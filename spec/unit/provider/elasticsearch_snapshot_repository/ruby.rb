require 'spec_helper'
require 'webmock/rspec'

describe Puppet::Type.type(:elasticsearch_snapshot_repository).provider(:ruby) do

  describe 'instances' do
    context 'with no repositories' do
      before :all do
        stub_request(:get, 'http://localhost:9200/_snapshot').
          to_return(
            :status => 200,
            :body => '{}'
        )
      end

      it 'returns an empty list' do
        expect(described_class.instances).to eq([])
      end
    end
  end

  describe 'multiple repositories' do
    before :all do
      stub_request(:get, 'http://localhost:9200/_snapshot').
        to_return(
          :status => 200,
          :body => <<-EOS
            {
              "snap1": {
                "type": "fs",
                "settings": {
                  "compress": true,
                  "location": "/bak1"
                }
              },
              "snap2": {
                "type": "fs",
                "settings": {
                  "compress": false,
                  "location": "/bak2"
                }
              }
            }
          EOS
      )
    end

    it 'returns two repositories' do
      expect(described_class.instances.map { |provider|
        provider.instance_variable_get(:@property_hash)
      }).to contain_exactly({
        :name             => 'snap1',
        :ensure           => :present,
        :provider         => :ruby,
        :type             => 'fs',
        :compress         => true,
        :chunk_size       => nil,
        :location         => '/bak1',
        :max_restore_bps  => nil,
        :max_snapshot_bps => nil
      },{
        :name             => 'snap2',
        :ensure           => :present,
        :provider         => :ruby,
        :type             => 'fs',
        :compress         => false,
        :chunk_size       => nil,
        :location         => '/bak2',
        :max_restore_bps  => nil,
        :max_snapshot_bps => nil
      })
    end
  end

  describe 'basic authentication' do
    before :all do
      stub_request(:get, 'http://localhost:9200/_snapshot').
        with(:basic_auth => ['elastic', 'password']).
        to_return(
          :status => 200,
          :body => <<-EOS
            {
              "snap3": {
                "type": "fs",
                "settings": {
                  "location": "/bak3"
                }
              }
            }
          EOS
      )
    end

    it 'authenticates' do
      expect(described_class.repositories(
        'http', true, 'localhost', '9200', 10, 'elastic', 'password'
      ).map { |provider|
        described_class.new(
          provider
        ).instance_variable_get(:@property_hash)
      }).to contain_exactly({
        :name             => 'snap3',
        :ensure           => :present,
        :provider         => :ruby,
        :type             => 'fs',
        :compress         => true,
        :chunk_size       => nil,
        :location         => '/bak3',
        :max_restore_bps  => nil,
        :max_snapshot_bps => nil
      })
    end
  end

  describe 'https' do
    before :all do
      stub_request(:get, 'https://localhost:9200/_snapshot').
        to_return(
          :status => 200,
          :body => <<-EOS
            {
              "snap-ssl": {
                "type": "fs",
                "settings": {
                  "location": "/bak-ssl"
                }
              }
            }
          EOS
      )
    end

    it 'uses ssl' do
      expect(described_class.repositories(
        'https', true, 'localhost', '9200', 10
      ).map { |provider|
        described_class.new(
          provider
        ).instance_variable_get(:@property_hash)
      }).to contain_exactly({
        :name             => 'snap-ssl',
        :ensure           => :present,
        :provider         => :ruby,
        :type             => 'fs',
        :compress         => true,
        :chunk_size       => nil,
        :location         => '/bak-ssl',
        :max_restore_bps  => nil,
        :max_snapshot_bps => nil
      })
    end
  end

  describe 'prefetch' do
    it 'should have a prefetch method' do
      expect(described_class).to respond_to :prefetch
    end
  end

  describe 'flush' do
    let(:resource) { Puppet::Type::Elasticsearch_snapshot_repository.new props }
    let(:provider) { described_class.new resource }
    let(:props) do
      {
        :name             => 'foo',
        :type             => 'fs',
        :chunk_size       => '500m',
        :location         => '/bak',
        :max_restore_bps  => '50mb',
        :max_snapshot_bps => '50mb'
      }
    end

    let(:bare_resource) do
      JSON.dump(
        'type'     => 'fs',
        'settings' => {
          'compress'                   => true,
          'location'                   => '/bak',
          'chunk_size'                 => '500m',
          'max_restore_bytes_per_sec'  => '50mb',
          'max_snapshot_bytes_per_sec' => '50mb'
        }
      )
    end

    it "creates repositories" do
      stub_request(:put, "http://localhost:9200/_snapshot/foo")
        .with(
          :body => bare_resource
        )
      stub_request(:get, "http://localhost:9200/_snapshot")
        .to_return(:status => 200, :body => '{}')

      provider.flush
    end
  end
end # of describe puppet type
