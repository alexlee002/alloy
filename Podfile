source 'https://github.com/CocoaPods/Specs.git'
# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'

workspace 'alloy'

def shared_pods
    #pod 'YYModel'
    pod 'FMDB'
    pod 'BlocksKit/Core'
    pod 'ASIHTTPRequest/Core'
    pod 'Reachability'
    pod 'ObjcAssociatedObjectHelpers/Core'
end

target 'alloy' do
	# Uncomment this line if you're using Swift or would like to use dynamic frameworks
	# use_frameworks!

    project 'alloy.xcodeproj'
	platform :ios, '7.0'
    #platform :osx, '10.10'

	shared_pods

	target 'alloyTests' do
		inherit! :search_paths
		# Pods for testing
	end

end

# target 'alloy-demo-osx' do
# 	project 'Examples/alloy-demo-osx/alloy-demo-osx.xcodeproj'
# 	platform :osx, '10.10'
# 	shared_pods
#     pod 'alloy-demo', :path => '.'
# end


pre_install do
    #system("sed -i '' '/UITextField/d' Pods/BlocksKit/BlocksKit/BlocksKit+UIKit.h")
    #system('rm -f Pods/BlocksKit/BlocksKit/UIKit/UITextField+BlocksKit.h')
    #system('rm -f Pods/BlocksKit/BlocksKit/UIKit/UITextField+BlocksKit.m')

    system("sed -i '' '/BKMacros/d' Pods/BlocksKit/BlocksKit/BlocksKit.h")

end
