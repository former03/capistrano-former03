module Capistrano
  module Former03
    class Rsync
      def self.build_path(path,type)
        return_path = ""

        if not type.nil?
          user = "#{type.user}@" unless type.user.nil?
          return_path += "#{user}#{type.hostname}:"
        end

        # Ensure path ends with slash
        return_path += path.to_s
        return_path << '/' unless return_path.end_with?('/')

        return_path
      end

      def initialize(opts={})

        # test for required flags
        required_flags = [:src_path, :dest_path]
        required_flags.each do |flag|
          if not opts.has_key?(flag)
            raise "Required arg '#{flag}' not given"
          end
        end

        if not opts[:src_type].nil? and not opts[:dest_type].nil?
          raise "Only one path can be remote"
        end

        # copy opts as instance vars
        opts.each do |k,v|
          instance_variable_set("@#{k}", v)
        end
      end

      def role
        @src_type || @dest_type
      end


      def password
        [role.ssh_options, fetch(:ssh_options)].each do |s|
          begin
            return s[:password]
          rescue
            next
          end
        end
        return nil
      end


      def remote_options
        options = []
        ssh_options = []
        # No remote site
        return [] if role.nil?

        # Handle passsword
        if not password.nil?
          ssh_options += [
            :sshpass,
            '-p',
            "'#{password}'",
            :ssh,
            '-o',
            'PubkeyAuthentication=no',
          ]
        end

        if not role.port.nil?
          ssh_options += ['ssh'] if ssh_options.length == 0
          ssh_options += ['-p', role.port]
        end

        # Add options
        options += ['-e', "\"#{ssh_options.join(' ')}\""] if ssh_options.length > 0

        # Add rsync path if needed
        rsync_path = role.properties.fetch(:deploy_rsync_path)
        if not rsync_path.nil?
          options += ['--rsync-path', rsync_path]
        end

        return options
      end

      def src_path
        return Rsync.build_path(@src_path,@src_type)
      end

      def dest_path
        return Rsync.build_path(@dest_path,@dest_type)
      end

      def command
        if @rsync_path.nil?
          options = [:rsync]
        else 
          options = [@rsync_path]
        end

        # Add options
        options += fetch(:rsync_options)

        # Add remote options if needed
        options += remote_options 

        # Add source and destination
        options += [src_path, dest_path]

        options
      end
    end
  end
end
