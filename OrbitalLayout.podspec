Pod::Spec.new do |s|
  s.name         = 'OrbitalLayout'
  s.version      = '1.0.0'
  s.summary      = 'Lightweight Auto Layout constraint library for Swift.'
  s.homepage     = 'https://github.com/dimayurkovski/OrbitalLayout'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Dima Yurkovski' => 'dima.yurkovski@gmail.com' }
  s.source       = { :git => 'https://github.com/dimayurkovski/OrbitalLayout.git', :tag => s.version.to_s }

  s.swift_versions = ['5.10', '6']

  s.ios.deployment_target     = '15.0'
  s.osx.deployment_target     = '12.0'
  s.tvos.deployment_target    = '15.0'

  s.source_files = 'Sources/**/*.{swift}'
  s.resource_bundles = { 'OrbitalLayout' => ['Sources/PrivacyInfo.xcprivacy'] }
end
