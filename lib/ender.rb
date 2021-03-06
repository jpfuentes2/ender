# encoding: utf-8

require "net/ssh/multi"
require "readline"
require "ender/config"
require "ender/version"

$stdout.sync = true

alias :λ :lambda # let's have fun when coding

module Ender
  include Config
  extend self

  INTRO = "Welcome, Ender, to your command center.
Type exit if you wish to surrender.
".freeze

  def cli(options = {})
    cfg = options.fetch :config_file, self.config_file
    abort "Config file: #{cfg} not found!" unless File.exists? cfg
    configure { eval File.read(cfg) }
    prompt
  end

  def prompt
    Signal.trap :SIGINT, method(:at_exit)
    Signal.trap :SIGTERM, method(:at_exit)
    Signal.trap :SIGQUIT, method(:at_exit)
    at_exit { abort "Ender out..."; session.close; exit }

    puts INTRO
    start_prompt
  end

  private

  def execute(buffer, hosts, sub_session)
    cmd = buffer.sub FILTERED_HOST_REGEX, ""
    puts "Executing '#{cmd}' on #{hosts.join(",")}"
    sub_session.exec cmd
    session.loop
  end

  def session
    @session ||= Net::SSH::Multi.start
  end

  def start_prompt
    while buffer = Readline.readline("> ", true)
      abort if buffer.nil? || buffer =~ /^(quit|exit)/

      sub_session, hosts = filter *parse_options(buffer)
      next if hosts.empty?

      execute buffer, hosts, sub_session
    end
  end

  FILTERED_HOST_REGEX = /^(group|on)\s([a-zA-Z0-9_\.,]*)\s/

  def parse_options(buffer)
    options = buffer.scan(FILTERED_HOST_REGEX).to_a.flatten

    if options.empty?
      [nil, nil]
    else
      targets = options.last.split ","
      filter = options.first.to_sym
      [filter, targets]
    end
  end

  def filter(type, targets)
    sub_session = case type
    when :group then group(targets)
    when :on then cherry_pick(targets)
    else session
    end

    [sub_session, sub_session.servers.map(&:host)]
  end

  def group(targets)
    sess = session.with *targets.map(&:to_sym)
    puts "No servers found for group(s): #{targets.join(",")}" if sess.servers.empty?
    sess
  end

  def cherry_pick(targets)
    servers = session.servers.select { |s| targets.include? s.host }
    puts "Servers #{targets.join(",")} have not been configured." if servers.empty?
    session.on *servers
  end
end
