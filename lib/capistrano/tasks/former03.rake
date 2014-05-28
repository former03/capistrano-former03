Rake::Task[:'deploy:check'].enhance [:'former03:override_scm']
Rake::Task[:'deploy:updating'].enhance [:'former03:override_scm']
Rake::Task[:'deploy:set_current_revision'].enhance [:'former03:override_scm']
Rake::Task[:'deploy:symlink:release'].enhance [:'former03:override_symlink']
Rake::Task[:'deploy:symlink:linked_dirs'].enhance [:'former03:override_symlink']
Rake::Task[:'deploy:symlink:linked_files'].enhance [:'former03:override_symlink']

namespace :former03 do
  set :rsync_options, [
    '--archive',
    '--delete',
  ]

  set :local_stage, 'tmp/deploy'
  set :remote_stage, 'shared/deploy'
  set :remote_bin, 'shared/deploy_bin'
  set :deploy_rsync_bin, nil
  set :deploy_busybox_bin, false
  set :relative_symlinks, true
  set :current_path_real_dir, false

  set :remote_stage_path, -> {
    Pathname.new(deploy_to).join(fetch(:remote_stage))
  }

  set :remote_bin_path, -> {
    Pathname.new(deploy_to).join(fetch(:remote_bin))
  }

  set :local_stage_path, -> {
    Pathname.pwd.join(fetch(:local_stage))
  }

  desc 'Override scm tasks'
  task :override_scm do
    Rake::Task[:"#{scm}:check"].clear
    Rake::Task.define_task(:"#{scm}:check") do
      invoke :'former03:local:check'
      invoke :'former03:remote:check'
    end

    Rake::Task[:"#{scm}:create_release"].clear
    Rake::Task.define_task(:"#{scm}:create_release") do
      invoke :'former03:remote:release'
    end

    Rake::Task[:"#{scm}:set_current_revision"].clear
    Rake::Task.define_task(:"#{scm}:set_current_revision") do
      invoke :'former03:local:set_current_revision'
    end
  end

  desc 'Override symlink tasks'
  task :override_symlink do
    if fetch(:relative_symlinks)
      #Filter execute with :ln, -s using Capistrano::Former03::Symlink
      SSHKit::Backend::Netssh.send(:define_method, :execute) do |*args|
        _execute(*Capistrano::Former03::Symlink.execute(args)).success?
      end
    end

    # Move release to have a real dir as current path
    if fetch(:current_path_real_dir)
      Rake::Task[:'deploy:symlink:release'].clear
      Rake::Task.define_task(:'deploy:symlink:release') do
        invoke :'former03:remote:release_move'
      end
    end
  end

  namespace :local do
    desc 'Check that the repository is reachable'
    task :check do
      run_locally do
        git_dir = Pathname.new(capture :git, 'rev-parse', '--git-dir')
        if not git_dir.absolute?
          git_dir = Pathname.pwd.join(git_dir)
        end
        set :repo_path, git_dir
      end
    end


    desc 'Create the local staging directory'
    task :mkdir_stage => :check do

      # Get full path of local stage
      set :local_stage_path, Pathname.pwd.join(fetch(:local_stage))

      # if already exits finish task
      next if File.directory? fetch(:local_stage)

      # create directory
      run_locally do
        execute :mkdir, '-p', fetch(:local_stage)
      end
    end

    desc 'Determine current revision'
    task :set_current_revision do
      run_locally do
          # Set current revision
          revision = capture(:git, 'rev-parse', 'HEAD').chomp
          branches = capture(:git, 'show-ref','|', :grep, "^#{revision}",'|',:awk, "'{ print $2 }'").split()
          set :current_revision, revision
          set :branch, branches.join(', ')
      end
    end

    desc 'Stage the repository in a local directory'
    task :stage => :mkdir_stage do

      git_prefix = [:git, '--git-dir', fetch(:repo_path), '--work-tree',fetch(:local_stage_path)]
      git_submodule = [:git, :submodule]

      run_locally do
        # Bugfix for git versions < 1.9
          
        # Check if .gitmodules exist
        if test :test, '-e', '.gitmodules'
          execute(*git_submodule, :init)
          execute(*git_submodule, :sync)
          execute(*git_submodule, :update)
        end

        within fetch(:local_stage) do
          # Ensure correct checkout
          execute(*git_prefix, :reset, '--hard')

          # Cleanup got
          execute(*git_prefix, :clean, '-fxd')

          # Check if .gitmodules exist
          if test :test, '-e', '.gitmodules'
            # check out all submodules
            git_submodule = git_prefix + [:submodule]
            git_submodule_foreach = git_submodule + [:foreach,:git]
            execute(*git_submodule, :init)
            execute(*git_submodule, :sync)
            execute(*git_submodule, :update)

            # cleanup all submodules
            execute(*git_submodule_foreach, :reset, '--hard')
            execute(*git_submodule_foreach, :clean, '-fxd')
          end
        end
      end
    end
  end

  namespace :remote do

    desc 'Check the deployment hosts'
    task :check => [
      :mkdir_stage,
      :check_rsync_binary,
      :check_busybox_binary
    ] do
      # Add :remote_bin_path to PATH if needed
      if fetch(:remote_bin_active)
        set :default_env, {
          path: "#{fetch(:remote_bin_path)}:$PATH"
        }
      end
    end

    desc 'Create a destination on deployment hosts'
    task :mkdir_stage do
      on release_roles :all do
        path = File.join fetch(:deploy_to), fetch(:remote_stage)
        execute :mkdir, '-pv', path
      end
    end

    desc 'Check if bin destnation dir exists'
    task :check_bin_dir do
      on release_roles :all do
        execute :mkdir, '-pv', fetch(:remote_bin_path)
      end
    end

    desc 'Check for rsync binary on deployment hosts'
    task :check_rsync_binary => [:check_bin_dir] do
      deploy_cmd = Capistrano::Former03::DeployCommand.new(
        :command     => 'rsync',
        :deploy_flag => :deploy_rsync_bin,
        :deploy_path => :deploy_rsync_path,
        :install_cmd => nil,
        :install_cmd => nil,
        :test_cmd    => ['--version', '>', '/dev/null'],
        :required    => true,
      )
      on release_roles :all do
        deploy_cmd.deploy(self)
      end
    end

    desc 'Check for busybox binary on deployment hosts'
    task :check_busybox_binary => [:check_bin_dir] do
      deploy_cmd = Capistrano::Former03::DeployCommand.new(
        :command     => 'busybox',
        :deploy_flag => :deploy_busybox_bin,
        :install_cmd => ['--install', '-s', fetch(:remote_bin_path)],
        :test_cmd    => ['--help', '>', '/dev/null'],
        :required    => false,
      )
      on release_roles :all do
        deploy_cmd.deploy(self)
      end
    end

    desc 'Sync to deployment hosts from local'
    task :sync =>  [:check, 'former03:local:stage'] do
      roles(:all).each do |role|
        rsync = Capistrano::Former03::Rsync.new(
          :src_path   => fetch(:local_stage_path),
          :dest_path  => fetch(:remote_stage_path),
          :dest_type  => role,
        )
        run_locally do
          execute(*rsync.command)
        end
      end
    end

    desc 'Copy the code to the releases directory'
    task :release => :sync do
      on release_roles :all do
        rsync = Capistrano::Former03::Rsync.new(
          :rsync_path => fetch(:deploy_rsync_path),
          :src_path   => fetch(:remote_stage_path),
          :dest_path  => release_path,
        )
        execute(*rsync.command)
      end
    end

    desc 'Move release to current instead of symlinking'
    task :release_move do
      on release_roles :all do
        cp = current_path.join('current')
        current_path = cp
        current_version_path = current_path.to_s + ".version"

        current_path_directory = test :test, '-d', current_path
        current_version_exists = test :test, '-f', current_version_path

        # check if current is a dir
        if current_path_directory and current_version_exists
          execute :mv, current_path, releases_path.join("`cat #{current_version_path}`")
        else
          execute :rm, '-rf', current_path
        end

        execute :mv, release_path, current_path
        execute :echo, '-n', File.basename(release_path), '>', current_version_path

      end
    end
  end
end
