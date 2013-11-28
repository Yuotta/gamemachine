module GameMachine
  module Handlers
    class Game < Actor::Base 
      include Commands

      attr_reader :registered

      def post_init(*args)
        @registered = args[0]
      end

      def on_receive(message)
        if message.is_a?(MessageLib::ClientMessage)
          if message.get_entity_list
            dispatch_entities(message.get_entity_list)
          end
        else
          unhandled(message)
        end
      end

      private

      def dispatch_entities(entities)
        entities.each do |entity|
          if entity.save
            entity.set_save(false)
            commands.datastore.put(entity)
          end
          component_names = entity.component_names
          GameMachine.logger.debug("Dispatch: #{entity} #{component_names.to_a.inspect}")
          next if component_names.empty?
          registered.each do |klass|
            dispatched = false
            klass.aspects.each do |aspect|
              next if dispatched
              if (aspect & component_names).size == aspect.size
                klass.find.tell(entity)
                dispatched = true
              end
            end
          end
        end
      end

    end
  end
end

