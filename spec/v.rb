puts 'To run specs with (extremely) verbose output, use:'
puts '$ rspec -rv spec'

OPTS ||= {
    :verbose => true, #false, #true, # Verbosity of test outputs
    :brokertron => false, # Use mock (Brokertron) instead of paper account
}
