# frozen_string_literal: true

module Minbox
  class Inbox
    include Singleton
    include Enumerable

    def initialize(root_dir: 'tmp')
      empty!
      ::Listen.to(File.expand_path(root_dir), only: /\.eml$/) do |modified, added, removed|
        added.each do |file|
          @emails[File.basename(file)] = Mail.read(file)
        end
      end.start
    end

    def emails
      @emails.keys
    end

    def until(seconds: 10, wait: 0.1)
      iterations = (seconds / wait).to_i
      iterations.times do
        return if yield(self)

        sleep wait
      end
      raise "timeout: #{seconds} seconds elapsed."
    end

    def open(id)
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
