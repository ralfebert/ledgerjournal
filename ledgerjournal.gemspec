require_relative 'lib/ledgerjournal/version'

Gem::Specification.new do |spec|
  spec.name          = "ledgerjournal"
  spec.version       = Ledger::VERSION
  spec.licenses      = ['MIT']
  spec.authors       = ["Ralf Ebert"]
  spec.email         = ["ralf.ebert@gmail.com"]

  spec.summary       = %q{Library to read and write ledger accounting files.}
  spec.description   = %q{ledgerjournal is a Ruby gem to read and write ledger accounting files.
For parsing, it uses the xml output from ledger. For outputting, it formats the ledger data to String in custom Ruby code.
The ledger binary needs to be installed to parse and pretty-print.}
  spec.homepage      = "https://github.com/ralfebert/ledgerjournal"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ralfebert/ledgerjournal.git"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]
  
  spec.add_dependency 'nokogiri', '~> 1.10'
  spec.add_dependency 'open4', '~> 1.3'
  
end
