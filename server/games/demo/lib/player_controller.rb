module Demo
  class PlayerController < GameMachine::Actor::Base
    include GameMachine::Commands

    set_player_controller

    def post_init(*args)
      entity = args.first
      @player = entity.player
      @base_health = 1000
      init_player
    end

    def init_player
    end

    def set_player_health(player)
      #player.set_health(
      #  Health.new.set_health(@base_health)
      #)
    end

    def on_receive(message)
      if message.has_player_authenticated
        GameMachine.logger.error "#{self.class.name} #{message.player}"
        commands.player.send_message(message,message.player.id)
        if entity = commands.datastore.get(message.player.id)
          set_player_health(entity.player)
        else
          entity = GameMachine::MessageLib::Entity.new.set_id(message.player.id).
            set_player(message.player.clone)
          set_player_health(entity.player)
        end
        commands.datastore.put(entity)
      end
    end
  end
end
