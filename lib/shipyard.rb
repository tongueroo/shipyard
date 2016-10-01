lib = File.expand_path("..", __FILE__)
require "#{lib}/shipyard/cache"
require "#{lib}/shipyard/benchmarker"

class Shipyard
  # Tried using require 'facets/class/cattr' but it causes issues with Rails.application.load_tasks
  # https://gist.github.com/tongueroo/b35320d6aaa95dccaf193dab13c2ceb1
  @@project = nil
  def self.project=(name) ; @@project = name ; end
  def self.project ; @@project ; end
  @@server = "shipyard"
  def self.server=(name) ; @@server = name ; end
  def self.server ; @@server ; end

  def self.load_rake_tasks(project)
    Shipyard.project = project
    spec = Gem::Specification.find_by_name 'shipyard'
    load "#{spec.gem_dir}/lib/tasks/shipyard.rake"
  end

  def initialize(local, dockerfile_path="Dockerfile")
    @local = local
    @cache = Cache.new(dockerfile_path)
    @benchmarker = Benchmarker.new
  end

  def build(stage)
    @benchmarker.start
    case stage
    when :cache
      run_build("docker build -t #{@cache.new_name} -f Dockerfile.cache .", publish=true)
      update_dockerfile
    when :deploy
      run_build("docker build -t #{@@project}:deploy .")
    else
      raise "Invalid build image stage: #{stage}"
    end
    @benchmarker.end
    @benchmarker.report
  end

  def run_build(cmd, publish=false)
    if @local
      execute(cmd)
    else
      rsync
      ssh_execute(cmd)
      # push(skip_rsync=true) if publish
    end
  end

  def rsync
    # --numeric-ids               don't map uid/gid values by user/group name
    # --safe-links                ignore symlinks that point outside the tree
    # -a, --archive               recursion and preserve almost everything (-rlptgoD)
    # -x, --one-file-system       don't cross filesystem boundaries
    # -z, --compress              compress file data during the transfer
    # -S, --sparse                handle sparse files efficiently
    # -v, --verbose               verbose
    exclude = %w/.git tmp/
    if File.exist?('.gitignore')
      exclude += File.read('.gitignore').split("\n")
    end
    exclude = exclude.reject {|x| x == "/shared"} # special case
    exclude = exclude.uniq.map{|path| "--exclude='#{path}'"}.join(' ')
    options = "--delete --numeric-ids --safe-links -axzSv #{exclude}"
    src = "./"
    dest = "src/#{@@project}"

    rsync = "rsync #{options} #{src} #{@@server}:#{dest}"
    execute(rsync)
  end

  def update_dockerfile
    @cache.write_new_dockerfile
  end

  def push(skip_rsync=false)
    cmd = "docker push #{@cache.new_name}"
    if @local
      system(cmd)
    else
      rsync unless skip_rsync
      ssh_execute(cmd)
    end
  end

  def execute(command)
    command = "time #{command}"
    puts "==> #{command}".blue
    system(command)
  end

  def ssh_execute(command)
    command = "time #{command}"
    command = %|ssh shipyard "cd ~/src/#{@@project} && #{command}"|
    puts "==> #{command}".green
    system(command)
  end
end
