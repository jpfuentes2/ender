require "ender"

Ender.configure do
  # define our servers here
  server host: "127.0.0.1", group: :lo
end

# Readline prompt will start & block so that nothing after this line is executed.
Ender.prompt

puts "we won't ever reach this code"
