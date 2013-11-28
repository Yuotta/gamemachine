module GameMachine
  module GameSystems
    class RemoteEcho < Actor::Base

      def configure_aspects
        aspect %w(EchoTest)
      end

      def on_receive(message)
        message.set_send_to_player(true)
        PlayerGateway.find.tell(message)
      end
    end
  end
end

