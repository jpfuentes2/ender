require "ender"

modes = [:vi, :emacs] # vi > emacs

begin
  mode = modes.shift
  Readline.public_send "#{mode}_editing_mode?"
rescue NotImplementedError
  retry unless modes.empty?
  mode = nil
end

Ender.configure do
  # define our servers here
  server host: "127.0.0.1", group: :lo

  edit_mode mode if mode
end

# Readline prompt will start & block so that nothing after this line is executed.
Ender.prompt

puts "we won't ever reach this code"
