require 'fileutils'
require_relative '../settings'
module GameMachine
  module Console
    class Build

      attr_reader :command
      def initialize(argv)
        @command = argv.shift || ''
      end

      def java_root
        ENV['JAVA_ROOT']
      end

      def java_lib
        File.join(java_root,'lib')
      end

      def gradlew
        File.join(java_root,'gradlew')
      end

      def build_code
        system("cd #{java_root} && #{gradlew} build")
      end

      def generate_csharp_code
        protogen_path = File.join(ENV['APP_ROOT'],'mono','bin','csharp','protogen_csharp.exe')
        proto_file = File.join(ENV['APP_ROOT'],'config','combined_messages.proto')
        messages_out_path =  Settings.protogen_out_dir
        if File.exists?(messages_out_path)
          messages_out_file =  File.join(messages_out_path,'messages.cs')
        else
          messages_out_file =  File.join(ENV['APP_ROOT'],'messages.cs')
        end
        cmd = "#{protogen_path} -i:#{proto_file} -o:#{messages_out_file}"
        puts "Running #{cmd}"
        system(cmd)
      end

      def generate_java_code
        protogen = GameMachine::Protobuf::Generate.new(ENV['APP_ROOT'])
        protogen.generate
      end

      def generate_code
        generate_java_code
        if Config::CONFIG['target_os'].match(/mswin/)
          generate_csharp_code
        end
      end

      def remove_libs
        FileUtils.rm Dir.glob(File.join(java_lib,'*.jar'))
      end

      def install_libs
        system("cd #{java_root} && #{gradlew} install_libs")
      end

      def run!
        if command == 'code'
          build_code
          remove_libs
          install_libs
        elsif command == 'messages'
          generate_code
        else
          generate_code
          build_code
          remove_libs
          install_libs
        end
      end

    end
  end
end
