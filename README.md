# Tripian Core Kit

Tripian Core Kit framework is created by the [Tripian Software Team](https://www.tripian.com/about-us/) which includes all the operations of Tripian APIs in view controllers with core functionalities. Such as creating trip, getting daily plan list, performing user management, viewing or editing user's upcoming & past trips, etc.

Tripian Core Kit pairs well with Tripian Rest Kit SDK for iOS.

Tripian Core Kit framework is written in Swift.

- [Features](#features)
- [Documentation](#documentation)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Provide your own Appearance Settings in TRPCoreKit](#provide-your-own-appearance-settings-in-tRPCoreKit)
- [Use Cases](#use-cases)
- [Examples](#examples)
- [Communication](#communication)
- [License](#license)

## Features

The key features are:

* Digital Itinerary Planner
* Location Based Recommendations
* Navigation With No Limits
* Additional Travelers
* Plan Around Meetings
* Detailed documentation is available in the [TRPCoreKit Documentation](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#tripian-recommendation-engine).

## Documentation

See the [TRPCoreKit documentation](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#tripian-recommendation-engine) for usage examples.

## Requirements

Tripian Core Kit is compatible with applications written in Swift 5 in Xcode 10.2 and above. Tripian Core Kit runs on iOS 11.0 and above.

Tripian Core Kit SDK is also available [for Android](https://github.com/tripian/trpCoreKitAndroid/).

## Installation

### Using CocoaPods

To install TRP Core Kit using [CocoaPods](https://cocoapods.org/):

1. Create a [Podfile](https://guides.cocoapods.org/syntax/podfile.html) with the following specification:
   ```ruby
   # Add the pods for any other Tripian products you want to use in your app
   # For example, to use TRPCoreKit
   pod 'TRPCoreKit'
   ```
   The platform specified in your Podfile should be `:iOS '11'`

1. Run `pod repo update && pod install` and open the resulting Xcode workspace.

Note that if you're using one of the quickstart samples, the Xcode project and Podfile (with pods) are already present, but you'll still need to install the pods.


## Usage

* Tripian APIs require a Tripian account and API access token.

   * TRPCoreKit uses [TRPRestKit framework](https://github.com/tripian/trpRestKitIOS/) to handle networking implementations of Tripian Rest API. 
   *  in `AppDelegate`:
   
       ```swift
       
       ```
   * Then, set the access token with calling the TRPClient.start() in your app's `application:didFinishLaunchingWithOptions:` method:
   
      ```swift
      let environment: Environment = .production // Enumaration value that can be production,test,sandbox, production or a custom BaseUrlCreater instance.
      let trpApiKey = "YOUR_API_KEY" // Tripian access token.
      TRPClient.start(enviroment: environment, apiKey: trpApiKey) // Set TRPRestKit access token in order TRPCoreKit to work properly.
      ```
   * You can obtain an access token from the [Tripian Recommendation API Page](https://www.tripian.com/travel-recommendation-api/).

* Tripian uses Mapbox to show customized maps. 

   * You need a Mapbox access token to use any of Mapbox's tools in TRPCoreKit. 
   * In the project editor, select the application target, then go to the Info tab. Under the “Property List Key” section, set `MGLMapboxAccessToken` to your mapbox access token.

* Tripian uses Google Places autocomplete results in searching places. 

   * To get rich details for millions of places in TRPCoreKit, Google Places provides autocomplete results for user queries.
   * In the project editor, select the application target, then go to the Info tab. Under the “Property List Key” section, set `TRPGooglePlaceApi` to your Google Places API Key.

* Adding LocationWhenInUseUsage Description: 

   * The TRPCoreKit SDK accesses location information only when running in the foreground, and requires location permission to work properly. Under the “Property List Key” section, set `Privacy - Location When In Use Usage Description` to a message that tells the user why the app is requesting access to the user’s location information while the app is running in the foreground.

* Adding Image Assets:

   * The TRPCoreKit uses asset catalog in the app. [TRPCoreKit-Annotation-Images](https://TRPCoreKit-Annotation-Images/) contains all the versions of annotation images that support various devices and scale factors. You can add annotation images to your app by dragging them to the asset catalog named Assets.xcassets. 

**TRPCoreKit uses MVVM-C iOS app architecture pattern** which is a combination of the Model-View-ViewModel architecture, plus the Coordinator pattern to manage all the screen navigations. 
`TRPSDKCoordinater` responsibility is to handle navigation flow in TRPCoreKit: the same way that UINavigationController keeps reference of its stack, `TRPSDKCoordinater` do the same with its children. You will need `TRPSDKCoordinator` to start TRPCoreKit navigation flow.

Now import the `TRPCoreKit` module and present a new UINavigationController instance. 

```swift
import TRPCoreKit
```
Then, create coordinator instance and call `start` method to show TRPCoreKit in your app.

```swift
let nav = UINavigationController() // TRPSDKCoordinater requires navigation controller instance in initialization.
nav.modalPresentationStyle = .fullScreen // Modally presented view controller to display in full-screen.
self.present(nav, animated: true, completion: nil)// Present Navigation View Controller instance in your app.
let coordinator = TRPSDKCoordinater(navigationController: nav) // Create coordinator instance.
coordinator.delegate = self // Set coordinator's delegate to track the functionality that has been delegated. 
coordinator.start()// Call `start` method to show the TRPCoreKit in your app.
```

## Provide your own Appearance Settings in TRPCoreKit

Although TRPCoreKit provides default appearance settings, applications may want different settings. 
`TRPAppearanceSettings` gives you a collection of variables  that lets you access to the appearance proxy for TRPCoreKit. You can customize the appearance of instances of a class by sending appearance modification details to the class’s appearance proxy.

To customize the appearance of all instances of a class, use `TRPAppearanceSettings` to get the appearance proxy for the class.

For example, to modify the bar background tint color for all instances of Paging View's top bar size, change `TRPAppearanceSettings.PaginView.menuItemSize`.

```swift
let menuItemSize: CGSize = 60
TRPAppearanceSettings.PaginView.menuItemSize = menuItemSize
```

To reach Search Places Page's title use `TRPAppearanceSettings.SearchPlaces.Title`.

```swift
TRPAppearanceSettings.SearchPlaces.title = "Search Places"
```


Consult the [TRPCoreKit Documentation](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#tripian-recommendation-engine) for further details.

## Use Cases
//UML DIAGRAMS

## Examples

The [TRPCoreKit-IOS-Examples](https://github/trpcorekitiosexamples) includes example code for accomplishing starting a navigation flow of TRPCoreKit and modifying common appearance feautures in Tripian Core Kit:

1. Clone the repository or download the [.zip file](https://github.com/tripian/trpcorekit-ios/archive/master.zip)
1. Run `pod repo update && pod install` and open the resulting Xcode workspace.
1. Open `TrpCoreKitIOSExample.xcodeproj`.
1. Sign up or log in to your Tripian account and grab a [Tripian Access Token](https://www.tripian.com/request-api-key/).
1. Set the access token with calling the TRPClient.start() in your app's `application:didFinishLaunchingWithOptions:` method:
   ```swift
   let environment: Environment = .production // Enumaration value that can be production,test,sandbox, production or a custom BaseUrlCreater instance.
   let trpApiKey = "YOUR_API_KEY" // Tripian access token.
   TRPClient.start(enviroment: environment, apiKey: trpApiKey) // Set TRPRestKit access token in order TRPCoreKit to work properly.
     ```
1. Build and run the `Example` target.

## Communication
- If you **need help with TRPCore Kit**, use [Stack Overflow](https://stackoverflow.com/questions/tagged/trpcorekit) and tag `trpcorekit`.
- If you need to **find or understand the Tripian Recommendation Engine API**, check [our documentation](http://airmiles-api-1837638174.ca-central-1.elb.amazonaws.com/apidocs/#tripian-recommendation-engine).
- If you **found a bug**, open an issue here on GitHub and follow the guide. The more detail the better!

## Built With

All below frameworks are created by the [Tripian Software Team](https://www.tripian.com/about-us/).

* [TRPRestKit](https://rest/kit/linki) - to focus specifically on networking implementations of Tripian Rest API.

* [TRPUIKit](https://foundation/kit/linki) - to provide ui components that are used in TRPCoreKit.

* [TRPUserProfileKit](https://foundation/kit/linki) - to organize user profile operations in TRPCoreKit.

* [TRPAddTravelCompanionsKit](https://foundation/kit/linki) - to obtain and modify travel companions in TRPCoreKit.

* [TRPFoundationKit](https://foundation/kit/linki) - to provide primitive classes and introduce several paradigms that makes developing with TRPCoreKit more easier by introducing consistent conventions.

This library also uses version 5.6.0 of the Mapbox-iOS-SDK API, 4.2.1 of the Polyline, 5.5.0 of the SDWebImage by default.

## License

//LICENSE
