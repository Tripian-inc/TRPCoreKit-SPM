////
////  MapDownloader.swift
////  TRPCoreKit
////
////  Created by Evren Yaşar on 6.08.2018.
////  Copyright © 2018 Tripian Inc. All rights reserved.
////
//
//import Foundation
//import MapboxMaps
////MAPBOX DOWNLOADER ŞU ANDA ÇALIŞMIYOR.
////ÇALIŞMASI İÇİN KODUN İÇİNE MAPVİEW EKLENMESİ GEREKİYOR:
//class MapDownloader :NSObject, MGLMapViewDelegate{
//    let sw = CLLocationCoordinate2D(latitude: 41.047904166862025, longitude: 29.0031128078748)
//    let ne = CLLocationCoordinate2D(latitude: 40.96149750959958, longitude: 28.93873979214061)
//    
//    func startDownload() {
//        self.addObserver()
//        self.startOfflinePackDownload()
//    }
//    
//    private func startOfflinePackDownload() {
//        let bound = MGLCoordinateBounds(sw: sw, ne: ne)
//        let region = MGLTilePyramidOfflineRegion(styleURL: MGLStyle.darkStyleURL,
//                                                 bounds: bound,
//                                                 fromZoomLevel: 10,
//                                                 toZoomLevel: 16)
//        
//        let userInfo = ["name": "IstanbulPactForEvren"]
//        let context = NSKeyedArchiver.archivedData(withRootObject: userInfo)
//        MGLOfflineStorage.shared.addPack(for: region, withContext: context) { (pack, error) in
//            guard error == nil else {
//                Log.e("Error: \(error?.localizedDescription ?? "unknown error")")
//                return
//            }
//            pack!.resume()
//        }
//    }
//    
//    public func addObserver() -> Void {
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(offlinePackProgressDidChange),
//                                               name: NSNotification.Name.MGLOfflinePackProgressChanged,
//                                               object: nil)
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(offlinePackDidReceiveError),
//                                               name: NSNotification.Name.MGLOfflinePackError,
//                                               object: nil)
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(offlinePackDidReceiveMaximumAllowedMapboxTiles),
//                                               name: NSNotification.Name.MGLOfflinePackMaximumMapboxTilesReached,
//                                               object: nil)
//    }
//    
//    @objc func offlinePackProgressDidChange(notification: NSNotification) {
//        
//        if let pack = notification.object as? MGLOfflinePack,
//            let userInfo = NSKeyedUnarchiver.unarchiveObject(with: pack.context) as? [String: String] {
//            let progress = pack.progress
//            // or notification.userInfo![MGLOfflinePackProgressUserInfoKey]!.MGLOfflinePackProgressValue
//            let completedResources = progress.countOfResourcesCompleted
//            let expectedResources = progress.countOfResourcesExpected
//            
//            // Calculate current progress percentage.
//            let progressPercentage = Float(completedResources) / Float(expectedResources)
//            
//            // Setup the progress bar.
//            
//            // If this pack has finished, print its size and resource count.
//            if completedResources == expectedResources {
//                let byteCount = ByteCountFormatter.string(fromByteCount: Int64(pack.progress.countOfBytesCompleted), countStyle: ByteCountFormatter.CountStyle.memory)
//                Log.i("Offline pack “\(userInfo["name"] ?? "unknown")” completed: \(byteCount), \(completedResources) resources")
//            } else {
//                // Otherwise, print download/verification progress.
//                Log.i("Offline pack “\(userInfo["name"] ?? "unknown")” has \(completedResources) of \(expectedResources) resources — \(progressPercentage * 100)%.")
//            }
//        }
//    }
//    
//    @objc func offlinePackDidReceiveError(notification: NSNotification) {
//        if let pack = notification.object as? MGLOfflinePack,
//            let userInfo = NSKeyedUnarchiver.unarchiveObject(with: pack.context) as? [String: String],
//            let error = notification.userInfo?[MGLOfflinePackUserInfoKey.error] as? NSError {
//            Log.i("Offline pack “\(userInfo["name"] ?? "unknown")” received error: \(error.localizedFailureReason ?? "unknown error")")
//        }
//    }
//    
//    @objc func offlinePackDidReceiveMaximumAllowedMapboxTiles(notification: NSNotification) {
//        if let pack = notification.object as? MGLOfflinePack,
//            let userInfo = NSKeyedUnarchiver.unarchiveObject(with: pack.context) as? [String: String],
//            let maximumCount = (notification.userInfo?[MGLOfflinePackUserInfoKey.maximumCount] as AnyObject).uint64Value {
//            Log.i("Offline pack “\(userInfo["name"] ?? "unknown")” reached limit of \(maximumCount) tiles.")
//        }
//    }
//}
//
//
//
//
////Observer
//extension TRPMapView {
//    fileprivate func addObserver() -> Void {
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(offlinePackProgressDidChange),
//                                               name: NSNotification.Name.MGLOfflinePackProgressChanged,
//                                               object: nil)
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(offlinePackDidReceiveError),
//                                               name: NSNotification.Name.MGLOfflinePackError,
//                                               object: nil)
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(offlinePackDidReceiveMaximumAllowedMapboxTiles),
//                                               name: NSNotification.Name.MGLOfflinePackMaximumMapboxTilesReached,
//                                               object: nil)
//    }
//    
//    
//    @objc func offlinePackProgressDidChange(notification: NSNotification) {
//        
//        if let pack = notification.object as? MGLOfflinePack,
//            let userInfo = NSKeyedUnarchiver.unarchiveObject(with: pack.context) as? [String: String] {
//            let progress = pack.progress
//            // or notification.userInfo![MGLOfflinePackProgressUserInfoKey]!.MGLOfflinePackProgressValue
//            let completedResources = progress.countOfResourcesCompleted
//            let expectedResources = progress.countOfResourcesExpected
//            
//            // Calculate current progress percentage.
//            let progressPercentage = Float(completedResources) / Float(expectedResources)
//            
//            // Setup the progress bar.
//            
//            Log.i("Progress Percentage: \(progressPercentage)")
//            
//            // If this pack has finished, print its size and resource count.
//            if completedResources == expectedResources {
//                let byteCount = ByteCountFormatter.string(fromByteCount: Int64(pack.progress.countOfBytesCompleted), countStyle: ByteCountFormatter.CountStyle.memory)
//                Log.i("Offline pack “\(userInfo["name"] ?? "unknown")” completed: \(byteCount), \(completedResources) resources")
//            } else {
//                // Otherwise, print download/verification progress.
//                Log.i("Offline pack “\(userInfo["name"] ?? "unknown")” has \(completedResources) of \(expectedResources) resources — \(progressPercentage * 100)%.")
//            }
//        }
//    }
//    
//    @objc func offlinePackDidReceiveError(notification: NSNotification) {
//        if let pack = notification.object as? MGLOfflinePack,
//            let userInfo = NSKeyedUnarchiver.unarchiveObject(with: pack.context) as? [String: String],
//            let error = notification.userInfo?[MGLOfflinePackUserInfoKey.error] as? NSError {
//            Log.i("Offline pack “\(userInfo["name"] ?? "unknown")” received error: \(error.localizedFailureReason ?? "unknown error")")
//        }
//    }
//    
//    @objc func offlinePackDidReceiveMaximumAllowedMapboxTiles(notification: NSNotification) {
//        if let pack = notification.object as? MGLOfflinePack,
//            let userInfo = NSKeyedUnarchiver.unarchiveObject(with: pack.context) as? [String: String],
//            let maximumCount = (notification.userInfo?[MGLOfflinePackUserInfoKey.maximumCount] as AnyObject).uint64Value {
//            Log.i("Offline pack “\(userInfo["name"] ?? "unknown")” reached limit of \(maximumCount) tiles.")
//        }
//    }
//}
