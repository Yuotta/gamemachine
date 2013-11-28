require 'forwardable'
module GameMachine
  module DataStores
    class Couchbase
      extend Forwardable

      def_delegators :@client, :get, :set, :delete, :shutdown

      attr_reader :server_urls
      def initialize(server_urls)
        @server_urls = server_urls
      end

      def connect
        @client ||= JavaLib::CouchbaseClient.new(servers, 'default'.to_java_string, ''.to_java_string)
      end

      def servers
        server_urls.map {|server| java.net.URI.new(server)}
      end
    end
  end
end
