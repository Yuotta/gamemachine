require 'active_support/inflector'
module GameMachine
  module GameSystems
    class PlayerManager < Actor::Base
        PLAYER_CONTROLLERS = java.util.concurrent.ConcurrentHashMap.new
      
      def post_init
      end

      def destroy_player_controller(id)
        if controller = PLAYER_CONTROLLERS.fetch(id,nil)
          controller.tell(JavaLib::PoisonPill.get_instance,get_self)
          PLAYER_CONTROLLERS.delete(id)
        else
          GameMachine.logger.error("Player Controller for #{id} not found")
        end
      end

      def create_player_controller(message)
        if controller_class = Actor::Base.player_controller
          id = message.player.id
          builder = Actor::Builder.new(app,controller_class,message)
          child = builder.with_parent(context).with_name(id).start
          PLAYER_CONTROLLERS[id] = child
        end
      rescue Exception => e
        GameMachine.logger.error("Create Player Controller error: #{e.class} #{e.message}")
      end

      def send_to_player_controller(message)
        if player_controller = PLAYER_CONTROLLERS.fetch(message.player.id,nil)
          player_controller.tell(message,get_self)
        else
          GameMachine.logger.error("Player Controller for #{message.player.id} not found")
        end
      end

      def destroy_player(player_id)
        GameSystems::EntityTracking.grid.remove(player_id)
        GameMachine::Handlers::Authentication.unregister_player(player_id)
        destroy_player_controller(player_id)
      end

      def on_receive(message)
        if message.is_a?(MessageLib::ClientMessage)
          if message.has_player_logout
            PlayerRegistry.find.tell(message.player_logout)
            destroy_player(message.player.id)
          elsif message.has_client_disconnect
            PlayerRegistry.find.tell(message.client_disconnect)
            if player_id = PlayerRegistry.player_id_for(message.client_connection.id)
              destroy_player(player_id)
            end
          end
        elsif message.is_a?(MessageLib::Entity)
          if message.has_player_authenticated
            create_player_controller(message)
            send_to_player_controller(message)
          else
            send_to_player_controller(message)
          end
        else
          unhandled(message)
        end
      end

    end
  end
end


