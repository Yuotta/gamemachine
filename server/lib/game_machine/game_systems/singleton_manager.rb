module GameMachine
  module GameSystems
    
    # TODO: register with cluster monitor so we can restart singletons if the 
    # node they are on goes down.

    # Updates should be optional, they aren't always wanted.

    # @note Manages the lifecycle of singleton controllers  
    #   - Sends a string message of 'update' to all singleton controllers
    #     at the update interval specifed in Settings::singleton_manager.update_count  
    #
    #   - Singleton controllers are distributed over the cluster using
    #     a distributed router.  
    #   
    #   - To create a singleton controller send an Entity to the singleton manager 
    #     with a CreateSingleton component.  You can attach any additional  
    #     components you wish.  The entity will be passed to the start  method
    #     of the singleton controller.  
    #
    # @aspects CreateSingleton
    # @aspects DestroySingleton
    # @aspects NotifySingleton
    #
    # @example Tells the manager to create a singleton controller
    #   entity = Entity.new
    #   entity.set_id('npc1')
    #   entity.set_create_singleton(
    #     CreateSingleton.new.set_id('npc1').set_controller(Demo::NpcController.name)
    #   )
    #   entity.set_is_npc(IsNpc.new.set_enabled(true))
    #   entity.set_vector3(Vector3.new.set_x(0.0).set_y(0.0).set_z(0.0))
    #   GameMachine::GameSystems::SingletonManager.find.tell(entity)
    class SingletonManager < Actor::Base
      
      def configure_aspects
        aspect %w(CreateSingleton)
        aspect %w(NotifySingleton)
        aspect %w(DestroySingleton)
      end

      def post_init(*args)
        router_count = args[0]
        update_interval = args[1]
        @actor_refs = create_singleton_routers(router_count)

        @slice_size = router_count / 10
        @slices = @actor_refs.each_slice(@slice_size).to_a
        schedule_update(update_interval)
      end

      def create_singleton_routers(router_count)
          GameMachine::Actor::Builder.new(app,SingletonRouter).distributed(
           router_count
          ).start
      end

      def send_in_slices
        @slices.each do |slice|
          slice.each do |actor_ref|
            actor_ref.tell('update',nil)
          end
          sleep 0.005
        end
      end

      def send_at_once
        @actor_refs.each do |actor_ref|
          actor_ref.tell('update',nil)
        end
      end

      def on_receive(message)
        if message.is_a?(String)
          if message == 'update'
            send_at_once
          end
        elsif message.has_notify_singleton
          ref = SingletonRouter.find_distributed_local(message.notify_singleton.id)
          ref.tell(message)
        elsif message.has_create_singleton
          ref = SingletonRouter.find_distributed_local(message.create_singleton.id)
          ref.tell(message)
        elsif message.has_destroy_singleton
          ref = SingletonRouter.find_distributed_local(message.destroy_singleton.id)
          ref.tell(message)
        else
          unhandled(message)
        end
      end

      def schedule_update(update_interval)
        duration = GameMachine::JavaLib::Duration.create(
          update_interval, java.util.concurrent.TimeUnit::MILLISECONDS
        )
        scheduler = get_context.system.scheduler
        dispatcher = get_context.system.dispatcher
        scheduler.schedule(duration, duration, get_self, "update", dispatcher, nil)
      end

    end
  end
end
