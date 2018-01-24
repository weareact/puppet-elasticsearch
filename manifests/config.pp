# == Class: elasticsearch_old::config
#
# This class exists to coordinate all configuration related actions,
# functionality and logical units in a central place.
#
#
# === Parameters
#
# This class does not provide any parameters.
#
#
# === Examples
#
# This class may be imported by other classes to use its functionality:
#   class { 'elasticsearch_old::config': }
#
# It is not intended to be used directly by external resources like node
# definitions or other modules.
#
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard.pijnenburg@elasticsearch.com>
#
class elasticsearch_old::config {

  #### Configuration

  Exec {
    path => [ '/bin', '/usr/bin', '/usr/local/bin' ],
    cwd  => '/',
  }

  if ( $elasticsearch_old::ensure == 'present' ) {

    file {
      $elasticsearch_old::configdir:
        ensure => 'directory',
        group  => $elasticsearch_old::elasticsearch_group,
        owner  => $elasticsearch_old::elasticsearch_user,
        mode   => '0644';
      $elasticsearch_old::datadir:
        ensure => 'directory',
        group  => $elasticsearch_old::elasticsearch_group,
        owner  => $elasticsearch_old::elasticsearch_user;
      $elasticsearch_old::logdir:
        ensure  => 'directory',
        group   => undef,
        owner   => $elasticsearch_old::elasticsearch_user,
        mode    => '0644',
        recurse => true;
      $elasticsearch_old::plugindir:
        ensure => 'directory',
        group  => $elasticsearch_old::elasticsearch_group,
        owner  => $elasticsearch_old::elasticsearch_user,
        mode   => 'o+Xr';
      "${elasticsearch_old::homedir}/lib":
        ensure  => 'directory',
        group   => $elasticsearch_old::elasticsearch_group,
        owner   => $elasticsearch_old::elasticsearch_user,
        recurse => true;
      $elasticsearch_old::params::homedir:
        ensure => 'directory',
        group  => $elasticsearch_old::elasticsearch_group,
        owner  => $elasticsearch_old::elasticsearch_user;
      "${elasticsearch_old::params::homedir}/templates_import":
        ensure => 'directory',
        group  => $elasticsearch_old::elasticsearch_group,
        owner  => $elasticsearch_old::elasticsearch_user,
        mode   => '0644';
      "${elasticsearch_old::params::homedir}/scripts":
        ensure => 'directory',
        group  => $elasticsearch_old::elasticsearch_group,
        owner  => $elasticsearch_old::elasticsearch_user,
        mode   => '0644';
      "${elasticsearch_old::params::homedir}/shield":
        ensure => 'directory',
        mode   => '0644',
        group  => '0',
        owner  => 'root';
      '/etc/elasticsearch/elasticsearch.yml':
        ensure => 'absent';
      '/etc/elasticsearch/logging.yml':
        ensure => 'absent';
      '/etc/elasticsearch/log4j2.properties':
        ensure => 'absent';
      '/etc/init.d/elasticsearch':
        ensure => 'absent';
    }

    if $elasticsearch_old::params::pid_dir {
      file { $elasticsearch_old::params::pid_dir:
        ensure  => 'directory',
        group   => undef,
        owner   => $elasticsearch_old::elasticsearch_user,
        recurse => true,
      }

      if ($elasticsearch_old::service_providers == 'systemd') {
        $group = $elasticsearch_old::elasticsearch_group
        $user = $elasticsearch_old::elasticsearch_user
        $pid_dir = $elasticsearch_old::params::pid_dir

        file { '/usr/lib/tmpfiles.d/elasticsearch.conf':
          ensure  => 'file',
          content => template("${module_name}/usr/lib/tmpfiles.d/elasticsearch.conf.erb"),
          group   => '0',
          owner   => 'root',
        }
      }
    }

    if ($elasticsearch_old::service_providers == 'systemd') {
      # Mask default unit (from package)
      exec { 'systemctl mask elasticsearch.service':
        unless => 'test `systemctl is-enabled elasticsearch.service` = masked',
      }
    }

    $new_init_defaults = { 'CONF_DIR' => $elasticsearch_old::configdir }
    if $elasticsearch_old::params::defaults_location {
      augeas { "${elasticsearch_old::params::defaults_location}/elasticsearch":
        incl    => "${elasticsearch_old::params::defaults_location}/elasticsearch",
        lens    => 'Shellvars.lns',
        changes => template("${module_name}/etc/sysconfig/defaults.erb"),
      }
    }

    # Other OS than Linux may not have that sysctl
    if $::kernel == 'Linux' {
      sysctl { 'vm.max_map_count':
        value => '262144',
      }
    }

  } elsif ( $elasticsearch_old::ensure == 'absent' ) {

    file { $elasticsearch_old::plugindir:
      ensure => 'absent',
      force  => true,
      backup => false,
    }

  }

}
