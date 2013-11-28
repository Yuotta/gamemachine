module GameMachine
  module Endpoints
    class TcpHandler < Actor::Base

      attr_reader :game_handler, :server_name
      def post_init(*args)
        @name = args[0]
        @game_handler = args[1]
        @server_name = args[2]
        @con_ref = nil
        @client_id = nil
        @message_buffer = MessageBuffer.new
      end

      def on_receive(message)
        if message.kind_of?(JavaLib::Tcp::ConnectionClosed)
          client_message = client_disconnect_message(@client_id)
          Actor::Base.find(game_handler).tell(client_message,get_self)
          get_context.stop(get_self)
        elsif message.kind_of?(JavaLib::Tcp::Received)
          handle_incoming(message)
        elsif message.is_a?(MessageLib::ClientMessage)
          handle_outgoing(message)
        elsif message.kind_of?(JavaLib::Tcp::Connected)
          @con_ref = get_sender
          @client_id = message.remote_address.to_s
        else
          unhandled(message)
        end
      end

      private

      def client_disconnect_message(client_id)
        MessageLib::ClientMessage.new.set_client_disconnect(
          MessageLib::ClientDisconnect.new.set_client_connection(
            MessageLib::ClientConnection.new.set_id(client_id).set_gateway(@name)
          )
        )
      end

      def handle_outgoing(message)
        byte_string = JavaLib::ByteString.from_array(message.to_byte_array)
        tcp_message = JavaLib::TcpMessage.write(byte_string)
        @con_ref.tell(tcp_message, get_self)
      rescue Exception => e
        GameMachine.logger.error "#{self.class.name} #{e.to_s}"
      end

      def handle_incoming(message)
        @message_buffer.add_bytes(message.data.to_array)
        @message_buffer.messages.each do |message_bytes|
          client_message = create_client_message(
            message_bytes,@client_id
          )
          Actor::Base.find(game_handler).tell(client_message,get_self)
        end
      rescue Exception => e
        GameMachine.logger.error "TcpHandler.handle_incoming: #{@name} #{e.to_s}"
      end

      def create_client_message(data,client_id)
        MessageLib::ClientMessage.parse_from(data).set_client_connection(
          MessageLib::ClientConnection.new.set_id(client_id).set_gateway(@name).
          set_server(server_name)
        )
      end

    end
  end
end
