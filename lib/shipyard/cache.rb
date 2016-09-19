class Shipyard
  class Cache
    def initialize(dockerfile_path)
      @dockerfile_path = dockerfile_path
    end

    def current_name
      lines = current_dockerfile.split("\n")
      from_line = lines.find {|x| x =~ /^FROM /}
      name = from_line.match(/^FROM (.*)/)[1]
    end

    def current_dockerfile
      @current_dockerfile ||= IO.read(@dockerfile_path)
    end

    def new_dockerfile
      lines = current_dockerfile.split("\n")
      # replace FROM line
      new_lines = lines.map do |line|
                    if line =~ /^FROM /
                      "FROM #{new_name}"
                    else
                      line
                    end
                  end
      new_lines.join("\n")
    end

    def write_new_dockerfile
      IO.write(@dockerfile_path, new_dockerfile)
    end

    def new_name
      "#{current_base_name}-#{random_id}"
    end

    # current name without random_id
    def current_base_name
      md = current_name.match(/(.*)-\d{4}-\d{2}-\d{2}-.{7}/)
      # current_name is base name if no match
      md ? md[1] : current_name
    end

    # random_id is timestap + git sha
    def random_id
      @random_id ||= [Time.now.strftime("%Y-%m-%d"), git_sha].join('-')
    end

    def git_sha
      `git rev-parse HEAD`.strip[0..6]
    rescue
      '' # no-git-sha
    end
  end
end
