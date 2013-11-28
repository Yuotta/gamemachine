module GameMachine
  class Akka
    extend Forwardable

    attr_reader :hashring, :address, :app_config

    def initialize(app_config)
      @app_config = app_config
      @address = address_for(app_config.config.name)
      @hashring = Hashring.new([@address])
    end

    def address_for(server)
      host = app_config.server_config(server).akka_host
      port = app_config.server_config(server).akka_port
      "akka.tcp://#{config_name}@#{host}:#{port}"
    end

    def init_cluster!(address)
      @address = address
      @hashring = Hashring.new([address])
    end

    def cluster?
      app_config.config.cluster ? true : false
    end

    def actor_system
      @actor_system.actor_system
    end

    def config_name
      cluster? ? 'cluster' : 'standalone'
    end

    def akka_config
      cluster? ? akka_cluster_config : akka_server_config
    end

    def start
      @actor_system = Actor::System.new(config_name,akka_config)
      @actor_system.create!
      JavaLib::GameMachineLoader.new.run(actor_system,'deprecated')
      start_camel_extension
    end

    def stop
      @actor_system.shutdown!
      Actor::Base.reset_hashrings
    end

    private

    def set_address(config)
      config.sub!('HOST',app_config.config.akka_host)
      config.sub!('PORT',app_config.config.akka_port.to_s)
      config
    end

    def set_seeds(config)
      seeds = app_config.config.seeds.map do |seed| 
        seed_host = app_config.server_config(server).akka_host
        seed_port = app_config.instance.server_config(server).akka_port
        "\"akka.tcp://cluster@#{seed_host}:#{seed_port}\""
      end
      config.sub!('SEEDS',seeds.join(','))
      config
    end

    def akka_cluster_config
      config = load_akka_config('cluster')
      config = set_address(config)
      config = set_seeds(config)
    end

    def akka_server_config
      config = load_akka_config('standalone')
      set_address(config)
    end

    def load_akka_config(name)
      File.read(File.expand_path(File.join(
          GameMachine.app_root,"config/#{name}.conf")
        )
      )
    end

    def start_camel_extension
      if app_config.config.http_enabled
        camel = JavaLib::CamelExtension.get(actor_system)
        camel_context = camel.context
      end
    end

  end
end
