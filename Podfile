source 'https://github.com/CocoaPods/Specs.git'

workspace 'patchwork'
xcodeproj 'patchwork.xcodeproj'
xcodeproj 'patchwork-Demo-OSX/patchwork-Demo-OSX.xcodeproj'

def shared_pods
	pod 'YYModel'
	pod 'FMDB'
	pod 'BlocksKit/Core'
	pod 'ASIHTTPRequest/Core'
	pod 'Reachability'
	pod 'ObjcAssociatedObjectHelpers/Core'
end

target 'patchwork' do
	platform :ios, "7.0"
	shared_pods
	xcodeproj 'patchwork.xcodeproj'
end

target 'patchworkTests' do
	platform :ios, "7.0"
	shared_pods
	xcodeproj 'patchwork.xcodeproj'
end

target 'patchwork-Demo-iOS' do
	platform :ios, "7.0"
	shared_pods
	xcodeproj 'patchwork.xcodeproj'
end

target 'patchwork-Demo-OSX' do
	platform :osx, "10.9"
	shared_pods
	pod 'patchwork-demo', :path => '.'
	xcodeproj 'patchwork-Demo-OSX/patchwork-Demo-OSX.xcodeproj'
end

target 'patchwork-Demo-OSXTests' do
	platform :osx, "10.9"
	shared_pods
	pod 'patchwork-demo', :path => '.'
	xcodeproj 'patchwork-Demo-OSX/patchwork-Demo-OSX.xcodeproj'
end

pre_install do
    #system("sed -i '' '/UITextField/d' Pods/BlocksKit/BlocksKit/BlocksKit+UIKit.h")
    #system('rm -f Pods/BlocksKit/BlocksKit/UIKit/UITextField+BlocksKit.h')
    #system('rm -f Pods/BlocksKit/BlocksKit/UIKit/UITextField+BlocksKit.m')
    
    system("sed -i '' '/BKMacros/d' Pods/BlocksKit/BlocksKit/BlocksKit.h")

end
