# Shipyard

This gem provides tasks which helps build a "cache" docker image layer.  In order to use this you'll need to have both `Dockerfile` and `Dockerfile.cache` files at the root of your project.  

The shipyard task `rake shipyard:build:cache` will use the `Dockerfile.cache` file to build a docker image and updated the FROM line in the `Dockerfile` with this newly generated docker image.

For example, let's say that `Dockerfile` has this FROM line:

```
FROM tongueroo/ruby:cache-2016-09-19-abcdefg
```

The new generated file might be:

```
FROM tongueroo/ruby:cache-2016-09-19-bcdefgh
```

The name is in the form: 

```
FROM [project-name]:cache-[date]-[git-sha]
```

## Why do this?

Having one Dockerfile and docker image is the standard way of building docker images.  However, for my use case, it was easier to build a cache image once in a while and have most of the dependencies cached in that cached image.  This also speeds up deployment on a newly provision server as a docker pull is faster than building the dependencies in that case.  Then the delta is built as part of the deploy.

This cache docker image will inevitablely get slow as the delta between it and the final docker image grows.  Whenver that happens this task provides a relatively quick way to update the docker cache image.

Dynamically generating the FROM docker image name using the git sha allows different base images to be use in long running feature branches also.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'shipyard'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install shipyard

Add it to your Rakefile.  You'll need to pass the docker image name as part of the `load_rake_tasks` method.  

Rakefile Example 1:

```ruby
Shipyard.load_rake_tasks("tongueroo/ruby")
```

Rakefile Example 2:

```ruby
Shipyard.load_rake_tasks("tongueroo/elixir")
```

## Usage

```bash
$ bundle exec rake -T shipyard
rake shipyard:build:cache   # builds the built docker image
rake shipyard:build:deploy  # builds the deploy docker image
rake shipyard:push:cache    # pushes the built docker image on the shipyard instance to dockerhub
$ 
```

The main task that I use is: `rake shipyard:build:cache`

To test building docker images locallly:

```
LOCAL=1 rake shipyard:build:cache
```

But normally the docker cache image gets build remotely on a server that you will need to set up so that it can run basically `docker build` commands.

To build docker images remotely:

```
rake shipyard:build:cache
```

By default a "shipyard" server is used and the code that you have locally is rsynced onto the shipyard server.  This can be configured in your `~/.ssh/config`.

You can also override this via `Shipyard.server`.  Example:

```ruby
Shipyard.server = "my.custom.server.com"
Shipyard.load_rake_tasks("my/dockerimage")
```
