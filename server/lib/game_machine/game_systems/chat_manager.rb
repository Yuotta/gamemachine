module GameMachine
  module GameSystems

    # @note All chat system requests go through the ChatManager
    #   Chat can be topic based or private player to player messages
    #   Topics are automatically created by the first player to send a join
    #   request to a topic that does not already exist.  
    #   Chat topic channels are distributed across the cluster, and guaranteed
    #   to be delivered.
    #
    # @aspects ChatMessage Player
    # @aspects JoinChat Player
    # @aspects LeaveChat Player
    class ChatManager < Actor::Base
      include GameMachine::Commands


      aspect %w(ChatMessage Player)
      aspect %w(JoinChat Player)
      aspect %w(LeaveChat Player)
      aspect %w(ChatStatus Player)

      def define_update_procs
        commands.datastore.define_dbproc(:chat_remove_subscriber) do |current_entity,update_entity|
          if current_entity.has_subscribers
            if subscriber_id_list = current_entity.subscribers.get_subscriber_id_list
              subscriber_id_list.remove(update_entity.id)
            end
          end
          current_entity
        end

        commands.datastore.define_dbproc(:chat_add_subscriber) do |current_entity,update_entity|
          unless current_entity.has_subscribers
            current_entity.set_subscribers(MessageLib::Subscribers.new)
          end
          current_entity.subscribers.add_subscriber_id(update_entity.id)
          current_entity
        end
      end

      def post_init(*args)
        @chat_actors = {}
        define_update_procs
      end

      def on_receive(message)
        if message.is_a?(MessageLib::Disconnected)
          destroy_child(message)
        else
          unless @chat_actors.has_key?(message.player.id)
            create_child(message.player.id)
            PlayerRegistry.find.tell(
              MessageLib::RegisterPlayerObserver.new.set_player_id(message.player.id)
            )
          end
          forward_chat_request(message.player.id,message)
        end
      end

      private

      def destroy_child(message)
        player_id = message.player_id
        if @chat_actors.has_key?(player_id)
          forward_chat_request(player_id,JavaLib::PoisonPill.get_instance)
          @chat_actors.delete(player_id)
          GameMachine.logger.debug "Chat child for #{player_id} killed"
        else
          GameMachine.logger.info "chat actor for player_id #{player_id} not found"
        end
      end

      def forward_chat_request(player_id,message)
        @chat_actors[player_id].tell(message,nil)
      end

      def child_name(player_id)
        "chat#{player_id}"
      end

      def create_child(player_id)
        name = child_name(player_id)
        builder = Actor::Builder.new(GameSystems::Chat,player_id)
        child = builder.with_parent(context).with_name(name).start
        @chat_actors[player_id] = Actor::Ref.new(child,GameSystems::Chat.name)
        GameMachine.logger.debug "Chat child for #{player_id} created"
      end
    end
  end
end
