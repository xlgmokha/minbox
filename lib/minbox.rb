# frozen_string_literal: true

require "base64"
require "concurrent"
require "hashie"
require "listen"
require "logger"
require "socket"

require "minbox/client"
require "minbox/inbox"
require "minbox/publisher"
require "minbox/server"
require "minbox/version"

module Minbox
  class Error < StandardError; end

  class << self
    def logger
      @logger ||= Logger.new(STDOUT)
    end

    def logger=(logger)
      @logger = logger
    end
  end
end

