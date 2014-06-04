require 'ostruct'
require 'optparse'
require 'logger'
require 'erb'
require 'fileutils'

module Capistrano
  module Former03
    # Install application
    class Install
      @@name = 'f03capinstall'

      def initialize
        @options = {}
        @argv = nil
        @log = Logger.new(STDOUT)
        @log.level = Logger::INFO


      end

      def parse_arguments
        options = OpenStruct.new
        options.stages = ['production','staging','development']
        options.force = false
        options.verbose = false

        opt_parser = OptionParser.new do |opts|
          opts.banner = "Usage: #{@@name} [options]"
          # Boolean switch
          opts.on("-s", "--stages [#{options.stages.join(',')}]", Array, "Specify custom stage names") do |s|
            options.stages = stages
          end

          opts.on("-f", "--force", "Overwrite existing files") do |v|
            options.force = v
          end

          opts.on("-v", "--verbose", "Run verbosely") do |v|
            options.verbose = v
          end
        end

        opt_parser.parse!(@argv)

        @options = options

        if @options.verbose
          @log.level = Logger::DEBUG
        end
      end

      def setup_templates
        template_dir = Pathname.new(File.expand_path("../templates/", __FILE__))
        @log.debug "Search for templates in path '#{template_dir}'"
        @template_deploy_rb = ERB.new template_dir.join('deploy.rb.erb').read
        @template_stage_rb = ERB.new template_dir.join('stage.rb.erb').read
        @template_capfile = ERB.new template_dir.join('Capfile').read
      end

      def generate_files
        pwd = Pathname.pwd
        generate_file pwd.join('Capfile'), @template_capfile
        generate_file pwd.join('config/deploy.rb'), @template_deploy_rb
        @options.stages.each do |stage|
          generate_file pwd.join("config/deploy/#{stage}.rb"), @template_stage_rb, stage
        end
      end

      def generate_file (path,template,stage=nil)
        require 'capistrano/version'

        if not path.dirname.directory?
          @log.debug "create directory '#{path.dirname}"
          FileUtils.mkdir_p path.dirname
        end

        if path.exist?
          if @options.force
            @log.warn "Overwriting file '#{path}'. To overwrite it use flag --force"
            path.delete
          else
            @log.warn "won't overwrite already existing file '#{path}'. To overwrite it use flag --force"
            return
          end
        end

        f=path.open('w')
        f.write(template.result(binding))
        f.close

        @log.info "Wrote file '#{path}'"
      end

      # Main method of application
      def run
        @argv = ARGV.dup

        # Parse arguments
        parse_arguments

        # logging
        @log.debug "#{@@name} is starting with arguments: #{ARGV}"
        @log.debug "Parsed options: #{@options}"

        # setup templates
        setup_templates

        # generate the actual files
        generate_files

      end
    end
  end
end
