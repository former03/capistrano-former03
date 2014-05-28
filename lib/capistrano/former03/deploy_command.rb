module Capistrano
  module Former03
    class DeployCommand

      def initialize(opts={})

        # test for required flags
        required_flags = [:command, :deploy_flag ,:test_cmd, :required]
        required_flags.each do |flag|
          if not opts.has_key?(flag)
            raise "Required arg '#{flag}' not given"
          end
        end

        # copy opts as instance vars
        opts.each do |k,v|
          instance_variable_set("@#{k}", v)
        end
      end

      def dest_path
        File.join(fetch(:remote_bin_path), @command)
      end

      def dest_src(arch='x64')
        File.expand_path(File.join(
          File.expand_path(File.dirname(__FILE__)),
          "../../../share/#{@command}/#{@command}_#{arch}"
        ))
      end

      def test_run_path
        @ssh.test(@command, *@test_cmd)
      end

      def test_run_absolute
        @ssh.test(dest_path, *@test_cmd)
      end

      def upload(src)
        @ssh.upload! src, dest_path
        @ssh.execute :chmod, '+x', dest_path
        if test_run_absolute
          if not @install_cmd.nil?
            if @ssh.test(dest_path, *@install_cmd)
              return true
            else
              return false
            end
          else
            return true
          end
        else
          return false
        end
      end

      def add_env_path
        #TODO do host local env setting
        env = SSHKit.config.default_env
        bin_path = fetch(:remote_bin_path).to_s
        if env.has_key? (:path)
          split = env[:path].split(':')
          if not split.include?(bin_path)
           split = [bin_path] + split
          end
          env[:path] = split.join(':')
        else
          env[:path] = "#{bin_path}:$PATH"
        end
      end


      def deploy_succeed
        add_env_path
        @ssh.host.properties.set "deploy_#{@command.to_sym}_path".to_sym, dest_path
        return true
      end

      def deploy_run
        # Deploy own binary if it doesn't already exist
        return deploy_succeed if test_run_absolute

        # Upload x64 binary
        upload(dest_src('x64'))
        return deploy_succeed if test_run_absolute

        # Upload x32 binary
        upload(dest_src('x32'))
        return deploy_succeed if test_run_absolute

        # Fail if arrive here
        fail_missing

      end

      def fail_missing
        fail "No usable '#{@command}' command found"
      end


      def deploy(ssh)

        # receive ssh handle
        @ssh = ssh
        @deploy = fetch(@deploy_flag)
        # deploy states
        if @deploy == true
          return deploy_run
        elsif @deploy.nil?
          if test_run_path
            return false
          else
            return deploy_run
          end
        else
          if @required
            if test_run_path
              return false
            else
              fail_missing
            end
          else
            return false
          end
        end

      end
    end
  end
end
