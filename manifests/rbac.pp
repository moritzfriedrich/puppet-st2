# @summary This class creates RBAC resources
#
class st2::rbac (
  Boolean $enable = true,
  Boolean $sync_remote_groups = false,
  String $backend = 'default',
  Hash $assignments = {},
  Hash $roles = {},
  Hash $mappings = {}
) {

  ensure_resource('exec', 'restart st2api rbac', {
    'command'         => 'st2ctl restart-component st2api ',
    'refreshonly'     => true,
    'path'            => '/usr/sbin:/usr/bin:/sbin:/bin',
  })

  ensure_resource('exec', 'reload st2 rbac definitions', {
    'command'         => 'st2-apply-rbac-definitions',
    'refreshonly'     => true,
    'path'            => '/usr/sbin:/usr/bin:/sbin:/bin',
  })

  ini_setting { 'rbac_enable':
    ensure  => present,
    path    => '/etc/st2/st2.conf',
    section => 'rbac',
    setting => 'enable',
    value   => bool2str($enable, 'True', 'False'),
    notify  => Exec['restart st2api rbac'],
  }

  ini_setting { 'rbac_backend':
    ensure  => present,
    path    => '/etc/st2/st2.conf',
    section => 'rbac',
    setting => 'backend',
    value   => $backend,
    notify  => Exec['restart st2api rbac'],
  }
  
  ini_setting { 'rbac_sync_remote_groups':
    ensure  => present,
    path    => '/etc/st2/st2.conf',
    section => 'rbac',
    setting => 'sync_remote_groups',
    value   => bool2str($sync_remote_groups, 'True', 'False'),
    notify  => Exec['restart st2api rbac'],
  }

  $_rbac_dir = '/opt/stackstorm/rbac'

  ensure_resource('file', $_rbac_dir, {
    'ensure'  => 'directory',
    'owner'   => 'root',
    'group'   => 'root',
    'mode'    => '0755',
    'require' => Class['st2::profile::server'],
  })

  ensure_resource('file', "${_rbac_dir}/assignments", {
    'ensure'  => 'directory',
    'recurse' => true,
    'purge'   => true,
    'owner'   => 'root',
    'group'   => 'root',
    'mode'    => '0755',
    'require' => Class['st2::profile::server'],
  })
  $assignments.each |$assignment, $values| {
    file { "${_rbac_dir}/assignments/${assignment}.yaml":
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => inline_template('<%= require "yaml"; @values.to_yaml %>'),
      notify  => Exec['reload st2 rbac definitions'],
      require => File["${_rbac_dir}/assignments"]
    }
  }
  
  ensure_resource('file', "${_rbac_dir}/roles", {
    'ensure'  => 'directory',
    'recurse' => true,
    'purge'   => true,
    'owner'   => 'root',
    'group'   => 'root',
    'mode'    => '0755',
    'require' => Class['st2::profile::server'],
  })
  $roles.each |$role, $values| {
    file { "${_rbac_dir}/roles/${role}.yaml":
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => inline_template('<%= require "yaml"; @values.to_yaml %>'),
      notify  => Exec['reload st2 rbac definitions'],
      require => File["${_rbac_dir}/roles"]
    }
  }

  ensure_resource('file', "${_rbac_dir}/mappings", {
    'ensure'  => 'directory',
    'recurse' => true,
    'purge'   => true,
    'owner'   => 'root',
    'group'   => 'root',
    'mode'    => '0755',
    'require' => Class['st2::profile::server'],
  })
  $mappings.each |$mapping, $values| {
    file { "${_rbac_dir}/mappings/${mapping}.yaml":
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => inline_template('<%= require "yaml"; @values.to_yaml %>'),
      notify  => Exec['reload st2 rbac definitions'],
      require => File["${_rbac_dir}/mappings"]
    }
  }

}
