require 'spec_helper'

describe 'elasticsearch::service::init', :type => 'define' do

  let :facts do {
    :operatingsystem => 'CentOS',
    :kernel => 'Linux',
    :osfamily => 'RedHat',
    :operatingsystemmajrelease => '6',
    :scenario => '',
    :common => ''
  } end

  let(:title) { 'es-service-init' }
  let(:pre_condition) {%q{
    class { "elasticsearch":
      config => { "node" => {"name" => "test" }}
    }
  }}

  context 'setup service' do

    let :params do {
      :ensure => 'present',
      :status => 'enabled'
    } end

    it { should contain_elasticsearch__service__init('es-service-init') }
    it { should contain_service('elasticsearch-instance-es-service-init')
      .with(:ensure => 'running', :enable => true) }
  end

  context 'remove service' do

    let :params do {
      :ensure => 'absent'
    } end

    it { should contain_elasticsearch__service__init('es-service-init') }
    it { should contain_service('elasticsearch-instance-es-service-init')
      .with(:ensure => 'stopped', :enable => false) }
  end

  context 'unmanaged' do
      let :params do {
        :ensure => 'present',
        :status => 'unmanaged'
      } end

    it { should contain_elasticsearch__service__init('es-service-init') }
    it { should contain_service('elasticsearch-instance-es-service-init')
      .with(:enable => false) }
    it { should contain_augeas('defaults_es-service-init') }
  end

  context 'defaults file' do

    context 'set via file' do
      let :params do {
        :ensure => 'present',
        :status => 'enabled',
        :init_defaults_file =>
          'puppet:///path/to/initdefaultsfile'
      } end

      it { should contain_file(
        '/etc/sysconfig/elasticsearch-es-service-init'
      ).with(
        :source => 'puppet:///path/to/initdefaultsfile'
      )}
      it { should contain_file(
        '/etc/sysconfig/elasticsearch-es-service-init'
      ).that_comes_before(
        'Service[elasticsearch-instance-es-service-init]'
      ) }
    end

    context 'set via hash' do
      let :params do {
        :ensure => 'present',
        :status => 'enabled',
        :init_defaults => {'ES_HOME' => '/usr/share/elasticsearch' }
      } end

      it 'writes the defaults file' do
        should contain_augeas('defaults_es-service-init').with(
          :incl => '/etc/sysconfig/elasticsearch-es-service-init',
          :changes => [
            'rm CONF_FILE',
            "set ES_GROUP 'elasticsearch'",
            "set ES_HOME '/usr/share/elasticsearch'",
            "set ES_USER 'elasticsearch'",
            "set MAX_OPEN_FILES '65536'",
          ].join("\n") << "\n",
          :before => 'Service[elasticsearch-instance-es-service-init]'
        )
      end
    end

    context 'restarts when "restart_on_change" is true' do
      let(:pre_condition) { %q{
        class { "elasticsearch":
          config => { "node" => {"name" => "test" }},
          restart_on_change => true
        }
      }}

      context 'set via file' do
        let :params do {
          :ensure => 'present',
          :status => 'enabled',
          :init_defaults_file => 'puppet:///path/to/initdefaultsfile'
        } end

        it { should contain_file(
          '/etc/sysconfig/elasticsearch-es-service-init'
        ).with(
          :source => 'puppet:///path/to/initdefaultsfile'
        ) }
        it { should contain_file(
          '/etc/sysconfig/elasticsearch-es-service-init'
        ).that_comes_before(
          'Service[elasticsearch-instance-es-service-init]'
        ) }
        it { should contain_file(
          '/etc/sysconfig/elasticsearch-es-service-init'
        ).that_notifies(
          'Service[elasticsearch-instance-es-service-init]'
        ) }
      end

      context 'set via hash' do
        let :params do {
          :ensure => 'present',
          :status => 'enabled',
          :init_defaults => {
            'ES_HOME' => '/usr/share/elasticsearch'
          }
        } end

        it { should contain_augeas(
          'defaults_es-service-init'
        ).with(
          :incl => '/etc/sysconfig/elasticsearch-es-service-init',
          :changes => "rm CONF_FILE\nset ES_GROUP 'elasticsearch'\nset ES_HOME '/usr/share/elasticsearch'\nset ES_USER 'elasticsearch'\nset MAX_OPEN_FILES '65536'\n"
        ) }
        it { should contain_augeas(
          'defaults_es-service-init'
        ).that_comes_before(
          'Service[elasticsearch-instance-es-service-init]'
        ) }
        it { should contain_augeas(
          'defaults_es-service-init'
        ).that_notifies(
          'Service[elasticsearch-instance-es-service-init]'
        ) }
      end
    end

    context 'does not restart when "restart_on_change" is false' do
      let(:pre_condition) { %q{
        class { "elasticsearch":
          config => { "node" => {"name" => "test" }},
        }
      }}

      context 'set via file' do
        let :params do {
          :ensure => 'present',
          :status => 'enabled',
          :init_defaults_file => 'puppet:///path/to/initdefaultsfile'
        } end

        it { should_not contain_file(
          '/etc/sysconfig/elasticsearch-es-service-init'
        ).that_notifies(
          'Service[elasticsearch-instance-es-service-init]'
        ) }
      end

      context 'set via hash' do
        let :params do {
          :ensure => 'present',
          :status => 'enabled',
          :init_defaults => {
            'ES_HOME' => '/usr/share/elasticsearch'
          }
        } end

        it { should_not contain_augeas(
          'defaults_es-service-init'
        ).that_notifies(
          'Service[elasticsearch-instance-es-service-init]'
        ) }
      end
    end
  end

  context 'init file' do
    let(:pre_condition) {%q{
      class { "elasticsearch":
        config => { "node" => {"name" => "test" }}
      }
    }}

    context 'via template' do
      let :params do {
        :ensure => 'present',
        :status => 'enabled',
        :init_template =>
          'elasticsearch/etc/init.d/elasticsearch.RedHat.erb'
      } end

      it do
        should contain_elasticsearch_service_file(
          '/etc/init.d/elasticsearch-es-service-init'
        ).that_comes_before(
          'File[/etc/init.d/elasticsearch-es-service-init]'
        )
      end

      it do
        should contain_file(
          '/etc/init.d/elasticsearch-es-service-init'
        ).that_comes_before(
          'Service[elasticsearch-instance-es-service-init]'
        )
      end
    end

    context 'restarts when "restart_on_change" is true' do
      let(:pre_condition) { %q{
        class { "elasticsearch":
          config => { "node" => {"name" => "test" }},
          restart_on_change => true
        }
      }}

      let :params do {
        :ensure => 'present',
        :status => 'enabled',
        :init_template =>
          'elasticsearch/etc/init.d/elasticsearch.RedHat.erb'
      } end

      it { should contain_file(
        '/etc/init.d/elasticsearch-es-service-init'
      ).that_comes_before(
        'Service[elasticsearch-instance-es-service-init]'
      ) }
      it { should contain_file(
        '/etc/init.d/elasticsearch-es-service-init'
      ).that_notifies(
        'Service[elasticsearch-instance-es-service-init]'
      ) }
    end

    context 'does not restart when "restart_on_change" is false' do
      let(:pre_condition) { %q{
        class { "elasticsearch":
          config => { "node" => {"name" => "test" }},
        }
      }}

      let :params do {
        :ensure => 'present',
        :status => 'enabled',
        :init_template =>
          'elasticsearch/etc/init.d/elasticsearch.RedHat.erb'
      } end

      it { should_not contain_file(
        '/etc/init.d/elasticsearch-es-service-init'
      ).that_notifies(
        'Service[elasticsearch-instance-es-service-init]'
      ) }
    end
  end
end
