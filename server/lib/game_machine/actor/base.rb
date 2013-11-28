module GameMachine
  module Actor

    class DuplicateHashringError < StandardError;end
    class MissingHashringError < StandardError;end

    # @abstract All game actors inherit fromm this class
    class Base < JavaLib::UntypedActor
  
      attr_reader :app_config, :app, :actor_name

      @@player_controller = nil

      class << self
        alias_method :apply, :new
        alias_method :create, :new

        # Sets the system wide player controller class.
        # When a player logs in, a player controller with this class
        # will be created. The system notifies the player controller when
        # various player lifecycle events happen.
        #
        # This should only be called on subclasses, never on the Actor base
        # class
        def set_player_controller
          @@player_controller = self
          GameMachine.logger.info("Player controller set to #{self.name}")
        end

        def player_controller
          @@player_controller
        end

        def reset_hashrings
          @hashrings = nil
        end

        def hashrings
          @hashrings ||= java.util.concurrent.ConcurrentHashMap.new
        end

        def hashring(name)
          hashrings.fetch(name,nil)
        end

        def add_hashring(name,hashring)
          if hashring(name)
            raise DuplicateHashringError, "name=#{name}"
          end
          hashrings[name] = hashring
        end

        # Find a local actor by name
        # @return [Actor::Ref]
        def find(app,name)
          Actor::Ref.new(local_path(name),app.akka.actor_system)
        end

        # Find a remote actor by name
        # @return [Actor::Ref]
        def find_remote(app,server,name)
          Actor::Ref.new(remote_path(app.akka,server,name),app.akka.actor_system)
        end

        # Returns a local actor ref from the distributed ring of actors based
        # on a consistent hashing of the id.
        # @return [Actor::Ref]
        def find_distributed_local(app,id,name)
          ensure_hashring(name)
          Actor::Ref.new(local_distributed_path(id, name),app.akka.actor_system)
        end

        # Returns an actor ref from the distributed ring of actors based
        # on a consistent hashing of the id. The actor returned can be from
        # any server in the cluster
        # @return [Actor::Ref]
        def find_distributed(app,id,name)
          ensure_hashring(name)
          Actor::Ref.new(distributed_path(app.akka,id, name),app.akka.actor_system)
        end

        def local_path(name)
          "/user/#{name}"
        end

        private

        def ensure_hashring(name)
          unless hashring(name)
            raise MissingHashringError
          end
        end

        def remote_path(akka,server,name)
          "#{akka.address_for(server)}/user/#{name}"
        end

        def local_distributed_path(id,name)
          bucket = hashring(name).bucket_for(id)
          "/user/#{bucket}"
        end

        def distributed_path(akka,id,name)
          server = akka.hashring.bucket_for(id)
          bucket = hashring(name).bucket_for(id)
          "#{server}/user/#{bucket}"
        end
      end


      def find(name)
        self.class.find(app,name)
      end

      def find_remote(server,name)
        self.class.find_remote(app,server,name)
      end

      def find_distributed_local(id,name)
        self.class.find_distributed_local(app,id,name)
      end

      def find_distributed(id,name)
        self.class.find_distributed(app,id,name)
      end

      def onReceive(message)
        #GameMachine.logger.debug("#{self.class.name} got #{message}")
        on_receive(message)
      end

      def on_receive(message)
        unhandled(message)
      end

      def aspects
        @aspects ||= []
      end
      
      def aspect(new_aspects)
        aspects << new_aspects
        unless app.registered.include?(self.class)
          app.register(self.class)
        end
      end

      def sender
        Actor::Ref.new(get_sender)
      end

    end
  end
end
