class Shipyard
  class Benchmarker
    def start
      @start_time = Time.now
    end

    def end
      @end_time = Time.now
    end

    def report
      duration = (@end_time - @start_time).to_i
      seconds = duration % 60
      minutes = duration / 60
      pretty_time = if minutes > 0
                      "#{minutes} minutes and #{seconds} seconds"
                    else
                      "#{seconds} seconds"
                    end
      puts "Total time took: #{pretty_time}".green
    end
  end
end
