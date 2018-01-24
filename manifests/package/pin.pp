# == Class: elasticsearch_old::package::pin
#
# Controls package pinning for the Elasticsearch package.
#
# === Parameters
#
# This class does not provide any parameters.
#
# === Examples
#
# This class may be imported by other classes to use its functionality:
#   class { 'elasticsearch_old::package::pin': }
#
# It is not intended to be used directly by external resources like node
# definitions or other modules.
#
# === Authors
#
# * Tyler Langlois <mailto:tyler@elastic.co>
#
class elasticsearch_old::package::pin {

  Exec {
    path => [ '/bin', '/usr/bin', '/usr/local/bin' ],
    cwd  => '/',
  }

  case $::osfamily {
    'Debian': {
      include ::apt

      if ($elasticsearch_old::ensure == 'absent') {
        apt::pin { $elasticsearch_old::package_name:
          ensure => $elasticsearch_old::ensure,
        }
      } elsif ($elasticsearch_old::version != false) {
        apt::pin { $elasticsearch_old::package_name:
          ensure   => $elasticsearch_old::ensure,
          packages => $elasticsearch_old::package_name,
          version  => $elasticsearch_old::version,
          priority => 1000,
        }
      }

    }
    'RedHat', 'Linux': {

      if ($elasticsearch_old::ensure == 'absent') {
        $_versionlock = '/etc/yum/pluginconf.d/versionlock.list'
        $_lock_line = '0:elasticsearch-'
        exec { 'elasticsearch_purge_versionlock.list':
          command => "sed -i '/${_lock_line}/d' ${_versionlock}",
          onlyif  => [
            "test -f ${_versionlock}",
            "grep -F '${_lock_line}' ${_versionlock}",
          ],
        }
      } elsif ($elasticsearch_old::version != false) {
        yum::versionlock {
          "0:elasticsearch-${elasticsearch_old::pkg_version}.noarch":
            ensure => $elasticsearch_old::ensure,
        }
      }

    }
    default: {
      warning("Unable to pin package for OSfamily \"${::osfamily}\".")
    }
  }
}
