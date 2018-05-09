module Net
  module Hippie
    # A simple client for connecting with http resources.
    class Client
      DEFAULT_HEADERS = {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'User-Agent' => "net/hippie #{Net::Hippie::VERSION}"
      }.freeze

      attr_accessor :mapper

      def initialize(
        certificate: nil,
        headers: DEFAULT_HEADERS,
        key: nil,
        passphrase: nil,
        verify_mode: nil
      )
        @certificate = certificate
        @default_headers = headers
        @key = key
        @mapper = JsonMapper.new
        @passphrase = passphrase
        @verify_mode = verify_mode
      end

      def execute(uri, request)
        response = http_for(normalize_uri(uri)).request(request)
        if block_given?
          yield request, response
        else
          response
        end
      end

      def get(uri, headers: {}, body: {}, &block)
        request = request_for(Net::HTTP::Get, uri, headers: headers, body: body)
        execute(uri, request, &block)
      end

      def post(uri, headers: {}, body: {}, &block)
        type = Net::HTTP::Post
        request = request_for(type, uri, headers: headers, body: body)
        execute(uri, request, &block)
      end

      def put(uri, headers: {}, body: {}, &block)
        request = request_for(Net::HTTP::Put, uri, headers: headers, body: body)
        execute(uri, request, &block)
      end

      private

      attr_reader :default_headers
      attr_reader :verify_mode
      attr_reader :certificate, :key, :passphrase

      def http_for(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.read_timeout = 30
        http.use_ssl = uri.is_a?(URI::HTTPS)
        http.verify_mode = verify_mode
        http.set_debug_output(Net::Hippie.logger)
        if certificate && key
          http.cert = OpenSSL::X509::Certificate.new(certificate) if certificate
          http.key = private_key
        end
        http
      end

      def request_for(type, uri, headers: {}, body: {})
        type.new(uri, default_headers.merge(headers)).tap do |x|
          x.body = mapper.map_from(body) unless body.empty?
        end
      end

      def normalize_uri(uri)
        uri.is_a?(URI) ? uri : URI.parse(uri)
      end

      def private_key
        if passphrase
          OpenSSL::PKey::RSA.new(key, passphrase)
        else
          OpenSSL::PKey::RSA.new(key)
        end
      end
    end
  end
end
