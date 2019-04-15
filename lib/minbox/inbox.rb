# frozen_string_literal: true

module Minbox
  class Inbox
    include Enumerable
    attr_reader :root_dir

    def initialize(root_dir: 'tmp')
      @root_dir = Pathname.new(root_dir)
    end

    def emails
      map { |x| File.basename(x) }
    end

    def open(id)
      file = find { |x| x.end_with?(id) }
      file ? Mail.read(file) : nil
    end

    def empty!
      each do |email|
        File.unlink(email)
      rescue StandardError
        nil
      end
    end

    def each
      Dir[root_dir.join("*.eml")].sort_by { |x| File.mtime(x) }.each do |email|
        yield email
      end
    end
  end
end
