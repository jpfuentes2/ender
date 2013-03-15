# encoding: utf-8

module Ender
  module Config
    extend self

    EDIT_MODES = [:vi, :emacs]

    Readline.completion_append_character = " "

    def config_file
      File.join Dir.pwd, ".ender"
    end

    def configure(&blk)
      self.instance_eval &blk

      completion_list = %w(on group) + session.groups.keys + session.servers.map(&:host)

      Readline.completion_proc = λ do |str|
        completion_list.grep /^#{Regexp.escape(str)}/
      end
    end

    def default_user(name = nil)
      @default_user = name
    end

    def edit_mode(mode)
      abort "Really? Pick a *real* editing mode! :vi or :emacs" unless mode?(mode)
      Readline.public_send "#{mode}_editing_mode?"
    rescue NotImplementedError
      abort "Readline #{mode} editing mode not supported. Try this: http://bit.ly/WzD1YC"
    end

    def server(options = {})
      user = options.fetch :user, default_user
      host = options.delete :host || abort("Must provide :host for server")
      groups = Array(options.delete(:group)).map &:to_sym

      server = session.use host, options
      session.group groups => server unless groups.empty?
    end

    private

    def mode?(mode)
      EDIT_MODES.include? mode.to_sym
    end

  end
end
