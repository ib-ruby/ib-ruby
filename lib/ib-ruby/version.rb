require 'pathname'

module IB
  VERSION_FILE = Pathname.new(__FILE__).dirname + '../../VERSION' # :nodoc:
  VERSION = VERSION_FILE.exist? ? VERSION_FILE.read.strip : nil
end
