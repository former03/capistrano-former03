require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require_relative 'helpers'

RSpec.configure do |c|
  c.include Helpers
end


shared_context "Capistrano::Former03" do
  require 'capistrano/all'
  require 'capistrano/deploy'
  require 'capistrano/former03'
  before do
  end
end


