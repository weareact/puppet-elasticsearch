# == Define: elasticsearch_old::plugin
#
# This define allows you to install arbitrary Elasticsearch plugins
# either by using the default repositories or by specifying an URL
#
# All default values are defined in the elasticsearch_old::params class.
#
#
# === Parameters
#
# [*module_dir*]
#   Directory name where the module has been installed
#   This is automatically generated based on the module name
#   Specify a value here to override the auto generated value
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*ensure*]
#   Whether the plugin will be installed or removed.
#   Set to 'absent' to ensure a plugin is not installed
#   Value type is string
#   Default value: present
#   This variable is optional
#
# [*url*]
#   Specify an URL where to download the plugin from.
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*source*]
#   Specify the source of the plugin.
#   This will copy over the plugin to the node and use it for installation.
#   Useful for offline installation
#   Value type is string
#   This variable is optional
#
# [*proxy_host*]
#   Proxy host to use when installing the plugin
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*proxy_port*]
#   Proxy port to use when installing the plugin
#   Value type is number
#   Default value: None
#   This variable is optional
#
# [*proxy_username*]
#   Proxy auth username to use when installing the plugin
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*proxy_password*]
#   Proxy auth username to use when installing the plugin
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*instances*]
#   Specify all the instances related
#   value type is string or array
#
# === Examples
#
# # From official repository
# elasticsearch_old::plugin{'mobz/elasticsearch-head': module_dir => 'head'}
#
# # From custom url
# elasticsearch_old::plugin{ 'elasticsearch-jetty':
#  module_dir => 'elasticsearch-jetty',
#  url        => 'https://oss-es-plugins.s3.amazonaws.com/elasticsearch-jetty/elasticsearch-jetty-0.90.0.zip',
# }
#
# === Authors
#
# * Matteo Sessa <mailto:matteo.sessa@catchoftheday.com.au>
# * Dennis Konert <mailto:dkonert@gmail.com>
# * Richard Pijnenburg <mailto:richard.pijnenburg@elasticsearch.com>
#
define elasticsearch_old::plugin (
  $instances      = undef,
  $module_dir     = undef,
  $ensure         = 'present',
  $url            = undef,
  $source         = undef,
  $proxy_host     = undef,
  $proxy_port     = undef,
  $proxy_username = undef,
  $proxy_password = undef,
) {

  include elasticsearch_old

  case $ensure {
    'installed', 'present': {
      if empty($instances) {
        fail('no $instances defined')
      }

      $_file_ensure = 'directory'
      $_file_before = []
    }
    'absent': {
      $_file_ensure = $ensure
      $_file_before = File[$elasticsearch_old::plugindir]
    }
    default: {
      fail("'${ensure}' is not a valid ensure parameter value")
    }
  }

  if ! empty($instances) and $elasticsearch_old::restart_plugin_change {
    Elasticsearch_old_plugin[$name] {
      notify +> Elasticsearch_old::Instance[$instances],
    }
  }

  # set proxy by override or parse and use proxy_url from
  # elasticsearch_old::proxy_url or use no proxy at all

  if ($proxy_host != undef and $proxy_port != undef) {
    if ($proxy_username != undef and $proxy_password != undef) {
      $_proxy_auth = "${proxy_username}:${proxy_password}@"
    } else {
      $_proxy_auth = undef
    }
    $_proxy = "http://${_proxy_auth}${proxy_host}:${proxy_port}"
  } elsif ($elasticsearch_old::proxy_url != undef) {
    $_proxy = $elasticsearch_old::proxy_url
  } else {
    $_proxy = undef
  }

  if ($source != undef) {

    $filenameArray = split($source, '/')
    $basefilename = $filenameArray[-1]

    $file_source = "${elasticsearch_old::package_dir}/${basefilename}"

    file { $file_source:
      ensure => 'file',
      source => $source,
      before => Elasticsearch_old_plugin[$name],
    }

  } else {
    $file_source = undef
  }

  if ($url != undef) {
    validate_string($url)
  }

  $_module_dir = es_plugin_name($module_dir, $name)

  elasticsearch_old_plugin { $name:
    ensure      => $ensure,
    source      => $file_source,
    url         => $url,
    proxy       => $_proxy,
    plugin_dir  => $::elasticsearch_old::plugindir,
    plugin_path => $module_dir,
  } ->
  file { "${elasticsearch_old::plugindir}/${_module_dir}":
    ensure  => $_file_ensure,
    mode    => 'o+Xr',
    recurse => true,
    before  => $_file_before,
  }
}
