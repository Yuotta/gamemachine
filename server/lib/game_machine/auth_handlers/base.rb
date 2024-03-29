require 'forwardable'

module GameMachine
  module AuthHandlers
    class Base
      include Singleton
      extend Forwardable

      def_delegators :@handler, :authorize, :authtoken_for, :load_users,
        :add_user

      def initialize
        @handler = Application.config.auth_handler.constantize.new
      end

      def set_handler(handler_name)
        @handler = handler_name.constantize.new
      end
    end
  end
end

