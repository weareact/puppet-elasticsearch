require 'spec_helper'

describe Puppet::Type.type(:elasticsearch_snapshot_repository) do

  let(:resource_name) { 'test_repository' }

  describe 'attribute validation' do
    [
      :name,
      :type,
      :host,
      :port,
      :protocol,
      :validate_tls,
      :ca_file,
      :ca_path,
      :timeout,
      :username,
      :password
    ].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [
      :compress, 
      :chunk_size, 
      :ensure,
      :location,
      :max_restore_bps,
      :max_snapshot_bps
    ].each do |prop|
      it "should have a #{prop} property" do
        expect(described_class.attrtype(prop)).to eq(:property)
      end
    end

    describe 'namevar validation' do
      it 'should have :name as its namevar' do
        expect(described_class.key_attributes).to eq([:name])
      end
    end

    describe 'ensure' do
      it 'should support present as a value for ensure' do
        expect { described_class.new(
          :name => resource_name,
          :ensure => :present,
          :location => 'test'
        ) }.to_not raise_error
      end

      it 'should support absent as a value for ensure' do
        expect { described_class.new(
          :name => resource_name,
          :ensure => :absent
        ) }.to_not raise_error
      end

      it 'should not support other values' do
        expect { described_class.new(
          :name => resource_name,
          :ensure => :foo,
          :location => 'test'
        ) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end

    describe 'host' do
      it 'should accept IP addresses' do
        expect { described_class.new(
          :name => resource_name,
          :location => 'test',
          :host => '127.0.0.1'
        ) }.not_to raise_error
      end
    end

    describe 'port' do
      [-1, 0, 70000, 'foo'].each do |value|
        it "should reject invalid port value #{value}" do
          expect { described_class.new(
            :name => resource_name,
            :location => 'test',
            :port => value
          ) }.to raise_error(Puppet::Error, /invalid port/i)
        end
      end
    end

    describe 'validate_tls' do
      [-1, 0, {}, [], 'foo'].each do |value|
        it "should reject invalid ssl_verify value #{value}" do
          expect { described_class.new(
            :name => resource_name,
            :location => 'test',
            :validate_tls => value
          ) }.to raise_error(Puppet::Error, /invalid value/i)
        end
      end

      [true, false, 'true', 'false', 'yes', 'no'].each do |value|
        it "should accept validate_tls value #{value}" do
          expect { described_class.new(
            :name => resource_name,
            :location => 'test',
            :validate_tls => value
          ) }.not_to raise_error
        end
      end
    end

    describe 'timeout' do
      it 'should reject string values' do
        expect { described_class.new(
          :name => resource_name,
          :location => 'test',
          :timeout => 'foo'
        ) }.to raise_error(Puppet::Error, /must be a/)
      end

      it 'should reject negative integers' do
        expect { described_class.new(
          :name => resource_name,
          :location => 'test',
          :timeout => -10
        ) }.to raise_error(Puppet::Error, /must be a/)
      end

      it 'should accept integers' do
        expect { described_class.new(
          :name => resource_name,
          :location => 'test',
          :timeout => 10
        ) }.to_not raise_error
      end

      it 'should accept quoted integers' do
        expect { described_class.new(
          :name => resource_name,
          :location => 'test',
          :timeout => '10'
        ) }.to_not raise_error
      end
    end

  end # of describing when validing values
end # of describe Puppet::Type
