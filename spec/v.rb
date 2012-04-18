puts 'To run specs with (extremely) verbose output, use:'
puts '$ rspec -rv spec'

OPTS ||= {
    :verbose => true, #false, #true, # Verbosity of test outputs
    :brokertron => false, # Do not use mock service (Brokertron)
}
