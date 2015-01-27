# == Class: st2::profile::web
#
#  Profile to install StackStorm web client (st2web). This feature is
#  currently under active development, and limited to early access users.
#  If you would like to try this out, please send an email to support@stackstorm.com
#  and let us know!
#
# === Parameters
#
#  [*github_oauth_token*] - Version of StackStorm to install
#  [*st2_api_server*]     - Revision of StackStorm to install
#
# === Variables
#
#  This class has no variables
#
# === Examples
#
#  class { '::st2::profile::web':
#    github_oauth_token = 'abcd0011222333',
#  }
#
class st2::profile::web(
  $github_oauth_token = undef,
  $st2_api_server     = $::ipaddress,
  $revision           = 'v0.6.0',
) {
  if !$github_oauth_token {
    fail("Class['st2::profile::web']: ${st2::notices::web_no_oauth_token}")
  }

  file { '/opt/st2web':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  vcsrepo { '/opt/st2web':
    ensure   => present,
    provider => git,
    source   => "https://${github_oauth_token}@github.com/StackStorm/st2web.git",
    revision => $revision,
    notify   => [
      Exec['npm-install-st2repo'],
      Exec['bower-install-st2repo'],
    ],
  }

  # This is crude... get some augeas on
  ## Manage connection list currently
  file { '/opt/st2web/config.js':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('st2/opt/st2web/config.js.erb'),
    require => Vcsrepo['/opt/st2web'],
  }

  exec { 'npm-install-st2repo':
    command     => 'npm install',
    cwd         => '/opt/st2web',
    path        => '/usr/bin:/usr/sbin:/bin:/sbin',
    refreshonly => true,
    require     => Class['::nodejs'],
  }

  exec { 'bower-install-st2repo':
    command     => 'bower --allow-root install',
    cwd         => '/opt/st2web',
    path        => '/usr/bin:/usr/sbin:/bin:/sbin',
    refreshonly => true,
    require     => [
      Exec['npm-install-st2repo'],
      Class['::nodejs'],
    ],
  }

  # Needs a SystemD init script too!
  file { '/etc/init/st2web.conf':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0444',
    source => 'puppet:///modules/st2/etc/init/st2web.conf',
  }

  service { 'st2web':
    ensure  => running,
    enable  => true,
    require => [
      Exec['bower-install-st2repo'],
      Class['::nodejs'],
      File['/etc/init/st2web.conf'],
    ],
  }
}