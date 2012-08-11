#!/usr/bin/env ruby
#
# This script converts given migration file into rails scaffold command

output = STDOUT
ARGV.each do |file_name|
  if File.exist? file_name
    File.open(file_name) do |file|
      puts "\nProcessing: #{file.inspect}"

      model_name = nil
      file.each do |line|
        if line =~ /create_table.*:ib_(.*)s.* do \|t\|/
          model_name = Regexp.last_match(1)
          output.print "\nrails generate scaffold #{model_name} "
        end

        if line =~ /t\.(\w*) :(\w*)/
          field, type = Regexp.last_match(2), Regexp.last_match(1)
          if type == 'references'
          	field, type = field + '_id', 'integer'
          end	
          output.print "#{field}:#{type} "
        end
      end
    end
    output.puts
  end
end