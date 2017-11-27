$LOAD_PATH.unshift(File.join(File.dirname(__FILE__),"..","..",".."))

require 'puppet/file_serving/content'
require 'puppet/file_serving/metadata'
require 'puppet/parameter/boolean'

require 'puppet_x/elastic/deep_implode'
require 'puppet_x/elastic/deep_to_i'

Puppet::Type.newtype(:elasticsearch_snapshot_repository) do
  desc 'Manages Elasticsearch snapshot repositories.'

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, :namevar => true) do
    desc 'Repository name.'
  end

  newparam(:type) do
    desc 'Repository type.'
    defaultto 'fs'
  end

  newproperty(:compress) do
    desc 'Compress Snapshot files'
    defaultto true
  end

  newproperty(:location) do
    desc 'Snapshot location.'
    isrequired
  end

  newproperty(:chunk_size) do
    desc 'File chunk size'
  end

  newproperty(:max_restore_bps) do
    desc 'Maximum Restore rate'
    defaultto '40mb'
  end

  newproperty(:max_snapshot_bps) do
    desc 'Maximum Snapshot rate'
    defaultto '40mb'
  end

  newparam(:host) do
    desc 'Optional host where Elasticsearch is listening.'
    defaultto 'localhost'

    validate do |value|
      unless value.is_a? String
        raise Puppet::Error, 'invalid parameter, expected string'
      end
    end
  end

  newparam(:port) do
    desc 'Port to use for Elasticsearch HTTP API operations.'
    defaultto 9200

    munge do |value|
      if value.is_a? String
        value.to_i
      elsif value.is_a? Fixnum
        value
      else
        raise Puppet::Error, "unknown '#{value}' timeout type '#{value.class}'"
      end
    end

    validate do |value|
      if value.to_s =~ /^([0-9]+)$/
        unless (0 < $1.to_i) and ($1.to_i < 65535)
          raise Puppet::Error, "invalid port value '#{value}'"
        end
      else
        raise Puppet::Error, "invalid port value '#{value}'"
      end
    end
  end

  newparam(:protocol) do
    desc 'Protocol to communicate over to Elasticsearch.'
    defaultto 'http'
  end

  newparam(
    :validate_tls,
    :boolean => true,
    :parent => Puppet::Parameter::Boolean
  ) do
    desc 'Whether to verify TLS/SSL certificates.'
    defaultto true
  end

  newparam(:timeout) do
    desc 'HTTP timeout for reading/writing content to Elasticsearch.'
    defaultto 10

    munge do |value|
      if value.is_a? String
        value.to_i
      elsif value.is_a? Fixnum
        value
      else
        raise Puppet::Error, "unknown '#{value}' timeout type '#{value.class}'"
      end
    end

    validate do |value|
      if value.to_s !~ /^\d+$/
        raise Puppet::Error, 'timeout must be a positive integer'
      end
    end
  end

  newparam(:username) do
    desc 'Optional HTTP basic authentication username for Elasticsearch.'
  end

  newparam(:password) do
    desc 'Optional HTTP basic authentication plaintext password for Elasticsearch.'
  end

  newparam(:ca_file) do
    desc 'Absolute path to a CA file to authenticate server certificates against.'
  end

  newparam(:ca_path) do
    desc 'Absolute path to a directory containing CA files to authenticate server certificates against.'
  end

  validate do

    # Ensure that at least one source of template content has been provided
    if self[:ensure] == :present
      if self[:location].nil?
        fail Puppet::ParseError, '"location" is required'
      end
    end

  end
end # of newtype
