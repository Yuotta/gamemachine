require_relative 'commands/message_helper'
require_relative 'commands/datastore_commands'
require_relative 'commands/chat_commands'
require_relative 'commands/player_commands'
require_relative 'commands/grid_commands'
require_relative 'commands/proxy'
require_relative 'commands/base'

if Config::CONFIG['target_os'] == 'linux'
  require_relative 'commands/navigation_commands'
end

module GameMachine
  module Commands

    def commands
      @commands ||= Base.new
    end

  end
end

