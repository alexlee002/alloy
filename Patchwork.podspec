Pod::Spec.new do |s|
  s.name         = "Patchwork"
  s.version      = "0.0.1"
  s.summary      = "An easy, simple base foundation for iOS app."
  s.description  = <<-DESC
  An easy, simple base foundation for iOS app.
  Features are going to support:
    * model and json mappings: using YYModel, [supported]
    * model and database mappings: [supported]
    * network layer wrapper: ASIHTTPRequest and NSURLSession, [developing...]
                   DESC
  s.homepage     = "https://github.com/alexlee002/patchwork"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"

  
  s.license      = { :type => 'Apache License 2.0', :file => 'LICENSE' }
  s.author       = { "Alex Lee" => "alexlee002@hotmail.com" }
  # s.social_media_url   = "http://twitter.com/Alex Lee"

  
  # s.platform     = :ios
  # s.platform     = :ios, "5.0"

  #  When using multiple platforms
  s.ios.deployment_target = "7.0"
  s.osx.deployment_target = "10.9"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"


  #s.source       = { :git => "https://github.com/alexlee002/patchwork.git", :tag => s.version.to_s }
  s.source       = { :git => "https://github.com/alexlee002/patchwork.git" :branch => "master"}
  s.source_files  = "patchwork", "patchwork/**/*.{h,m}"
  #s.exclude_files = "Classes/Exclude"

  s.public_header_files = "patchwork/patchwork.h"

  s.requires_arc = true
  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  #s.dependency "JSONKit", "~> 1.4"
  s.dependency  "FMDB",             "~> 2.6"
  s.dependency  "YYModel",          "~> 1.0.1"
  s.dependency  "BlocksKit/Core",   "~> 2.2.5"

end
