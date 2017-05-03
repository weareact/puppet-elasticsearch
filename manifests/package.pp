# == Class: elasticsearch_old::package
#
# This class exists to coordinate all software package management related
# actions, functionality and logical units in a central place.
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
#   class { 'elasticsearch_old::package': }
#
# It is not intended to be used directly by external resources like node
# definitions or other modules.
#
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard.pijnenburg@elasticsearch.com>
#
class elasticsearch_old::package {

  Exec {
    path      => [ '/bin', '/usr/bin', '/usr/local/bin' ],
    cwd       => '/',
    tries     => 3,
    try_sleep => 10,
  }

  #### Package management


  # set params: in operation
  if $elasticsearch_old::ensure == 'present' {

    Package[$elasticsearch_old::package_name] ~> Elasticsearch_old::Service <| |>
    Package[$elasticsearch_old::package_name] ~> Exec['remove_plugin_dir']

    # Create directory to place the package file
    $package_dir = $elasticsearch_old::package_dir
    exec { 'create_package_dir_elasticsearch':
      cwd     => '/',
      path    => ['/usr/bin', '/bin'],
      command => "mkdir -p ${package_dir}",
      creates => $package_dir,
    }

    file { $package_dir:
      ensure  => 'directory',
      purge   => $elasticsearch_old::purge_package_dir,
      force   => $elasticsearch_old::purge_package_dir,
      backup  => false,
      require => Exec['create_package_dir_elasticsearch'],
    }

    # Check if we want to install a specific version or not
    if $elasticsearch_old::version == false {

      $package_ensure = $elasticsearch_old::autoupgrade ? {
        true  => 'latest',
        false => 'present',
      }

    } else {

      # install specific version
      $package_ensure = $elasticsearch_old::pkg_version

    }

    # action
    if ($elasticsearch_old::package_url != undef) {

      case $elasticsearch_old::package_provider {
        'package': { $before = Package[$elasticsearch_old::package_name]  }
        default:   { fail("software provider \"${elasticsearch_old::package_provider}\".") }
      }


      $filenameArray = split($elasticsearch_old::package_url, '/')
      $basefilename = $filenameArray[-1]

      $sourceArray = split($elasticsearch_old::package_url, ':')
      $protocol_type = $sourceArray[0]

      $extArray = split($basefilename, '\.')
      $ext = $extArray[-1]

      $pkg_source = "${package_dir}/${basefilename}"

      case $protocol_type {

        'puppet': {

          file { $pkg_source:
            ensure  => file,
            source  => $elasticsearch_old::package_url,
            require => File[$package_dir],
            backup  => false,
            before  => $before,
          }

        }
        'ftp', 'https', 'http': {

          if $elasticsearch_old::proxy_url != undef {
            $exec_environment = [
              'use_proxy=yes',
              "http_proxy=${elasticsearch_old::proxy_url}",
              "https_proxy=${elasticsearch_old::proxy_url}",
            ]
          } else {
            $exec_environment = []
          }

          exec { 'download_package_elasticsearch':
            command     => "${elasticsearch_old::params::download_tool} ${pkg_source} ${elasticsearch_old::package_url} 2> /dev/null",
            creates     => $pkg_source,
            environment => $exec_environment,
            timeout     => $elasticsearch_old::package_dl_timeout,
            require     => File[$package_dir],
            before      => $before,
          }

        }
        'file': {

          $source_path = $sourceArray[1]
          file { $pkg_source:
            ensure  => file,
            source  => $source_path,
            require => File[$package_dir],
            backup  => false,
            before  => $before,
          }

        }
        default: {
          fail("Protocol must be puppet, file, http, https, or ftp. You have given \"${protocol_type}\"")
        }
      }

      if ($elasticsearch_old::package_provider == 'package') {

        case $ext {
          'deb':   { Package { provider => 'dpkg', source => $pkg_source } }
          'rpm':   { Package { provider => 'rpm', source => $pkg_source } }
          default: { fail("Unknown file extention \"${ext}\".") }
        }

      }

    }

  # Package removal
  } else {

    if ($::osfamily == 'Suse') {
      Package {
        provider  => 'rpm',
      }
      $package_ensure = 'absent'
    } else {
      $package_ensure = 'purged'
    }

  }

  if ($elasticsearch_old::package_provider == 'package') {

    package { $elasticsearch_old::package_name:
      ensure => $package_ensure,
    }

    exec { 'remove_plugin_dir':
      refreshonly => true,
      command     => "rm -rf ${elasticsearch_old::plugindir}",
    }


  } else {
    fail("\"${elasticsearch_old::package_provider}\" is not supported")
  }

}
