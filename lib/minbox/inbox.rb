# frozen_string_literal: true
require 'listen'
require 'singleton'

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
