module GameMachine
  class GridReplicator < Actor::Base

    attr_reader :grid
    def post_init(*args)
      @paths = {}
      schedule_update(80)
      @grid = app.grid
    end

    def on_receive(message)
      if message.is_a?(String)
        delta = grid.current_delta
        return if delta.length == 0
        GameMachine::ClusterMonitor.remote_members.keys.each do |address|
          @paths[address] ||= "#{address}#{self.class.local_path(self.class.name)}"
          Actor::Ref.new(@paths[address],self.class.name).tell(delta)
        end
      else
        grid.update_from_delta(message)
      end
      
    end

    def schedule_update(update_interval)
      duration = GameMachine::JavaLib::Duration.create(update_interval, java.util.concurrent.TimeUnit::MILLISECONDS)
      scheduler = get_context.system.scheduler
      dispatcher = get_context.system.dispatcher
      scheduler.schedule(duration, duration, get_self, "replicate_grid", dispatcher, nil)
    end

  end
end
