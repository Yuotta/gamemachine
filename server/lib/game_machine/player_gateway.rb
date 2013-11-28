module GameMachine
  class PlayerGateway < Actor::Base

    def post_init(*args)
      @players = {}
      @paths = {}
      @name = args.first
      find(:cluster_monitor).tell('register_observer',get_self)
    end


    def player(player_id)
      MessageLib::Player.new.
        set_id(player_id).
        set_name(player_id)
    end

    def replicate(message)
      GameMachine::ClusterMonitor.remote_members.keys.each do |address|
        path = "#{address}#{self.class.local_path(actor_name)}"
        Actor::Ref.new(path).tell(message,get_self)
      end
    end

    def replicate_players
      @players.values.each do |player_info|
        client_connection = player_info[:client_connection]
        player_id = player_info[:player_id]

        player_register = MessageLib::PlayerRegister.new.
          set_player_id(player_id).
          set_client_connection(client_connection)
        replicate(player_register)
      end
    end

    def on_receive(message)
      if message.is_a?(String)
        if message == 'cluster_update'
          replicate_players
        end
      elsif message.has_client_connection
        @players[message.player_id] = {
          :player_id => message.player_id,
          :client_connection => message.client_connection
        }
        unless get_sender.path.name == 'player_gateway'
          replicate(message)
        end
      elsif message.send_to_player
        if player_info = @players.fetch(message.player.id,nil)
          client_connection = player_info[:client_connection]
          if @name == client_connection.server
            client_message = MessageLib::ClientMessage.new
            client_message.set_player(player(message.player.id))
            client_message.set_client_connection(client_connection)
            message.set_send_to_player(false)
            client_message.add_entity(message)
            find(client_connection.gateway).tell(client_message)
          else
            find_remote(client_connection.server,actor_name).tell(message)
          end
        else
          GameMachine.logger.info "playerinfo not found for #{message.player.id}"
          unhandled(message)
        end
      end
    end

  end
end

