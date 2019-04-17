# frozen_string_literal: true

module Minbox
  class Inbox
    include Enumerable

    def self.instance(root_dir:)
      @instances ||= {}
      @instances[root_dir] ||= new(root_dir: root_dir)
    end

    def initialize(root_dir:)
      @semaphore = Mutex.new
      start_listening(root_dir)
      empty!
    end

    def emails(count: 0)
      wait_until { |x| x.count >= count } if count > 0
      with_lock do |emails|
        emails.values
      end
    end

    def wait_until(seconds: 10, wait: 0.1)
      iterations = (seconds / wait).to_i
      iterations.times do
        result = yield(self)
        return result if result

        sleep wait
      end
      nil
    end

    def wait_until!(*args, &block)
      raise "timeout: expired. #{args}" unless wait_until(*args, &block)
    end

    def open(subject:)
      wait_until do
        emails.find do |email|
          subject.is_a?(String) ? email.subject == subject : email.subject.match?(subject)
        end
      end
    end

    def empty!
      with_lock do
        @emails = {}
      end
    end

    def each
      @emails.each do |id, email|
        yield email
      end
    end

    private

    def changed(modified, added, removed)
      with_lock do |emails|
        added.each do |file|
          mail = Mail.read(file)
          Minbox.logger.debug("Received: #{mail.subject}")
          emails[File.basename(file)] = mail
        end
        removed.each do |file|
          emails.delete(File.basename(file))
        end
      end
    end

    def listener_for(dir)
      ::Listen.to(File.expand_path(dir), only: /\.eml$/, &method(:changed))
    end

    def start_listening(root_dir)
      listener_for(root_dir).start
    end

    def with_lock
      @semaphore.synchronize do
        yield @emails if block_given?
      end
    end
  end
end
