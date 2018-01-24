# == Define: elasticsearch_old::instance
#
#  This define allows you to create or remove an elasticsearch instance
#
# === Parameters
#
# [*ensure*]
#   String. Controls if the managed resources shall be <tt>present</tt> or
#   <tt>absent</tt>. If set to <tt>absent</tt>:
#   * The managed software packages are being uninstalled.
#   * Any traces of the packages will be purged as good as possible. This may
#     include existing configuration files. The exact behavior is provider
#     dependent. Q.v.:
#     * Puppet type reference: {package, "purgeable"}[http://j.mp/xbxmNP]
#     * {Puppet's package provider source code}[http://j.mp/wtVCaL]
#   * System modifications (if any) will be reverted as good as possible
#     (e.g. removal of created users, services, changed log settings, ...).
#   * This is thus destructive and should be used with care.
#   Defaults to <tt>present</tt>.
#
# [*status*]
#   String to define the status of the service. Possible values:
#   * <tt>enabled</tt>: Service is running and will be started at boot time.
#   * <tt>disabled</tt>: Service is stopped and will not be started at boot
#     time.
#   * <tt>running</tt>: Service is running but will not be started at boot time.
#     You can use this to start a service on the first Puppet run instead of
#     the system startup.
#   * <tt>unmanaged</tt>: Service will not be started at boot time and Puppet
#     does not care whether the service is running or not. For example, this may
#     be useful if a cluster management software is used to decide when to start
#     the service plus assuring it is running on the desired node.
#   Defaults to <tt>enabled</tt>. The singular form ("service") is used for the
#   sake of convenience. Of course, the defined status affects all services if
#   more than one is managed (see <tt>service.pp</tt> to check if this is the
#   case).
#
# [*config*]
#   Elasticsearch configuration hash
#
# [*configdir*]
#   Path to directory containing the elasticsearch configuration.
#   Use this setting if your packages deviate from the norm (/etc/elasticsearch)
#
# [*datadir*]
#   Allows you to set the data directory of Elasticsearch
#
# [*logging_file*]
#   Instead of a hash you can supply a puppet:// file source for the logging.yml file
#
# [*logging_config*]
#   Hash representation of information you want in the logging.yml file
#
# [*logging_template*]
#  Use a custom logging template - just supply the reative path ie ${module}/elasticsearch/logging.yml.erb
#
# [*logging_level*]
#   Default logging level for Elasticsearch.
#   Defaults to: INFO
#
# [*init_defaults*]
#   Defaults file content in hash representation
#
# [*init_defaults_file*]
#   Defaults file as puppet resource
#
# [*service_flags*]
#   Service flags used for the OpenBSD service configuration, defaults to undef.
#
# [*init_template*]
#   Service file as a template
#
# [*logdir*]
#   Log directory for this instance.
#
# [*ssl*]
#   Whether to manage TLS certificates for Shield. Requires the ca_certificate,
#   certificate, private_key and keystore_password parameters to be set.
#   Value type is boolean
#   Default value: false
#
# [*ca_certificate*]
#   Path to the trusted CA certificate to add to this node's java keystore.
#   Value type is string
#   Default value: undef
#
# [*certificate*]
#   Path to the certificate for this node signed by the CA listed in
#   ca_certificate.
#   Value type is string
#   Default value: undef
#
# [*private_key*]
#   Path to the key associated with this node's certificate.
#   Value type is string
#   Default value: undef
#
# [*keystore_password*]
#   Password to encrypt this node's Java keystore.
#   Value type is string
#   Default value: undef
#
# [*keystore_path*]
#   Custom path to the java keystore file. This parameter is optional.
#   Value type is string
#   Default value: undef
#
# [*system_key*]
#   Source for the Shield system key. Valid values are any that are
#   supported for the file resource `source` parameter.
#   Value type is string
#   Default value: undef
#
# [*file_rolling_type*]
#   Configuration for the file appender rotation. It can be 'dailyRollingFile',
#   'rollingFile' or 'file'. The first rotates by name, and the second one by size.
#   Value type is string
#   Default value: dailyRollingFile
#
# [*daily_rolling_date_pattern*]
#   File pattern for the file appender log when file_rolling_type is 'dailyRollingFile'
#   Value type is string
#   Default value: "'.'yyyy-MM-dd"
#
# [*rolling_file_max_backup_index*]
#   Max number of logs to store whern file_rolling_type is 'rollingFile'
#   Value type is integer
#   Default value: 1
#
# [*rolling_file_max_file_size*]
#   Max log file size when file_rolling_type is 'rollingFile'
#   Value type is string
#   Default value: 10MB
#
# === Authors
#
# * Tyler Langlois <mailto:tyler@elastic.co>
# * Richard Pijnenburg <mailto:richard.pijnenburg@elasticsearch.com>
#
define elasticsearch_old::instance (
  $ensure                        = $elasticsearch_old::ensure,
  $status                        = $elasticsearch_old::status,
  $config                        = undef,
  $configdir                     = undef,
  $datadir                       = undef,
  $logdir                        = undef,
  $logging_file                  = undef,
  $logging_config                = undef,
  $logging_template              = undef,
  $logging_level                 = $elasticsearch_old::default_logging_level,
  $service_flags                 = undef,
  $init_defaults                 = undef,
  $init_defaults_file            = undef,
  $init_template                 = $elasticsearch_old::init_template,
  $ssl                           = false,
  $ca_certificate                = undef,
  $certificate                   = undef,
  $private_key                   = undef,
  $keystore_password             = undef,
  $keystore_path                 = undef,
  $system_key                    = $elasticsearch_old::system_key,
  $file_rolling_type             = $elasticsearch_old::file_rolling_type,
  $daily_rolling_date_pattern    = $elasticsearch_old::daily_rolling_date_pattern,
  $rolling_file_max_backup_index = $elasticsearch_old::rolling_file_max_backup_index,
  $rolling_file_max_file_size    = $elasticsearch_old::rolling_file_max_file_size,
) {

  require elasticsearch_old::params

  File {
    owner => $elasticsearch_old::elasticsearch_user,
    group => $elasticsearch_old::elasticsearch_group,
  }

  Exec {
    path => [ '/bin', '/usr/bin', '/usr/local/bin' ],
    cwd  => '/',
  }

  # ensure
  if ! ($ensure in [ 'present', 'absent' ]) {
    fail("\"${ensure}\" is not a valid ensure parameter value")
  }

  if ! ($file_rolling_type in [ 'dailyRollingFile', 'rollingFile', 'file' ]) {
    fail("\"${file_rolling_type}\" is not a valid type")
  }

  $notify_service = $elasticsearch_old::restart_config_change ? {
    true  => Elasticsearch_old::Service[$name],
    false => undef,
  }

  # Instance config directory
  if ($configdir == undef) {
    $instance_configdir = "${elasticsearch_old::configdir}/${name}"
  } else {
    $instance_configdir = $configdir
  }

  if ($ensure == 'present') {

    # Configuration hash
    if ($config == undef) {
      $instance_config = {}
    } else {
      validate_hash($config)
      $instance_config = deep_implode($config)
    }

    if(has_key($instance_config, 'node.name')) {
      $instance_node_name = {}
    } else {
      $instance_node_name = { 'node.name' => "${::hostname}-${name}" }
    }

    # String or array for data dir(s)
    if ($datadir == undef) {
      if (is_array($elasticsearch_old::datadir)) {
        $instance_datadir = array_suffix($elasticsearch_old::datadir, "/${name}")
      } else {
        $instance_datadir = "${elasticsearch_old::datadir}/${name}"
      }
    } else {
      $instance_datadir = $datadir
    }

    # Logging file or hash
    if ($logging_file != undef) {
      $logging_source = $logging_file
      $logging_content = undef
      $_log4j_content = undef
    } elsif ($elasticsearch_old::logging_file != undef) {
      $logging_source = $elasticsearch_old::logging_file
      $logging_content = undef
      $_log4j_content = undef
    } else {

      if(is_hash($elasticsearch_old::logging_config)) {
        $main_logging_config = deep_implode($elasticsearch_old::logging_config)
      } else {
        $main_logging_config = { }
      }

      if(is_hash($logging_config)) {
        $instance_logging_config = deep_implode($logging_config)
      } else {
        $instance_logging_config = { }
      }
      $logging_hash = merge(
        $elasticsearch_old::params::logging_defaults,
        $main_logging_config,
        $instance_logging_config
      )
      if ($logging_template != undef ) {
        $logging_content = template($logging_template)
        $_log4j_content = template($logging_template)
      } elsif ($elasticsearch_old::logging_template != undef) {
        $logging_content = template($elasticsearch_old::logging_template)
        $_log4j_content = template($elasticsearch_old::logging_template)
      } else {
        $logging_content = template("${module_name}/etc/elasticsearch/logging.yml.erb")
        $_log4j_content = template("${module_name}/etc/elasticsearch/log4j2.properties.erb")
      }
      $logging_source = undef
    }

    if ($elasticsearch_old::x_config != undef) {
      $main_config = deep_implode($elasticsearch_old::x_config)
    } else {
      $main_config = { }
    }

    $instance_datadir_config = { 'path.data' => $instance_datadir }

    if(is_array($instance_datadir)) {
      $dirs = join($instance_datadir, ' ')
    } else {
      $dirs = $instance_datadir
    }

    # Manage instance log directory
    if ($logdir == undef) {
      $instance_logdir = "${elasticsearch_old::logdir}/${name}"
    } else {
      $instance_logdir = $logdir
    }

    $instance_logdir_config = { 'path.logs' => $instance_logdir }

    validate_bool($ssl)
    if $ssl {
      validate_absolute_path($ca_certificate, $certificate, $private_key)
      validate_string($keystore_password)

      if ($keystore_path == undef) {
        $_keystore_path = "${instance_configdir}/shield/${name}.ks"
      } else {
        validate_absolute_path($keystore_path)
        $_keystore_path = $keystore_path
      }

      $tls_config = {
        'shield.ssl.keystore.path'     => $_keystore_path,
        'shield.ssl.keystore.password' => $keystore_password,
        'shield.transport.ssl'         => true,
        'shield.http.ssl'              => true,
      }

      # Trust CA Certificate
      java_ks { "elasticsearch_instance_${name}_keystore_ca":
        ensure       => 'latest',
        certificate  => $ca_certificate,
        target       => $_keystore_path,
        password     => $keystore_password,
        trustcacerts => true,
      }

      # Load node certificate and private key
      java_ks { "elasticsearch_instance_${name}_keystore_node":
        ensure      => 'latest',
        certificate => $certificate,
        private_key => $private_key,
        target      => $_keystore_path,
        password    => $keystore_password,
      }
    } else { $tls_config = {} }

    if $system_key != undef {
      validate_string($system_key)
    }

    exec { "mkdir_logdir_elasticsearch_${name}":
      command => "mkdir -p ${instance_logdir}",
      creates => $instance_logdir,
      require => Class['elasticsearch_old::package'],
      before  => File[$instance_logdir],
    }

    file { $instance_logdir:
      ensure  => 'directory',
      owner   => $elasticsearch_old::elasticsearch_user,
      group   => undef,
      mode    => '0644',
      require => Class['elasticsearch_old::package'],
      before  => Elasticsearch_old::Service[$name],
    }

    exec { "mkdir_datadir_elasticsearch_${name}":
      command => "mkdir -p ${dirs}",
      creates => $instance_datadir,
      require => Class['elasticsearch_old::package'],
      before  => Elasticsearch_old::Service[$name],
    }

    file { $instance_datadir:
      ensure  => 'directory',
      owner   => $elasticsearch_old::elasticsearch_user,
      group   => undef,
      mode    => '0644',
      require => [ Exec["mkdir_datadir_elasticsearch_${name}"], Class['elasticsearch_old::package'] ],
      before  => Elasticsearch_old::Service[$name],
    }

    exec { "mkdir_configdir_elasticsearch_${name}":
      command => "mkdir -p ${instance_configdir}",
      creates => $elasticsearch_old::configdir,
      require => Class['elasticsearch_old::package'],
      before  => Elasticsearch_old::Service[$name],
    }

    file { $instance_configdir:
      ensure  => 'directory',
      mode    => '0644',
      purge   => $elasticsearch_old::purge_configdir,
      force   => $elasticsearch_old::purge_configdir,
      require => [ Exec["mkdir_configdir_elasticsearch_${name}"], Class['elasticsearch_old::package'] ],
      before  => Elasticsearch_old::Service[$name],
    }

    file {
      "${instance_configdir}/logging.yml":
        ensure  => file,
        content => $logging_content,
        source  => $logging_source,
        mode    => '0644',
        notify  => $notify_service,
        require => Class['elasticsearch_old::package'],
        before  => Elasticsearch_old::Service[$name];
      "${instance_configdir}/log4j2.properties":
        ensure  => file,
        content => $_log4j_content,
        source  => $logging_source,
        mode    => '0644',
        notify  => $notify_service,
        require => Class['elasticsearch_old::package'],
        before  => Elasticsearch_old::Service[$name];
    }

    file { "${instance_configdir}/scripts":
      ensure => 'link',
      target => "${elasticsearch_old::params::homedir}/scripts",
    }

    file { "${instance_configdir}/shield":
      ensure  => 'directory',
      mode    => '0644',
      source  => "${elasticsearch_old::params::homedir}/shield",
      recurse => 'remote',
      owner   => 'root',
      group   => '0',
      before  => Elasticsearch_old::Service[$name],
    }

    if $system_key != undef {
      file { "${instance_configdir}/shield/system_key":
        ensure  => 'file',
        source  => $system_key,
        mode    => '0400',
        before  => Elasticsearch_old::Service[$name],
        require => File["${instance_configdir}/shield"],
      }
    }

    # build up new config
    $instance_conf = merge($main_config, $instance_node_name, $instance_config, $instance_datadir_config, $instance_logdir_config, $tls_config)

    # defaults file content
    # ensure user did not provide both init_defaults and init_defaults_file
    if (($init_defaults != undef) and ($init_defaults_file != undef)) {
      fail ('Only one of $init_defaults and $init_defaults_file should be defined')
    }

    if (is_hash($elasticsearch_old::init_defaults)) {
      $global_init_defaults = $elasticsearch_old::init_defaults
    } else {
      $global_init_defaults = { }
    }

    $instance_init_defaults_main = {
      'CONF_DIR'  => $instance_configdir,
      'CONF_FILE' => "${instance_configdir}/elasticsearch.yml",
      'ES_HOME'   => '/usr/share/elasticsearch',
      'LOG_DIR'   => $instance_logdir,
    }

    if (is_hash($init_defaults)) {
      $instance_init_defaults = $init_defaults
    } else {
      $instance_init_defaults = { }
    }
    $init_defaults_new = merge(
      { 'DATA_DIR'  => '$ES_HOME/data' },
      $global_init_defaults,
      $instance_init_defaults_main,
      $instance_init_defaults
    )

    $user = $elasticsearch_old::elasticsearch_user
    $group = $elasticsearch_old::elasticsearch_group

    datacat_fragment { "main_config_${name}":
      target => "${instance_configdir}/elasticsearch.yml",
      data   => $instance_conf,
    }

    datacat { "${instance_configdir}/elasticsearch.yml":
      template => "${module_name}/etc/elasticsearch/elasticsearch.yml.erb",
      notify   => $notify_service,
      require  => Class['elasticsearch_old::package'],
      owner    => $elasticsearch_old::elasticsearch_user,
      group    => $elasticsearch_old::elasticsearch_group,
    }

    $require_service = Class['elasticsearch_old::package']
    $before_service  = undef

  } else {

    file { $instance_configdir:
      ensure  => 'absent',
      recurse => true,
      force   => true,
    }

    $require_service = undef
    $before_service  = File[$instance_configdir]

    $init_defaults_new = {}
  }

  elasticsearch_old::service { $name:
    ensure             => $ensure,
    status             => $status,
    service_flags      => $service_flags,
    init_defaults      => $init_defaults_new,
    init_defaults_file => $init_defaults_file,
    init_template      => $init_template,
    require            => $require_service,
    before             => $before_service,
  }

}
