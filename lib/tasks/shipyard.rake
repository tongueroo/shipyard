require_relative "../../lib/shipyard"

# docker image stages:
# base -> built -> deploy
#
# Typically workflow
# 1. build the cache image remotely and push to DockerHub
# 2. build the deploy image locally which will pull from the updated cache image on DockerHub
namespace :shipyard do
  namespace :build do
    # LOCAL=1 bundle exec rake shipyard:build:built
    desc "builds the built docker image.  LOCAL=1 to build locally."
    task :cache do
      # defaults to building remotely
      local = ENV['LOCAL'].nil? ? false : ENV['LOCAL'] == '1'
      Shipyard.new(local).build(:cache)
    end

    desc "builds the deploy docker image"
    task :deploy do
      # defaults to building locally
      local = ENV['LOCAL'].nil? ? true : ENV['LOCAL'] == '1'
      Shipyard.new(local).build(:deploy)
    end
  end

  namespace :push do
    desc "pushes the built docker image on the shipyard instance to dockerhub"
    task :cache do
      # defaults to building remotely
      local = ENV['LOCAL'].nil? ? false : ENV['LOCAL'] == '1'
      Shipyard.new(false).push
    end
  end
end
