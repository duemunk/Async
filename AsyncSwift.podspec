Pod::Spec.new do |s|
  s.name        = "AsyncSwift"
  s.version     = "2.0.0"
  s.summary     = "Syntactic sugar in Swift for asynchronous dispatches in Grand Central Dispatch"
  s.homepage    = "https://github.com/duemunk/Async"
  s.license     = { :type => "MIT" }
  s.authors     = { "Tobias Due Munk" => "tobias@developmunk.dk" }

  s.osx.deployment_target = "10.10"
  s.ios.deployment_target = "8.0"
  s.tvos.deployment_target = "9.0"
  s.watchos.deployment_target = "3.0"
  s.source   = { :git => "https://github.com/duemunk/Async.git", :tag => "2.0.0"}
  s.source_files = "Source/*.swift"
  s.requires_arc = true
  s.module_name = 'Async'
end
