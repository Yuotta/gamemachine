module GameMachine
  module Actor

    class Builder

      attr_reader :name

      # Creates an actor builder instance.  First argument is the actor class
      # remaining arguments are optional and will be passed to post_init
      # @param args 
      # @return self
      attr_reader :application, :klass, :actor_system
      def initialize(*args)
        @application = args.shift
        @klass = args.shift
        @name = klass.name.sub('GameMachine::','').sub('::','_').underscore
        puts "ACTOR_NAME= #{@name}"
        @create_hashring = false
        @hashring_size = 0
        @props = JavaLib::Props.new(Actor::Factory.new(application,@name,klass,args))
        @actor_system = application.akka.actor_system
      end

      # Sets the parent actor
      # @param parent
      # @return self
      def with_parent(parent)
        actor_system = parent
        self
      end

      # Sets the actor's name
      # @param name
      # @return self
      def with_name(name)
        @name = name
        self
      end

      def with_dispatcher(name)
        @props = @props.with_dispatcher(name)
        self
      end

      # Run the actor under a router
      # @param router_class [Class] num_router [Integer]
      # @return self
      def with_router(router_class,num_routers)
        @props = @props.with_router(
          router_class.new(num_routers)
        )
        self
      end

      # Creates this router as a distributed router. It will create a group
      # of actors distributed using consistent hashing.  Suggest a hashring size
      # of at least 40 up to 160.
      # @param hashring_size [Integer]
      # @return self
      def distributed(hashring_size)
        @create_hashring = true
        @hashring_size = hashring_size
        self
      end

      # Start the actor(s). If the actor is distributed returns the entire
      # Array of actor refs in the hash ring, otherwise a single actor ref
      # @return actor ref
      def start
        GameMachine.logger.debug "Game actor #{@name} starting"
        if @create_hashring
          hashring = create_hashring(@hashring_size)
          hashring.buckets.map do |bucket_name|
            actor_system.actor_of(@props, bucket_name)
          end
        else
          actor_system.actor_of(@props, @name)
        end
      end


      private

      def create_hashring(bucket_count)
        hashring = Hashring.create_actor_ring(@name,bucket_count)
        @klass.add_hashring(@name,hashring)
        hashring
      end

    end
  end
end
