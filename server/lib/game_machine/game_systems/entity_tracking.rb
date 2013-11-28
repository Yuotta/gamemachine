module GameMachine
  module GameSystems

    # @note Handles player location tracking and neighbor requests.
    #   The client must explicitly send a TrackEntit component to the server
    #   to be tracked, it doesn't happen automatically.
    #
    # @aspects TrackEntity
    # @aspects GetNeighbors
    class EntityTracking < Actor::Base

      attr_reader :grid

      def configure_aspects
        aspect %w(TrackEntity)
        aspect %w(GetNeighbors)
      end

      def post_init
        @entity_updates = []
        @grid = app.grid
        @paths = {}
        @width = grid.get_width
        @cell_count = grid.get_cell_count
      end

      def on_receive(message)
        if message.is_a?(MessageLib::Entity)
          if message.get_neighbors
            send_neighbors(message)
          end

          if message.track_entity
            set_entity_location(message)
          end
        else
          unhandled(message)
        end
      end

      private

      def set_entity_location(entity)
        vector = entity.vector3
        @grid.set(entity.id,vector.x,vector.z,vector.y,entity.entity_type)
      end

      def location_entity(grid_value)
        MessageLib::Entity.new.set_id(grid_value.id).set_vector3(
          MessageLib::Vector3.new.
          set_xi(grid_value.x.to_i).
          set_yi(grid_value.z.to_i).
          set_zi(grid_value.y.to_i)
        )
      end

      def send_neighbors(message)
        type = message.get_neighbors.neighbor_type
        x = message.get_neighbors.vector3.x
        z = message.get_neighbors.vector3.z
        search_results = grid.neighbors(x,z,type)
       
        neighbors = {:players => [], :npcs => []}
        search_results.each do |grid_value|
          if grid_value.entityType == 'player'
            neighbors[:players] << location_entity(grid_value)
          elsif grid_value.entityType == 'npc'
            neighbors[:npcs] << location_entity(grid_value)
          end
        end
 
        if neighbors[:players].empty? && neighbors[:npcs].empty?
          return
        end

        if message.has_player
          send_neighbors_to_player(neighbors,message.player)
        end
      end

      def send_neighbors_to_player(neighbors,player)
        entity = MessageLib::Entity.new.set_neighbors(
          MessageLib::Neighbors.new.
          set_player_list(neighbors[:players]).
          set_npc_list(neighbors[:npcs])
        )
        entity.set_id(player.id)
        entity.set_player(player)
        entity.set_send_to_player(true)
        PlayerGateway.find.tell(entity)
      end

    end
  end
end
