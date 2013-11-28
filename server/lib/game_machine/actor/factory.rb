module GameMachine
  module Actor

    class Factory
      include JavaLib::UntypedActorFactory

      def initialize(application,name,klass,args)
        @application = application
        @name = name
        @klass = klass
        @args = args
      end

      def create
        actor = @klass.new
        actor.instance_variable_set(:@actor_name, @name)
        actor.instance_variable_set(:@app_config, @application.config)
        actor.instance_variable_set(:@app, @application)

        if actor.respond_to?(:initialize_states)
          actor.initialize_states
        end

        if actor.respond_to?(:post_init)
          actor.post_init(*@args)
        end

        if actor.respond_to?(:configure_aspects)
          actor.configure_aspects
        end

        actor
      end

      def self.create
      end

    end
  end
end
