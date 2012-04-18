desc 'Alias to doc:rdoc'
task :doc => 'doc:rdoc'

namespace :doc do
  require 'rdoc/task'
  Rake::RDocTask.new do |rdoc|
#    Rake::RDocTask.new(:rdoc => "rdoc", :clobber_rdoc => "clobber", :rerdoc => "rerdoc") do |rdoc|
    rdoc.rdoc_dir = DOC_PATH.basename.to_s
    rdoc.title = "#{NAME} #{CLASS_NAME::VERSION} Documentation"
    rdoc.main = "README.doc"
    rdoc.rdoc_files.include('README*')
    rdoc.rdoc_files.include('lib/**/*.rb')
  end
end
