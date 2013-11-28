require_relative 'settings'
module GameMachine
  class AppConfig
    attr_reader :config

    def initialize
      @config = OpenStruct.new
    end

    def reload
      @config = OpenStruct.new
      load_config
    end

    def server_config(server)
      Settings.servers.send(server)
    end

    def load_config(name)
      config.name = name
      config.login_username = 'player'
      config.authtoken = 'authorized'
      config.request_handler_routers = 20
      config.game_handler_routers = 20
      config.authentication_handler_ring_size = 160
      load_settings(name)
    end

    private

    def load_settings(name)
      Settings.servers.send(name).each do |key,value|
        config.send("#{key}=",value)
      end
    end

  end
end
