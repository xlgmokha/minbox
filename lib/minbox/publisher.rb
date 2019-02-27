require 'redis'

module Minbox
  class Publisher
    attr_reader :publishers

    def initialize(*publishers)
      @publishers = Array(publishers)
    end

    def add(publisher)
      publishers.push(publisher)
    end

    def publish(mail)
      publishers.each { |x| x.publish(mail) }
    end
  end

  class LogPublisher
    def initialize(logger = STDOUT)
      @logger = logger
    end

    def publish(mail)
      @logger.puts mail.to_s
    end
  end

  class RedisPublisher
    def initialize(redis = Redis.new)
      @redis = redis
    end

    def publish(mail)
      @redis.publish("minbox", mail.to_s)
    end
  end

  class FilePublisher
    attr_reader :dir

    def initialize(dir = Dir.pwd)
      @dir = File.join(dir, "tmp")
      FileUtils.mkdir_p(@dir)
    end

    def publish(mail)
      IO.write(File.join(dir, "#{Time.now.to_i}.eml"), mail.to_s)
    end
  end
end
