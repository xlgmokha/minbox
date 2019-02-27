require 'redis'

module Minbox
  class Publisher
    attr_reader :publishers

    def initialize(*publishers)
      @publishers = Array(publishers)
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
end
