# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name = "ib"
  gem.version = File.open('VERSION').read.strip # = ::Mix::VERSION # - conflicts with Bundler
  gem.summary = "Ruby Implementation of the Interactive Broker' TWS API"
  gem.description = "Ruby Implementation of the Interactive Broker' TWS API"
  gem.authors = ["arvicco"]
  gem.email = "arvitallian@gmail.com"
  gem.homepage = "http://github.com/arvicco/ib-ruby"
  gem.platform = Gem::Platform::RUBY
  gem.date = Time.now.strftime "%Y-%m-%d"

  # Files setup
  versioned = `git ls-files -z`.split("\0")
  gem.files = Dir['{bin,lib,man,spec,features,tasks}/**/*', 'Rakefile', 'README*', 'LICENSE*',
                  'VERSION*', 'CHANGELOG*', 'HISTORY*', 'ROADMAP*', '.gitignore'] & versioned
  gem.executables = (Dir['bin/**/*'] & versioned).map { |file| File.basename(file) }
  gem.test_files = Dir['spec/**/*'] & versioned
  gem.require_paths = ["lib"]

  # RDoc setup
  gem.has_rdoc = true
  gem.rdoc_options.concat %W{--charset UTF-8 --main README.rdoc --title mix}
  gem.extra_rdoc_files = ["LICENSE", "HISTORY", "README.rdoc"]

  # Dependencies
  gem.add_dependency("bundler", [">= 1.0.13"])
  gem.add_development_dependency("rspec", [">= 2.5.0"])

end
