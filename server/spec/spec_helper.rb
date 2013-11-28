
ENV['GAME_ENV'] = 'test'
require 'rubygems'

begin
  require 'game_machine'
rescue LoadError
  require_relative '../lib/game_machine'
end

RSpec.configure do |config|
  config.before(:suite) do
    GameMachine::Application.create('default',true)
  end

  config.before(:each) do
    app = GameMachine::Application.instance_for('default')
    app.load_game_data
    app.start_actor_system
    app.start_core_systems
    app.start_handlers
    app.start_game_systems
    GameMachine::GameLoader.new.load_all
  end

  config.after(:each) do
    app = GameMachine::Application.instance_for('default')
    app.stop_actor_system
  end

  config.after(:suite) do
    puts "after suite"
  end
end

begin
  require_relative 'message_expectations'
rescue LoadError
end
