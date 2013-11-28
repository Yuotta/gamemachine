module GameMachine
  module Endpoints
    class Udt < JavaLib::UntypedActor
      class << self
        alias_method :apply, :new
        alias_method :create, :new
      end
 
      attr_reader :game_handler
      def post_init(*args)
        @game_handler = args[0]
      end

      def preStart
        @clients = {}
      end

      def onReceive(message)
        GameMachine.logger.debug("Udt onReceive #{message}")
        if message.is_a?(JavaLib::NetMessage)
          client_id = get_client_id(message)

          if message.protocol == JavaLib::NetMessage::DISCONNECTED
            client_message = client_disconnect_message(client_id)
            @clients.delete(client_id) if @clients[client_id]
          else
            @clients[client_id] = message
            client_message = create_client_message(message.bytes,client_id)
          end

          Actor::Base.find(game_handler).
            send_message(client_message, :sender => get_self)
        elsif message.is_a?(MessageLib::ClientMessage)
          if @clients[message.client_connection.id]
            JavaLib::UdtServer.get_udt_server.send_to_client(
              message.to_byte_array,
              @clients[message.client_connection.id].ctx
            )
          else
            GameMachine.logger.error "UDT outgoing message with invalid client_id"
          end
        else 
          unhandled(message)
        end
      end

      private

      def client_disconnect_message(client_id)
        MessageLib::ClientMessage.new.set_client_disconnect(
          MessageLib::ClientDisconnect.new.set_client_connection(
            MessageLib::ClientConnection.new.set_id(client_id).set_gateway(self.class.name)
          )
        )
      end

      def create_client_message(data,client_id)
        MessageLib::ClientMessage.parse_from(data).set_client_connection(
          MessageLib::ClientConnection.new.set_id(client_id).set_gateway(self.class.name)
        )
      end

      def get_client_id(netMessage)
        "#{netMessage.host}:#{netMessage.port}"
      end

    end
  end
end
