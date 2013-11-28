module GameMachine
  class Grid

    class << self

      def reset_grids
        @grids = java.util.concurrent.ConcurrentHashMap.new
      end

      def grids
        unless @grids
          reset_grids
        end
        @grids
      end

      def get(name)
        grids.get(name)
      end

      def default_grid
        find_or_create('default')
      end

      def find_or_create(name, grid_size, cell_size)
        unless grids.containsKey(name)
          grids.put(name,JavaLib::Grid.new(grid_size,cell_size))
        end

        grids.get(name)
      end
    end

  end
end
