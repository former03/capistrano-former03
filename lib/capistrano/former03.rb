require 'capistrano/former03/version'
require 'capistrano/former03/deploy_command'
require 'capistrano/former03/symlink'
require 'capistrano/former03/rsync'
require 'capistrano/former03/mysql'
load File.expand_path('../tasks/former03.rake', __FILE__)

module Capistrano
  module Former03
  end
end
