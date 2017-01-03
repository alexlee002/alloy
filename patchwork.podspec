Pod::Spec.new do |s|
  s.name         = "patchwork"
  
  `xcodebuild -project patchwork.xcodeproj -showBuildSettings` =~ /CURRENT_PROJECT_VERSION = ((\d\.)+\d)/
  abort("No version detected") if $1.nil?
  s.version = $1

  s.summary      = "Patchwork is a simple toolkit that makes your iOS / OS X development more easier."
  s.description  = <<-DESC
  Features are going to support:
    * model and json mappings: using YYModel, [supported]
    * model and database mappings: Active-Record, [supported]
    * network layer wrapper: ASIHTTPRequest [supported] and NSURLSession [developing...],
                   DESC
  s.homepage     = "https://github.com/alexlee002/patchwork"

  
  s.license      = { :type => 'Apache License 2.0', :file => 'LICENSE' }
  s.author       = { "Alex Lee" => "alexlee002@hotmail.com" }

  #  When using multiple platforms
  s.ios.deployment_target = "7.0"
  s.osx.deployment_target = "10.9"


  #s.source       = { :git => "https://github.com/alexlee002/patchwork.git", :tag => s.version.to_s }
  s.source        = { :git => "https://github.com/alexlee002/patchwork.git" }
  s.source_files  = "patchwork", "patchwork/**/*.{h,m}"
  #s.exclude_files = "Classes/Exclude"
  s.public_header_files = "patchwork/**/*.h"
  s.private_header_files =  "patchwork/**/*_{p,P}rivate.h"

  s.requires_arc = true
  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  s.dependency  "FMDB",             "~> 2.6"
  s.dependency  "YYModel",          "~> 1.0"
  s.dependency  "BlocksKit/Core",   "~> 2.2"
  s.dependency  "ASIHTTPRequest/Core", "~> 1.8"
  s.dependency  "ObjcAssociatedObjectHelpers/Core", "~> 2.0"
end

