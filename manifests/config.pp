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

  File {
    owner => $elasticsearch_old::elasticsearch_user,
    group => $elasticsearch_old::elasticsearch_group,
  }

  Exec {
    path => [ '/bin', '/usr/bin', '/usr/local/bin' ],
    cwd  => '/',
  }

  if ( $elasticsearch_old::ensure == 'present' ) {

    $notify_service = $elasticsearch_old::restart_on_change ? {
      true  => Class['elasticsearch_old::service'],
      false => undef,
    }

    file { $elasticsearch_old::configdir:
      ensure => directory,
      mode   => '0644',
    }

    file { $elasticsearch_old::logdir:
      ensure  => 'directory',
      group   => undef,
      mode    => '0644',
      recurse => true,
    }

    file { $elasticsearch_old::params::homedir:
      ensure  => 'directory',
    }

    file { $elasticsearch_old::datadir:
      ensure  => 'directory',
    }

    file { "${elasticsearch_old::homedir}/lib":
      ensure  => 'directory',
      recurse => true,
    }

    if $elasticsearch_old::params::pid_dir {
      file { $elasticsearch_old::params::pid_dir:
        ensure  => 'directory',
        group   => undef,
        recurse => true,
      }

      if ($elasticsearch_old::service_providers == 'systemd') {
        $user = $elasticsearch_old::elasticsearch_user
        $group = $elasticsearch_old::elasticsearch_group
        $pid_dir = $elasticsearch_old::params::pid_dir

        file { '/usr/lib/tmpfiles.d/elasticsearch.conf':
          ensure  => 'file',
          content => template("${module_name}/usr/lib/tmpfiles.d/elasticsearch.conf.erb"),
          owner   => 'root',
          group   => 'root',
        }
      }
    }


    file { "${elasticsearch_old::params::homedir}/templates_import":
      ensure => 'directory',
      mode   => '0644',
    }

    file { "${elasticsearch_old::params::homedir}/scripts":
      ensure => 'directory',
      mode   => '0644',
    }

    # Resources for shield management
    file { "${elasticsearch_old::params::homedir}/shield":
      ensure => 'directory',
      mode   => '0644',
      owner  => 'root',
      group  => 'root',
    }

    # Removal of files that are provided with the package which we don't use
    file { '/etc/init.d/elasticsearch':
      ensure => 'absent',
    }
    if $elasticsearch_old::params::systemd_service_path {
      file { "${elasticsearch_old::params::systemd_service_path}/elasticsearch.service":
        ensure => 'absent',
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

    file { '/etc/elasticsearch/elasticsearch.yml':
      ensure => 'absent',
    }
    file { '/etc/elasticsearch/logging.yml':
      ensure => 'absent',
    }

  } elsif ( $elasticsearch_old::ensure == 'absent' ) {

    file { $elasticsearch_old::plugindir:
      ensure => 'absent',
      force  => true,
      backup => false,
    }

  }

}
