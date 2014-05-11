module Capistrano
  module Former03
    module Symlink
      def self.execute(args)
        begin
          if args[0] == :ln and args[1] = '-s'
            return [
              :ln,
              '-s',
              self.relative_source(args[2], args[3]),
              args[3]
            ]
          else
            return args
          end
        rescue IOError
          return args
        end
      end

      def self.relative_source(source,destination)
        # Ensure pathname objects
        if not source.instance_of?(Pathname)
          source = Pathname.new source
        end
        if not destination.instance_of?(Pathname)
          destination = Pathname.new destination
        end

        return source.relative_path_from(destination.dirname)

      end
    end
  end
end
