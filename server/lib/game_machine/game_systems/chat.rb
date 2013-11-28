module GameMachine
  module GameSystems
    class Chat < Actor::Base
      include GameMachine::Commands

      def self.subscribers_for_topic(topic)
        datastore = GameMachine::Commands::DatastoreCommands.new
        if entity = datastore.get("chat_topic_#{topic}")
          entity.subscribers || MessageLib::Subscribers.new
        else
          MessageLib::Subscribers.new
        end
      end

      def define_update_procs
        commands.datastore.define_dbproc(:chat_remove_subscriber) do |current_entity,update_entity|
          if subscriber_id_list = current_entity.subscribers.get_subscriber_id_list
            subscriber_id_list.remove(update_entity.id)
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
        @player_id = args.first
        @topic_handlers = {}
        @subscriptions = []
        define_update_procs
      end

      def on_receive(entity)
        if entity.has_join_chat
          join_channels(entity.join_chat.get_chat_channel_list)
        end

        if entity.has_chat_message
          send_message(entity.chat_message)
        end

        if entity.has_leave_chat
          leave_channels(entity.leave_chat.get_chat_channel_list)
        end
        send_player_update
      end

      private

      def send_player_update
        channels = MessageLib::ChatChannels.new
        @subscriptions.each do |name|
          channels.add_chat_channel(
            MessageLib::ChatChannel.new.set_name(name).
            set_subscribers(self.class.subscribers_for_topic(name))
          )
        end
        commands.player.send_message(channels,@player_id)
      end

      def message_queue
        MessageQueue.find
      end

      def topic_handler_for(name)
        @topic_handlers.fetch(name,nil)
      end

      def create_topic_handler(topic)
        name = "topic#{@player_id}#{topic}"
        builder = Actor::Builder.new(app,GameSystems::ChatTopic,@player_id)
        ref = builder.with_parent(context).with_name(name).start
        actor_ref = Actor::Ref.new(ref,GameSystems::ChatTopic.name)
        @topic_handlers[topic] = actor_ref
      end

      def remove_subscriber(subscriber_id,topic)
        stored_entity_id = "chat_topic_#{topic}"
        entity = MessageLib::Entity.new.set_id(subscriber_id)
        commands.datastore.call_dbproc(:chat_remove_subscriber,stored_entity_id,entity)
      end

      def add_subscriber(subscriber_id,topic)
        stored_entity_id = "chat_topic_#{topic}"
        entity = MessageLib::Entity.new.set_id(subscriber_id)
        commands.datastore.call_dbproc(:chat_add_subscriber,stored_entity_id,entity)
      end

      def join_channels(chat_channels)
        chat_channels.each do |channel|
          next if @topic_handlers[channel.name]
          create_topic_handler(channel.name)
          message = MessageLib::Subscribe.new.set_topic(channel.name)
          message_queue.tell(message,topic_handler_for(channel.name).actor)
          @subscriptions << channel.name
          add_subscriber(@player_id,channel.name)
        end
      end

      # TODO destroy topic handler when leaving channel
      def leave_channels(chat_channels)
        chat_channels.each do |channel|
          if topic_handler = topic_handler_for(channel.name)
            message = MessageLib::Unsubscribe.new.set_topic(channel.name)
            message_queue.tell(message,topic_handler_for(channel.name).actor)
            @subscriptions.delete_if {|sub| sub == channel.name}
            remove_subscriber(@player_id,channel.name)
          else
            GameMachine.logger.info "leave_channel: no topic handler found for #{channel.name}"
          end
        end
      end

      def send_private_message(chat_message)
        GameMachine.logger.info "Sending private chat message #{chat_message.message} to #{chat_message.chat_channel.name}"
        entity = MessageLib::Entity.new
        player = MessageLib::Player.new.set_id(chat_message.chat_channel.name)
        entity.set_id(player.id)
        entity.set_player(player)
        entity.set_chat_message(chat_message)
        entity.set_send_to_player(true)
        PlayerGateway.find.tell(entity)
      end

      def send_group_message(chat_message)
        topic = chat_message.chat_channel.name
        if topic_handler = topic_handler_for(topic)
          entity = MessageLib::Entity.new.set_id('0').set_chat_message(chat_message)
          publish = MessageLib::Publish.new
          publish.set_topic(topic).set_message(entity)
          message_queue.tell(publish,topic_handler_for(topic).actor)
        else
          GameMachine.logger.info "send_message: no topic handler found for #{topic}"
        end
      end

      def send_message(chat_message)
        if chat_message.type == 'group'
          send_group_message(chat_message)
        elsif chat_message.type == 'private'
          send_private_message(chat_message)
        end
      end

    end
  end
end
