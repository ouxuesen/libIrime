platform :ios, '8.0'


def shared
    pod 'SVProgressHUD', '~> 1.1.2'
end

target 'iRime' do
    pod 'InAppSettingsKit'
    pod 'GCDWebServer/WebUploader/CocoaLumberjack', '~> 3.3.3'
    pod 'ZipArchive', '~> 1.4.0'
    shared
    pod 'UIlertView+Blocks', '~> 0.9'
    pod 'Reachability', '~> 3.2'
    pod 'AFWebViewController', '~> 1.0'
    pod 'AGEmojiKeyboard', '~> 0.2.0'
end

target 'Keyboard' do
    pod 'ZipArchive', '~> 1.4.0'
    pod 'Masonry', '~> 1.0.1'
    pod 'MJRefresh', '~> 3.1.12'
end

#post_install do |installer|
#    installer.pods_project.targets.each do |target|
#        target.build_configurations.each do |config|
#            config.build_settings['SWIFT_VERSION'] = '3.0'
#        end
#    end
#end

