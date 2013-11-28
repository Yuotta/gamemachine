require 'trollop'
require 'pry'
module GameMachine
  class Runner

    def self.start(name,cluster,console)
      java_dir = File.join(File.expand_path(Dir.pwd),'java')
      unless File.directory?(java_dir)
        puts "Please run game_machine from your game directory"
        exit 0
      end

      GameMachine.logger.info "Using name #{name}"
      app = GameMachine::Application.create(name,cluster)
      app.start
      if console
        binding.pry
      end
    end

  end
end
