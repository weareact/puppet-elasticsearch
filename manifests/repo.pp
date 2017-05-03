# == Class: elasticsearch_old::repo
#
# This class exists to install and manage yum and apt repositories
# that contain elasticsearch official elasticsearch packages
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
#   class { 'elasticsearch_old::repo': }
#
# It is not intended to be used directly by external resources like node
# definitions or other modules.
#
#
# === Authors
#
# * Phil Fenstermacher <mailto:phillip.fenstermacher@gmail.com>
# * Richard Pijnenburg <mailto:richard.pijnenburg@elasticsearch.com>
#
class elasticsearch_old::repo {

  Exec {
    path      => [ '/bin', '/usr/bin', '/usr/local/bin' ],
    cwd       => '/',
  }

  case $::osfamily {
    'Debian': {
      include ::apt
      Class['apt::update'] -> Package[$elasticsearch_old::package_name]

      apt::source { 'elasticsearch':
        location    => "http://packages.elastic.co/elasticsearch/${elasticsearch_old::repo_version}/debian",
        release     => 'stable',
        repos       => 'main',
        key         => $::elasticsearch_old::repo_key_id,
        key_source  => $::elasticsearch_old::repo_key_source,
        include_src => false,
      }
    }
    'RedHat', 'Linux': {
      yumrepo { 'elasticsearch':
        descr    => 'elasticsearch repo',
        baseurl  => "http://packages.elastic.co/elasticsearch/${elasticsearch_old::repo_version}/centos",
        gpgcheck => 1,
        gpgkey   => $::elasticsearch_old::repo_key_source,
        enabled  => 1,
        proxy    => $::elasticsearch_old::repo_proxy,
      }
    }
    'Suse': {
      if $::operatingsystem == 'SLES' and versioncmp($::operatingsystemmajrelease, '11') <= 0 {
        # Older versions of SLES do not ship with rpmkeys
        $_import_cmd = "rpm --import ${::elasticsearch_old::repo_key_source}"
      } else {
        $_import_cmd = "rpmkeys --import ${::elasticsearch_old::repo_key_source}"
      }

      exec { 'elasticsearch_suse_import_gpg':
        command => $_import_cmd,
        unless  => "test $(rpm -qa gpg-pubkey | grep -i '${::elasticsearch_old::repo_key_id}' | wc -l) -eq 1 ",
        notify  => [ Zypprepo['elasticsearch'] ],
      }

      zypprepo { 'elasticsearch':
        baseurl     => "http://packages.elastic.co/elasticsearch/${elasticsearch_old::repo_version}/centos",
        enabled     => 1,
        autorefresh => 1,
        name        => 'elasticsearch',
        gpgcheck    => 1,
        gpgkey      => $::elasticsearch_old::repo_key_source,
        type        => 'yum',
      } ~>
      exec { 'elasticsearch_zypper_refresh_elasticsearch':
        command     => 'zypper refresh elasticsearch',
        refreshonly => true,
      }
    }
    default: {
      fail("\"${module_name}\" provides no repository information for OSfamily \"${::osfamily}\"")
    }
  }

  # Package pinning

    case $::osfamily {
      'Debian': {
        include ::apt

        if ($elasticsearch_old::package_pin == true and $elasticsearch_old::version != false) {
          apt::pin { $elasticsearch_old::package_name:
            ensure   => 'present',
            packages => $elasticsearch_old::package_name,
            version  => $elasticsearch_old::version,
            priority => 1000,
          }
        }

      }
      'RedHat', 'Linux': {

        if ($elasticsearch_old::package_pin == true and $elasticsearch_old::version != false) {
          yum::versionlock { "0:elasticsearch-${elasticsearch_old::pkg_version}.noarch":
            ensure => 'present',
          }
        }
      }
      default: {
        warning("Unable to pin package for OSfamily \"${::osfamily}\".")
      }
    }
}
