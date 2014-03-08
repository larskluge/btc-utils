$:.push File.expand_path('../lib', __FILE__)
require 'btc-utils/version'

Gem::Specification.new do |s|
  s.name        = 'btc-utils'
  s.version     = BtcUtils::VERSION
  s.date        = '2014-03-06'
  s.summary     = 'Bitcoin utilities'
  s.description = 'A library of handy Bitcoin utilities. Currently some models to interact easily with bitcoind RPC interface.'
  s.authors     = ['Lars Kluge']
  s.email       = 'l@larskluge.com'
  s.homepage    = 'https://github.com/larskluge/btc-utils'
  s.license     = 'MIT'

  s.files       = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")

  s.add_dependency 'bitcoin-client'
  s.add_dependency 'activesupport'

  s.add_development_dependency 'rspec'
end

