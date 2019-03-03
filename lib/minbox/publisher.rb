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
      Thread.new do
        Minbox.logger.debug("Publishing: #{mail.message_id}")
        publishers.each { |x| x.publish(mail) }
      end
    end

    def self.from(outputs)
      publisher = Publisher.new
      outputs.each do |x|
        case x
        when 'stdout'
          publisher.add(LogPublisher.new)
        when 'redis'
          publisher.add(RedisPublisher.new)
        when 'file'
          publisher.add(FilePublisher.new)
        end
      end
      publisher
    end
  end

  class LogPublisher
    def initialize(logger = Minbox.logger)
      @logger = logger
    end

    def publish(mail)
      @logger.debug(mail.to_s)
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
