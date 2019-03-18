# frozen_string_literal: true

require 'redis'

module Minbox
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
      @redis.publish('minbox', mail.to_s)
    end
  end

  class FilePublisher
    attr_reader :dir

    def initialize(dir = Dir.pwd)
      @dir = File.join(dir, 'tmp')
      FileUtils.mkdir_p(@dir)
    end

    def publish(mail)
      IO.write(File.join(dir, "#{Time.now.to_i}.eml"), mail.to_s)
    end
  end

  class Publisher
    REGISTERED_PUBLISHERS = {
      stdout: LogPublisher,
      redis: RedisPublisher,
      file: FilePublisher,
    }.freeze

    attr_reader :publishers

    def initialize(*publishers)
      @publishers = Array(publishers)
    end

    def add(publisher)
      publishers << publisher
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
        clazz = REGISTERED_PUBLISHERS[x.to_sym]
        publisher.add(clazz.new) if clazz
      end
      publisher
    end
  end
end
