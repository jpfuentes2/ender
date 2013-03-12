module Ender
  module Config
    extend self

    Readline.completion_append_character = " "

    def config_file
      File.join Dir.pwd, ".ender"
    end

    def configure(&blk)
      self.instance_eval &blk

      completion_list = %w(on group) + session.groups.keys + session.servers.map(&:host)

      Readline.completion_proc = Proc.new do |str|
        completion_list.grep /^#{Regexp.escape(str)}/
      end

      self
    end

    def default_user(name = nil)
      @default_user = name
    end

    def edit_mode(mode)
      if mode == :vi
        Readline.vi_editing_mode
      elsif mode == :emacs
        Readline.emacs_editing_mode
      else
        abort "Really? Pick a *real* editing mode! :vi or :emacs"
      end
    rescue NotImplementedError
      abort "Readline #{mode} editing mode not supported. Try the advice found here: http://bit.ly/WzD1YC."
    end

    def server(options = {})
      user = options.fetch :user, default_user
      host = options.delete :host || abort("Must provide :host for server")
      groups = Array(options.delete(:group)).map &:to_sym

      server = session.use host, options
      session.group groups => server unless groups.empty?

      nil
    end

  end
end
