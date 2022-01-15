require_relative "lib/wechat_payment/version"

Gem::Specification.new do |spec|
  spec.name        = "wechat_payment"
  spec.version     = WechatPayment::VERSION
  spec.authors     = ["ian"]
  spec.email       = ["ianlynxk@gmail.com"]
  spec.homepage    = "http://dev.com"
  spec.summary     = "Summary of WechatPayment."
  spec.description = "Description of WechatPayment."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "http://dev.com"
  spec.metadata["changelog_uri"] = "http://dev.com/CHANGELOG.md"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  # spec.add_dependency "rails", "~> 6.1.4"
  spec.add_dependency "rails", "~> 7.0.1"
  spec.add_dependency "wx_pay"
  spec.add_dependency 'rexml'
end
