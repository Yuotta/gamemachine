module GameMachine
  class Application

    def self.instances
      if @instances
        @instances
      else
        @instances = java.util.concurrent.ConcurrentHashMap.new
      end
    end

    def self.instance_for(name)
      instances.fetch(name,nil)
    end

    def self.create(name='default', cluster=false)
      instances[name] = new(name,cluster)
    end

    attr_reader :config, :auth_handler, :data_store, :akka, :grid

    def initialize(name,cluster)
      app_config = AppConfig.new
      app_config.load_config(name)
      @config = app_config.config
      config.cluster = cluster
      @grid = Grid.find_or_create(config.name,config.world_grid_size,config.world_grid_cell_size)
      @akka = Akka.new(app_config)
      load_game_data
      @auth_handler = AuthHandlers::Base.new(config.auth_handler)
      @data_store = DataStore.new(config.data_store,config.couchbase_servers)
      load_mono
    end

    def registered
      @@registered ||= Set.new
    end

    def register(system_class)
      registered << system_class
      GameMachine.logger.debug "#{system_class} registered"
    end

    def start_actor_system
      akka.start
    end

    def stop_actor_system
      akka.stop
    end

    def stop
      stop_actor_system
      data_store.shutdown
      JavaLib::UdtServer.stop
    end

    def start
      load_game_data
      start_actor_system
      auth_handler
      data_store
      start_endpoints
      start_core_systems
      start_handlers
      start_game_systems
      GameLoader.new.load_all
      GameMachine.stdout("Game Machine start successful")
    end

    def load_mono
      if config.mono_enabled
        require_relative 'mono'
      end
    end

    def load_game_data
      GameMachine::GameData.load_from(
        File.join(GameMachine.app_root,'config/game_data.yml')
      )
    end

    def start_endpoints
      if config.tcp_enabled
        Actor::Builder.new(self,Endpoints::Tcp,config.tcp_host,config.tcp_port,config.game_handler,config.name).start
        GameMachine.stdout(
          "Tcp starting on #{config.tcp_host}:#{config.tcp_port}"
        )
      end

      if config.udp_enabled
        Actor::Builder.new(self,Endpoints::Udp,config.udp_host,config.udp_port,config.game_handler,config.name).start
        GameMachine.stdout(
          "UDP starting on #{config.udp_host}:#{config.udp_port}"
        )
      end

      if config.udt_enabled
        Actor::Builder.new(self,Endpoints::Udt,config.game_handler).start
        JavaLib::UdtServer.start(config.udt_host,config.udt_port)
        GameMachine.stdout(
          "UDT starting on #{config.udt_host}:#{config.udt_port}"
        )
      end
      
      if config.http_enabled
        props = JavaLib::Props.new(Endpoints::Http::Auth)
        akka.actor_system.actor_of(props,Endpoints::Http::Auth.name)
        props = JavaLib::Props.new(Endpoints::Http::Rpc)
        akka.actor_system.actor_of(props,Endpoints::Http::Rpc.name)
      end
    end

    def start_handlers
      Actor::Builder.new(self,Handlers::Request).with_router(
        JavaLib::RoundRobinRouter,config.request_handler_routers
      ).start
      Actor::Builder.new(self,Handlers::Authentication).distributed(
        config.authentication_handler_ring_size
      ).start
      Actor::Builder.new(self,Handlers::Game,config.name).with_router(
        JavaLib::RoundRobinRouter,config.game_handler_routers
      ).start
    end

    # TODO configurize router sizes
    def start_core_systems
      Actor::Builder.new(self,ClusterMonitor).start
      Actor::Builder.new(self,PlayerGateway,config.name).start
      Actor::Builder.new(self,PlayerRegistry).start
      Actor::Builder.new(self,ObjectDb).distributed(2).start
      Actor::Builder.new(self,MessageQueue).start
      Actor::Builder.new(self,SystemMonitor).start
      Actor::Builder.new(self,Scheduler).start
      Actor::Builder.new(self,WriteBehindCache,config.cache_write_interval,config.cache_writes_per_second).distributed(2).start
      Actor::Builder.new(self,GridReplicator).start
      Actor::Builder.new(self,GameSystems::EntityLoader).start
    end

    def start_game_systems
      Actor::Builder.new(self,GameSystems::EntityTracking).with_router(JavaLib::RoundRobinRouter,4).start
      Actor::Builder.new(self,GameSystems::LocalEcho).with_router(JavaLib::RoundRobinRouter,2).start
      Actor::Builder.new(self,GameSystems::LocalEcho).with_name('DistributedLocalEcho').distributed(2).start
      Actor::Builder.new(self,GameSystems::RemoteEcho).with_router(JavaLib::RoundRobinRouter,2).start
      Actor::Builder.new(self,GameSystems::ChatManager).start
      Actor::Builder.new(self,GameSystems::SingletonManager,config.singleton_manager_router_count,config.singleton_manager_update_interval).start
      Actor::Builder.new(self,GameSystems::PlayerManager).with_router(JavaLib::RoundRobinRouter,2).start
    end

  end
end
