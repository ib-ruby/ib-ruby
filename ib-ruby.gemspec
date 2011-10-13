# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ib-ruby/version"

Gem::Specification.new do |s|
  s.name        = "ib-ruby"
  s.version     = Ib::Ruby::VERSION
  s.authors     = ["Ric Pruss"]
  s.email       = ["ricpruss@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{A Ruby interface to the Interactive Brokers' Trader
  Workstation API (http://www.interactivebrokers.com/)}

  s.description = %q{IB-Ruby: Ruby implementation of the Interactive Brokers' TWS API.
  Copyright (C) 2006-2009 Paul Legato By Paul Legato (pjlegato at gmail dot com) sightly updated
  by Ric Pruss in the spirt of the GPL license Paul post the project under .}

  s.rubyforge_project = "ib-ruby"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "getopt"
  
  # s.add_runtime_dependency "rest-client"
end
