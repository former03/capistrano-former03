require 'tempfile'

module Capistrano
  module Former03
    class Namespace
      def initialize(hash)
        hash.each do |key, value|
          singleton_class.send(:define_method, key) { value }
        end 
      end

      def get_binding
        binding
      end
    end
    
    class MySQL
      def initialize
      end

      def task
        if @task.nil?
          fail "No object handle"
        end
        @task
      end

      def sync(t)
        @task = t
        src_stage = :production
        dst_stage = fetch(:stage)

        if src_stage == dst_stage
          fail "Source stage (#{src_stage}) is equal to destination stage (#{dst_stage})"
        end

        src_database = config(src_stage)[:database]
        dst_database = config(dst_stage)[:database]
        src_cnf = mysql_cnf_upload(:src, src_stage)
        dst_cnf = mysql_cnf_upload(:dst, dst_stage)

        @task.on release_roles :all do

          # remove all tables on dest
          tables = capture "mysql --defaults-file=#{dst_cnf} -e'SHOW TABLES;' #{dst_database}"
          tables = tables.split
          if tables.length > 1
            tables = tables[1..-1].map{|name| "`#{name}`"}.join(',')
            execute "mysql --defaults-file=#{dst_cnf} -e'DROP TABLES #{tables};' #{dst_database}"
          end

          # sync production to stage
          execute "mysqldump --defaults-file=#{src_cnf} #{src_database} | mysql --defaults-file=#{dst_cnf} #{dst_database}"

          # remove credentials
          execute "rm #{src_cnf}"
          execute "rm #{dst_cnf}"
        end
      end

      def config(stage=nil)
        @config ||= task.fetch(:mysql_connections)
        stage ||= task.fetch(:stage)
        @config[stage]
      end


      def deploy_to
        @task.fetch(:deploy_to)
      end

      def cnf_path(name)
        File.join(deploy_to, 'shared', ".my.cnf_#{name}")
      end

      def mysql_cnf_upload(name, stage=nil)
        dest = cnf_path(name)
        src = Tempfile.new('my.cnf')
        src.write(mysql_cnf(stage))
        src.flush
        @task.on release_roles :all do
          upload!(src.path, dest)
          execute "chmod 600 #{dest}"
        end

        # remove tempfile
        src.delete

        dest
      end

      def mysql_cnf(stage=nil)
        c=config(stage)
        output = "[client]\n"
        output +="user=#{c[:username]}\n" if c.has_key?(:username)
        output +="password=#{c[:password]}\n" if c.has_key?(:password)
        output +="host=#{c[:host]}\n" if c.has_key?(:host)
        output +="port=#{c[:port]}\n" if c.has_key?(:port)
      end

      def backup(t)
        @task = t
        cnf = mysql_cnf_upload(:backup)
        database = config[:database]
        # run backup
        @task.on release_roles :all do
          begin
            output_dir = capture "readlink -e #{File.join(deploy_to, 'current')}"
          rescue
            output_dir = File.join(deploy_to, 'releases/00000000000000')
          end

          # test for backup dir
          execute "test -d \"#{output_dir}\" || mkdir -p \"#{output_dir}\""

          # backup mysqldb
          output = File.join(output_dir, 'mysql.sql.gz')
          execute "mysqldump --defaults-file=#{cnf} #{database} | gzip > #{output}"
          execute "chmod 600 #{output}"

          # remove credentials
          execute "rm #{cnf}"
        end
      end
      
      def templates(t)
        @task = t
        fetch(:mysql_templates, []).each do |c|

          dest = File.join(fetch(:local_stage_path), c[:destination])

          puts("Evaluting template '#{c[:template]}' to '#{dest}'")

          # Read template
          erb = ERB.new(
            File.read(c[:template]),
            nil,
            '-',
          )

          File.open(dest, 'w') do |file|
            namespace = Namespace.new({
              config: config(),
              stage: fetch(:stage),
            })
            file.write(erb.result(namespace.get_binding)) 
          end
          File.exist?(c[:destination])
        end
      end
    end
  end
end
