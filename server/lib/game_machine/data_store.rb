require 'forwardable'
require_relative 'data_stores/memory'
require_relative 'data_stores/couchbase'
require_relative 'data_stores/mapdb'
require_relative 'data_stores/redis'

module GameMachine
  class DataStore
    extend Forwardable

    def_delegators :@store, :get, :set, :delete, :delete_all, :shutdown

    def initialize(store_name,couchbase_servers)
      @store_name = store_name
      @couchbase_servers = couchbase_servers
      connect
    end

    def set_store(store_name)
      @store = nil
      @store_name = store_name
      connect
    end

    private

    def connect
      raise "already connected" if @store
      send("connect_#{@store_name}")
    end

    def connect_couchbase
      @store = DataStores::Couchbase.new(couchbase_servers)
      @store.connect
    end

    def connect_mapdb
      @store = DataStores::Mapdb.new
      @store.connect
    end

    def connect_redis
      @store = DataStores::Redis.new
      @store.connect
    end

    def connect_memory
      @store = DataStores::Memory.new
    end
  end
end
