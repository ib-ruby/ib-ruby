# A sample Guardfile
# More info at https://github.com/guard/guard#readme

#guard :rspec, cmd: "bundle exec rspec -rdb" do
guard :rspec, cmd: "bundle exec rspec -rgw" do
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
  watch(%r{^lib/models/ib/(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^lib/ib/alerts/(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^lib/ib/messages/(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^lib/ib/symbols/(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^lib/ib/order_prototypes/(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
#  watch(%r{^lib/ib/alerts/(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }

  watch(%r{^ib/(.+)\.rb$})  { |m| "spec/ib/#{m[1]}_spec.rb" }
  watch(%r{^gw/(.+)\.rb$})  { |m| "spec/gw/#{m[1]}_spec.rb" }
  watch(%r{^models/(.+)\.rb$})  { |m| "spec/models/#{m[1]}_spec.rb" }
  watch(%r{^spec/support/(.+)\.rb$})                  { "spec" }
end

