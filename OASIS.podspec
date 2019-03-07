#
#  Be sure to run `pod spec lint OASIS.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|
  spec.name         = "OASIS"
  spec.version      = "0.0.1"
  spec.summary      = "A short description of OASIS."
  spec.homepage     = "http://EXAMPLE/OASIS"
  spec.license      = "MIT (example)"
  spec.author       = { "Trevor Beasty" => "trevor.beasty@weightwatchers.com" }
  spec.ios.deployment_target = '10.0'
  s.swift_version   = '4.2'
  spec.source       = { :git => "http://github.com/trevor-beasty/OASIS" }
  spec.source_files = "Classes", "Classes/**/*.{h,m}"
  s.dependency 'RxSwift'
end
