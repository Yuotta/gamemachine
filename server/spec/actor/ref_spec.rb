require 'spec_helper'

module GameMachine
  describe Actor::Ref do

    let(:local_echo) do
      ref = Actor::Builder.new(GameSystems::LocalEcho).with_name('localecho1').test_ref
      ref.underlying_actor
    end

    subject do
      Actor::Ref.new('test')
    end

    describe "#initialize" do
      it "sets the path" do
        Actor::Ref.new('test').path.should == 'test'
      end
    end

    describe "#ask" do
      it "should accept an actor ref" do
        ref = Actor::Ref.new(local_echo.get_self)
        ref.ask('test',1000).should == 'test'
      end

      it "should accept a path" do
        Actor::Builder.new(GameSystems::LocalEcho).with_name('echotest3').start
        ref = GameSystems::LocalEcho.find('echotest3')
        ref.ask('test',1000).should == 'test'
      end
    end

    describe "#tell" do
      it 'sender argument is optional' do
        subject.tell('test').should be_true
      end

      it "should accept a path" do
        Actor::Builder.new(GameSystems::LocalEcho).with_name('echotest4').start
        GameSystems::LocalEcho.should_receive_message('test','echotest4') do
          ref = GameSystems::LocalEcho.find('echotest4')
          ref.tell('test',nil)
        end
      end

    end

    describe "#send_message" do

      it "default should call tell with message and nil sender" do
        subject.should_receive(:tell).with('test',nil)
        subject.send_message('test')
      end

      it "blocking=true should call ask with message and default timeout" do
        subject.should_receive(:ask).with('test',100)
        subject.send_message('test', :blocking => true)
      end

      it "sender option should be passed to tell" do
        subject.should_receive(:tell).with('test','sender')
        subject.send_message('test',:sender => 'sender')
      end

      it "timeout option should be passed to ask" do
        subject.should_receive(:ask).with('test',2)
        subject.send_message('test', :timeout => 2, :blocking => true)
      end

      it "should get returned message" do
        Actor::Builder.new(GameSystems::LocalEcho).with_name('echotest2').start
        ref = GameSystems::LocalEcho.find('echotest2')
        ref.send_message('hi', :blocking => true, :timeout => 1000).should == 'hi'
      end

      it "should return false on timeout" do
        ref = GameSystems::LocalEcho.find('blah')
        ref.send_message('hi', :blocking => true, :timeout => 1).should be_false
      end
    end
  end
end
