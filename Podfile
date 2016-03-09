source 'https://github.com/CocoaPods/Specs.git'

platform :ios, "7.0"
#use_frameworks!
#inhibit_all_warnings!

# === for cocoapods befre 1.0 ===
link_with 'patchwork', 'patchworkTests'

# === for cocoapods later than v1.0 ===
#def shared_pods

#
# Internal Pods
#
pod 'ASIHTTPRequest',             :path => './LocalPods/ASIHttPRequest'
#
# vendors' Pods
#

pod 'YYModel'
pod 'FMDB'
pod 'BlocksKit/Core'
#pod 'ASIHTTPRequest/Core'
pod 'Reachability'


#
# Other settings
#


#end
#target 'patchwork' do
#   shared_pods
#end
#
#target 'patchworkTests' do
#    shared_pods
#end

pre_install do
    system("sed -i '' '/UITextField/d' Pods/BlocksKit/BlocksKit/BlocksKit+UIKit.h")
    system('rm -f Pods/BlocksKit/BlocksKit/UIKit/UITextField+BlocksKit.h')
    system('rm -f Pods/BlocksKit/BlocksKit/UIKit/UITextField+BlocksKit.m')
    
    system("sed -i '' '/BKMacros/d' Pods/BlocksKit/BlocksKit/BlocksKit.h")

end