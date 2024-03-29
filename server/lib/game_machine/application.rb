module GameMachine
  class Application

    class << self

      def initialize!(name='default', cluster=false)
        AppConfig.instance.load_config(name)
        config.cluster = cluster
        akka.initialize!
      end

      def auth_handler
        AuthHandlers::Base.instance
      end

      def data_store
        DataStore.instance
      end

      def akka
        Akka.instance
      end

      def config
        @config ||= AppConfig.instance.config
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
        DataStore.instance.shutdown
      end

      def start
        GameMachine::Actor::Reloadable.update_paths(true)
        load_game_data
        start_actor_system
        auth_handler
        data_store
        start_endpoints
        start_core_systems
        start_handlers

        if GameMachine.env == 'development'
          start_development_systems
        end

        start_game_systems
        GameLoader.new.load_all
        start_mono

        GameMachine.stdout("Game Machine start successful")

        # This call blocks, make it the last thing we do
        if config.http_enabled
          start_http
        end
      end

      def start_http
        require_relative '../../web/app'
      end

      def start_mono
        if config.mono_enabled
          GameMachine.logger.info "Starting mono server"
          MonoServer.new.run!
        end
      end

      def load_game_data
        GameMachine::GameData.load_from(
          File.join(GameMachine.app_root,'config/game_data.yml')
        )
      end

      def start_endpoints
        if config.mono_enabled
          Actor::Builder.new(Endpoints::MonoGateway).start
          GameMachine.stdout(
            "MonoGateway starting on #{config.mono_gateway_host}:#{config.mono_gateway_port}"
          )
        end
        if config.tcp_enabled
          Actor::Builder.new(Endpoints::Tcp).start
          GameMachine.stdout(
            "Tcp starting on #{config.tcp_host}:#{config.tcp_port}"
          )
        end

        if config.udp_enabled
          Actor::Builder.new(Endpoints::Udp).start
          GameMachine.stdout(
            "UDP starting on #{config.udp_host}:#{config.udp_port}"
          )
        end

      end

      def start_handlers
        Actor::Builder.new(Handlers::Request).with_router(
          JavaLib::RoundRobinRouter,config.request_handler_routers
        ).start
        Actor::Builder.new(Handlers::Authentication).distributed(
          config.authentication_handler_ring_size
        ).start
        Actor::Builder.new(Handlers::Game).with_router(
          JavaLib::RoundRobinRouter,config.game_handler_routers
        ).start
      end

      def start_development_systems
      end

      # TODO configurize router sizes
      def start_core_systems
        Actor::Builder.new(ClusterMonitor).start
        Actor::Builder.new(PlayerGateway).start
        Actor::Builder.new(PlayerRegistry).start
        Actor::Builder.new(ObjectDb).distributed(2).start
        Actor::Builder.new(MessageQueue).start
        Actor::Builder.new(SystemMonitor).start
        Actor::Builder.new(ReloadableMonitor).start
        Actor::Builder.new(Scheduler).start
        Actor::Builder.new(WriteBehindCache).distributed(2).start
        Actor::Builder.new(GridReplicator).start
        Actor::Builder.new(GameSystems::EntityLoader).start


        if ENV.has_key?('RESTARTABLE')
          GameMachine.logger.info "restartable=true.  Will respond to tmp/gm_restart.txt"
          Actor::Builder.new(RestartWatcher).start
        end
      end

      def start_game_systems
        Actor::Builder.new(GameSystems::Devnull).start#.with_router(JavaLib::RoundRobinRouter,4).start
        Actor::Builder.new(GameSystems::ObjectDbProxy).with_router(JavaLib::RoundRobinRouter,4).start
        Actor::Builder.new(GameSystems::EntityTracking).with_router(JavaLib::RoundRobinRouter,4).start
        Actor::Builder.new(GameSystems::LocalEcho).with_router(JavaLib::RoundRobinRouter,2).start
        Actor::Builder.new(GameSystems::LocalEcho).with_name('DistributedLocalEcho').distributed(2).start
        Actor::Builder.new(GameSystems::RemoteEcho).with_router(JavaLib::RoundRobinRouter,2).start
        Actor::Builder.new(GameSystems::ChatManager).start
        Actor::Builder.new(GameSystems::PlayerManager).with_router(JavaLib::RoundRobinRouter,2).start
      end

    end
  end
end
