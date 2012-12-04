require 'childprocess'
require 'socket'
require "pathname"

module BrowserMob
  module Proxy

    class Server
      attr_reader :port, :host

      def initialize(path, opts = {})
        unless File.exist?(path)
          raise Errno::ENOENT, path
        end

        unless File.executable?(path)
          raise Errno::EACCES, "not executable: #{path}"
        end

        @path = path
        @port = Integer(opts[:port] || 8080)
        @host = String(opts[:host] || "localhost")

        @process = ChildProcess.new(path, "--port", port.to_s)
        @process.io.inherit! if opts[:log]

        if log_pathname = opts[:log_pathname]
          log_pathname = Pathname.new(log_pathname)
          raise ArgumentError unless log_pathname.dirname.exist?

          log_file = log_pathname.open("w")
          @process.io.stdout = log_file
          @process.io.stderr = log_file
        end
      end

      def start
        @process.start
        sleep 0.1 until listening?

        pid = Process.pid
        at_exit { stop if Process.pid == pid }

        self
      end

      def url
        "http://#{host}:#{port}"
      end

      def create_proxy(opts = {})
        Client.from(url, opts)
      end

      def stop
        @process.stop if @process.alive?
      end

      private


      def listening?
        TCPSocket.new("127.0.0.1", port).close
        true
      rescue
        false
      end
    end # Server

  end # Proxy
end # BrowserMob