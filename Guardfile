# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard :rspec, cmd: "bundle exec rspec" do
  require "ostruct"

  # Generic Ruby apps
  rspec = OpenStruct.new
  rspec.spec = ->(m) { "spec/#{m}_spec.rb" }
  rspec.spec_dir = "spec"
  rspec.spec_helper = "spec/spec_helper.rb"

#  watch(%r{^spec/.+_spec\.rb$})
#  watch(%r{^lib/(.+)\.rb$})     { |m| rspec.spec.("lib/#{m[1]}") }
#  watch(rspec.spec_helper)      { rspec.spec_dir }
#

  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }

  watch(%r{^models/(.+)\.rb$})  { |m| "spec/models/#{m[1]}_spec.rb" }
  watch(%r{^spec/support/(.+)\.rb$})                  { "spec" }
end

