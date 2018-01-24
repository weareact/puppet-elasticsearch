$LOAD_PATH.unshift(File.join(File.dirname(__FILE__),"..","..","..",".."))

require 'json'
require 'net/http'
require 'openssl'

Puppet::Type.type(:elasticsearch_old_snapshot_repository).provide(:ruby) do
  desc <<-ENDHEREDOC
    A REST API based provider to manage Elasticsearch Snapshot Repositories.
  ENDHEREDOC

  mk_resource_methods

  def self.rest http, \
                req, \
                validate_tls=true, \
                timeout=10, \
                username=nil, \
                password=nil

    if username and password
      req.basic_auth username, password
    elsif username or password
      Puppet.warning(
        'username and password must both be defined, skipping basic auth'
      )
    end

    http.read_timeout = timeout
    http.open_timeout = timeout
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if not validate_tls

    begin
      http.request req
    rescue EOFError => e
      # Because the provider attempts a best guess at API access, we
      # only fail when HTTP operations fail for mutating methods.
      unless ['GET', 'OPTIONS', 'HEAD'].include? req.method
        raise Puppet::Error,
          "Received '#{e}' from the Elasticsearch API. Are your API settings correct?"
      end
    end
  end

  def self.repositories protocol='http', \
                     validate_tls=true, \
                     host='localhost', \
                     port=9200, \
                     timeout=10, \
                     username=nil, \
                     password=nil, \
                     ca_file=nil, \
                     ca_path=nil

    uri = URI("#{protocol}://#{host}:#{port}/_snapshot")
    http = Net::HTTP.new uri.host, uri.port
    req = Net::HTTP::Get.new uri.request_uri

    http.use_ssl = uri.scheme == 'https'
    [[ca_file, :ca_file=], [ca_path, :ca_path=]].each do |arg, method|
      if arg and http.respond_to? method
        http.send method, arg
      end
    end

    response = rest http, req, validate_tls, timeout, username, password

    if response.respond_to? :code and response.code.to_i == 200
      JSON.parse(response.body).map do |name, repository|
        {
          :name             => name,
          :ensure           => :present,
          :type             => repository['type'],
          :compress         => repository['settings']['compress'].nil? ? true : repository['settings']['compress'],
          :chunk_size       => repository['settings']['chunk_size'],
          :location         => repository['settings']['location'],
          :max_restore_bps  => repository['settings']['max_restore_bytes_per_sec'],
          :max_snapshot_bps => repository['settings']['max_snapshot_bytes_per_sec'],
          :provider         => :ruby
        }
      end
    else
      []
    end
  end

  def self.instances
    repositories.map { |resource| new resource }
  end

  # Unlike a typical #prefetch, which just ties discovered #instances to the
  # correct resources, we need to quantify all the ways the resources in the
  # catalog know about Elasticsearch API access and use those settings to
  # fetch any templates we can before associating resources and providers.
  def self.prefetch(resources)
    # Get all relevant API access methods from the resources we know about
    resources.map do |_, resource|
      p = resource.parameters
      [
        p[:protocol].value,
        p[:validate_tls].value,
        p[:host].value,
        p[:port].value,
        p[:timeout].value,
        (p.has_key?(:username) ? p[:username].value : nil),
        (p.has_key?(:password) ? p[:password].value : nil),
        (p.has_key?(:ca_file) ? p[:ca_file].value : nil),
        (p.has_key?(:ca_path) ? p[:ca_path].value : nil)
      ]
    # Deduplicate identical settings, and fetch repositories
    end.uniq.map do |api|
      repositories(*api)
    # Flatten and deduplicate the array, instantiate providers, and do the
    # typical association dance
    end.flatten.uniq.map{|resource| new resource}.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def flush
    uri = URI(
      "%s://%s:%d/_snapshot/%s" % [
      resource[:protocol],
      resource[:host],
      resource[:port],
      resource[:name]
    ])

    http = Net::HTTP.new uri.host, uri.port
    http.use_ssl = uri.scheme == 'https'
    [:ca_file, :ca_path].each do |arg|
      if not resource[arg].nil? and http.respond_to? arg
        http.send "#{arg}=".to_sym, resource[arg]
      end
    end

    case @property_flush[:ensure]
    when :absent
      req = Net::HTTP::Delete.new uri.request_uri
    else
      req = Net::HTTP::Put.new uri.request_uri
      body = {
        'type' => resource[:type],
        'settings' => {
          'compress' => resource[:compress],
          'location' => resource[:location]
        }
      }
      # Optional fields
      body['settings']['chunk_size'] = resource[:chunk_size] if resource[:chunk_size]
      body['settings']['max_restore_bytes_per_sec'] = resource[:max_restore_bps] if resource[:max_restore_bps]
      body['settings']['max_snapshot_bytes_per_sec'] = resource[:max_snapshot_bps] if resource[:max_snapshot_bps]
      req.body = JSON.generate(body)
    end

    response = self.class.rest(
      http,
      req,
      resource[:validate_tls],
      resource[:timeout],
      resource[:username],
      resource[:password]
    )

    # Attempt to return useful error output
    unless response.code.to_i == 200
      json = JSON.parse(response.body)

      if json.has_key? 'error'
        if json['error'].is_a? Hash and json['error'].has_key? 'root_cause'
          # Newer versions have useful output
          err_msg = json['error']['root_cause'].first['reason']
        else
          # Otherwise fallback to old-style error messages
          err_msg = json['error']
        end
      else
        # As a last resort, return the response error code
        err_msg = "HTTP #{response.code}"
      end

      raise Puppet::Error, "Elasticsearch API responded with: #{err_msg}"
    end

    @property_hash = self.class.repositories(
      resource[:protocol],
      resource[:validate_tls],
      resource[:host],
      resource[:port],
      resource[:timeout],
      resource[:username],
      resource[:password],
      resource[:ca_file],
      resource[:ca_path]
    ).detect do |t|
      t[:name] == resource[:name]
    end
  end

  def create
    @property_flush[:ensure] = :present
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

end # of .provide
