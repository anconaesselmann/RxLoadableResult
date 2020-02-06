# Be sure to run `pod lib lint RxLoadableResult.podspec' to ensure this is a

Pod::Spec.new do |s|
  s.name             = 'RxLoadableResult'
  s.version          = '0.1.3'
  s.summary          = 'Rx extension for LoadableResult'
  s.swift_version    = '5.0'

  s.description      = <<-DESC
Rx extension for LoadableResult.
                       DESC

  s.homepage         = 'https://github.com/anconaesselmann/RxLoadableResult'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ancona-esselmann' => 'axel@anconaesselmann.com' }
  s.source           = { :git => 'https://github.com/anconaesselmann/RxLoadableResult.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'

  s.source_files = 'RxLoadableResult/Classes/**/*'

  s.dependency 'RxSwift'
  s.dependency 'RxOptional'
  s.dependency 'RxCocoa'
  s.dependency 'LoadableResult'
end
