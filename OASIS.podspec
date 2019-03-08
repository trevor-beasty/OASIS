Pod::Spec.new do |spec|
  spec.name         = "OASIS"
  spec.version      = "0.0.1"
  spec.summary      = "A short description of OASIS."
  spec.license      = "Copyright © 2019 Weight Watchers International. All rights reserved."
  spec.author       = { "Trevor Beasty" => "trevor.beasty@weightwatchers.com" }
  spec.ios.deployment_target = '10.0'
  s.swift_version   = '4.2'
  spec.source       = { :git => "http://github.com/trevor-beasty/OASIS" }
  spec.source_files = 'Pod/Classes/**/*'
  s.dependency 'RxSwift'
end
