Pod::Spec.new do |s|
    s.name = "TRPCoreKit"
    s.version = "1.8.0"
    s.summary = "Tripian iOS Framework"
    s.homepage = "https://www.tripian.com"
    s.license =  s.license = { :type => "BSD" }
    s.author = { "Tripian" => "necati@tripian.com" }
    s.source       = {
        :http => "https://tripian-mobile-sdk.s3.us-east-2.amazonaws.com/trpcorekit/1.8.0/TRPCoreKit.zip"
      }
    s.module_name = "TRPCoreKit"
    s.exclude_files = "Classes/Exclude"
    s.ios.deployment_target = "11.0"
    s.platform = :ios, "11.0"
    s.vendored_frameworks = "TRPCoreKit/TRPCoreKit.framework"
    s.swift_version = '5.1'
    s.frameworks = "TRPCoreKit"
    s.dependency 'TRPFoundationKit', '1.5.0'
    s.dependency 'TRPUserProfileKit', '1.4.4'
    s.dependency 'TRPAddTravelCompanionsKit', '1.4.4'
    s.dependency 'TRPUIKit', '1.4.0'
    s.dependency 'TRPRestKit', '1.4.4'
    s.dependency 'Parchment'
    s.dependency 'Mapbox-iOS-SDK', '5.6'
    s.dependency 'MapboxDirections.swift', '~> 0.30'
    s.dependency 'SDWebImage', '~> 5.0'
    s.requires_arc = true
end
    
