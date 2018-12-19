Gem::Specification.new do |gem|
  gem.name = "ib-ruby"
  gem.version = File.open('VERSION').read.strip
  gem.summary = "Ruby Implementation of the Interactive Brokers TWS API"
  gem.description = "Ruby Implementation of the Interactive Brokers TWS API"
  gem.authors = ["Paul Legato", "arvicco","Hatmut Bischoff"]
  gem.email = ["pjlegato@gmail.com", "arvicco@gmail.com"',topofocus@gmail.com']
  gem.homepage = "https://github.com/ib-ruby"
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
	gem.add_dependency 'activesupport', '>= 5.2'
	gem.add_dependency 'activemodel'
  gem.add_dependency 'ox'
  gem.add_dependency 'bundler', '>= 1.1.16'
  gem.add_development_dependency 'rspec','>=3.6'
end

### last updated on 2018/2/27
