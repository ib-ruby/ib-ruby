# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name = "ib-ruby"
  gem.version = File.open('VERSION').read.strip
  gem.summary = "Ruby Implementation of the Interactive Brokers TWS API"
  gem.description = "Ruby Implementation of the Interactive Brokers TWS API"
  gem.authors = ["Paul Legato", "arvicco"]
  gem.email = ["pjlegato@gmail.com", "arvicco@gmail.com"]
  gem.homepage = "https://github.com/pjlegato/ib-ruby"
  gem.platform = Gem::Platform::RUBY
  gem.date = Time.now.strftime "%Y-%m-%d"

  # Files setup
  versioned = `git ls-files -z`.split("\0")
  gem.files = Dir['{app,config,db,bin,lib,man,spec,features,tasks}/**/*',
                  'Rakefile', 'README*', 'LICENSE*',
                  'VERSION*', 'HISTORY*', '.gitignore'] & versioned
  gem.executables = (Dir['bin/**/*'] & versioned).map { |file| File.basename(file) }
  gem.test_files = Dir['spec/**/*'] & versioned
  gem.require_paths = ['lib']

  # Dependencies
  gem.add_dependency 'bundler', '>= 1.1.3'
  gem.add_dependency 'activerecord', '~> 3.2.0'
  #gem.add_dependency 'activerecord-jdbcsqlite3-adapter', '>= 1.2.2'
  #gem.add_dependency 'jdbc-sqlite3', '>= 3.7.2'
  gem.add_dependency 'xml-simple', '>= 1.1.1'
  gem.add_dependency 'standalone_migrations'
  #gem.add_dependency 'pg', '>= 0.12.1'

  gem.add_development_dependency 'database_cleaner', '>= 0.7.2'
  gem.add_development_dependency 'rspec', '>= 2.10.0'
  gem.add_development_dependency 'standalone_migrations'
  gem.add_development_dependency 'my_scripts'
  gem.add_development_dependency 'rails', '~> 3.2.3'
  gem.add_development_dependency 'rspec-rails', '~> 2.10.1'
  gem.add_development_dependency 'capybara'
  gem.add_development_dependency 'combustion'
  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'pry-doc'
  gem.add_development_dependency 'pry-rails'
end
