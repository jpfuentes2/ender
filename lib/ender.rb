require "net/ssh/multi"
require "readline"
require "ender/config"

$stdout.sync = true

module Ender
  include Config
  extend self

  INTRO = "Welcome, Ender, to your command center.
Type exit if you wish to surrender.
".freeze

  def cli(options = {})
    config_file = options.fetch :config_file, self.config_file
    proc = Proc.new { eval File.read(config_file), proc.binding }
    configure &proc

    prompt
  end

  def prompt
    exit = -> { puts "exit"; exit }
    Signal.trap :SIGINT, &exit
    Signal.trap :SIGTERM, &exit
    Signal.trap :SIGQUIT, &exit
    at_exit { shutdown! }

    puts INTRO
    start_prompt
  end

  private

  def session
    @session ||= Net::SSH::Multi.start
  end

  def start_prompt
    while buffer = Readline.readline("> ", true)
      abort if buffer.nil? || buffer == "exit" || buffer == "quit"

      sub_session, hosts = filter *parse_options(buffer)
      next if hosts.empty?

      cmd = buffer.sub FILTERED_HOST_REGEX, ""
      puts "Executing '#{cmd}' on #{hosts.join(",")}"

      sub_session.exec cmd
      session.loop
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
    ss = session.with *targets.map(&:to_sym)
    puts "No servers found for group(s): #{targets.join(",")}" if ss.servers.empty?
    ss
  end

  def cherry_pick(targets)
    servers = session.servers.select { |s| targets.include?(s.host) }
    puts "Servers #{targets.join(",")} have not been configured." if servers.empty?
    session.on *servers
  end

  def shutdown!
    puts "Ender out..."
    session.close
  end
end
