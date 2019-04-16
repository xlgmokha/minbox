# frozen_string_literal: true

module Minbox
  class Inbox
    include Enumerable

    def self.instance(root_dir:)
      @instances ||= {}
      @instances[root_dir] ||= new(root_dir: root_dir)
    end

    def initialize(root_dir:)
      start_listening(root_dir)
      empty!
    end

    def emails(count: 0)
      wait_until { |x| x.count >= count } if count > 0
      @emails.values
    end

    def wait_until(seconds: 5, wait: 0.1)
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
          email.subject.match?(subject)
        end
      end
    end

    def empty!
      @emails = {}
    end

    def each
      @emails.each do |id, email|
        yield email
      end
    end

    private

    def changed(modified, added, removed)
      added.each do |file|
        @emails[File.basename(file)] = Mail.read(file)
      end
      removed.each do |file|
        @emails.delete(File.basename(file))
      end
    end

    def listener_for(dir)
      ::Listen.to(File.expand_path(dir), only: /\.eml$/, &method(:changed))
    end

    def start_listening(root_dir)
      listener_for(root_dir).start
    end
  end
end
