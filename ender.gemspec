$LOAD_PATH.push File.expand_path '../lib', __FILE__

require 'ender/version'

Gem::Specification.new do |s|
  s.name        = "ender"
  s.version     = Ender::VERSION
  s.authors     = ["Jacques Fuentes"]
  s.email       = ["jpfuentes2@gmail.com"]
  s.homepage    = "http://github.com/jpfuentes2/ender"
  s.license     = "MIT"
  s.summary     = "Multi-server SSH prompt"
  s.description = "Execute commands against a multitude of remote servers via a local SSH prompt"
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2")

  s.files = Dir[
    "LICENSE",
    "README.md",
    "lib/**/*.rb",
    "*.gemspec",
    "test/*.*"
  ]

  s.executables << "ender"
  s.require_paths = %w{lib}

  s.add_dependency "net-ssh-multi", "~> 1.0"
  s.add_dependency "clap", "~> 1.0"
end
