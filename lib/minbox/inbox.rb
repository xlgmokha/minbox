# frozen_string_literal: true

module Minbox
  class Inbox
    include Enumerable

    def self.instance(root_dir:)
      @instances ||= {}
      @instances[root_dir] ||= new(root_dir: root_dir)
    end

    def initialize(root_dir:)
      empty!
      ::Listen.to(File.expand_path(root_dir), only: /\.eml$/) do |modified, added, removed|
        added.each do |file|
          @emails[File.basename(file)] = Mail.read(file)
        end
        removed.each do |file|
          @emails.delete(File.basename(file))
        end
      end.start
    end

    def emails(count: 0)
      wait_until { |x| x.count >= count } if count > 0

      @emails.keys
    end

    def wait_until(seconds: 5, wait: 0.1)
      iterations = (seconds / wait).to_i
      iterations.times do
        return true if yield(self)
        sleep wait
      end
      false
    end

    def wait_until!(*args, &block)
      raise "timeout: expired. #{args}" unless wait_until(*args, &block)
    end

    def open(id)
      wait_until { @emails[id] }
      @emails[id]
    end

    def empty!
      @emails = {}
    end

    def each
      @emails.each do |id, email|
        yield email
      end
    end
  end
end
