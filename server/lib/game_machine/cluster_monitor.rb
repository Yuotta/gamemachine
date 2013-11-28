module GameMachine
  class ClusterMonitor < Actor::Base

    def self.cluster_members
      if @cluster_members
        @cluster_members
      else
        @cluster_members = java.util.concurrent.ConcurrentHashMap.new
      end
    end

    def self.remote_members
      if @remote_members
        @remote_members
      else
        @remote_members = java.util.concurrent.ConcurrentHashMap.new
      end
    end
    
    def self.add_cluster_member(address,member)
      cluster_members[address] = member
    end

    def self.remove_cluster_member(address)
      cluster_members.delete(address)
    end

    def self.remove_remote_member(address)
      remote_members.delete(address)
    end

    def self.add_remote_member(address,member)
      remote_members[address] = member
    end

    def preStart
      if getContext.system.name == 'cluster'
        @cluster = JavaLib::Cluster.get(getContext.system)
        app.akka.init_cluster!(@cluster.self_address.to_string)
        @cluster.subscribe(getSelf, JavaLib::ClusterEvent::ClusterDomainEvent.java_class)
      end
      @observers = []
    end

    def notify_observers
      @observers.each {|observer| observer.tell('cluster_update',get_self)}
    end

    def on_receive(message)
      if message.is_a?(String) && message == 'register_observer'
        @observers << sender
      elsif message.is_a?(JavaLib::ClusterEvent::SeenChanged)

      elsif message.is_a?(JavaLib::ClusterEvent::MemberRemoved)
        address = message.member.address.to_string
        app.akka.hashring.remove_bucket(address)
        self.class.remove_cluster_member(address)
        self.class.remove_remote_member(address)

        notify_observers

      elsif message.is_a?(JavaLib::ClusterEvent::MemberUp)
        address = message.member.address.to_string
        self.class.add_cluster_member(address,message.member)
        app.akka.hashring.add_bucket(address)

        unless address == @cluster.self_address.to_string
          self.class.add_remote_member(address,message.member)
        end

        notify_observers

      elsif message.is_a?(JavaLib::ClusterEvent::ClusterMetricsChanged)

      elsif message.is_a?(JavaLib::ClusterEvent::CurrentClusterState)
        message.get_members.each do |member|
          address = member.address.to_string
          self.class.add_cluster_member(address,member)
          app.akka.hashring.add_bucket(address)
          unless address == @cluster.self_address.to_string
            self.class.add_remote_member(address,member)
          end
        end

        notify_observers

      else
        #GameMachine.logger.info("Unrecognized message #{message}")
      end
    end
  end
end

