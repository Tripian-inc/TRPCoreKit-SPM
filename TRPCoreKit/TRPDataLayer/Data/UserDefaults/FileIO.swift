//
//  FileIO.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 19.12.2021.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import Foundation
import SwiftUI
public class FileIO {
    
     public static let shared = FileIO()
    
    private(set) var fileManager = FileManager.default
    private(set) var documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    
    
    public init() {}
    
     public func write<T: Encodable>(_ file: T,
                             _ docName: String,
                             _ directory: FileManager.SearchPathDirectory = .documentDirectory) throws {
        if let fileURL = getCruiseFile(docName) {
            let data = try JSONEncoder().encode(file)
            try data.write(to: fileURL, options: .atomicWrite)
        }else {
            print("[Error] File Not ")
        }
    }
    
     public func read<T: Decodable>(_ file: T.Type,
                                   _ docName: String,
                                   _ useRoute: Bool = false) throws -> T {
        var fileURL:URL?
        if useRoute {
            fileURL = documentsDirectory?.appendingPathComponent("\(docName).json")
        }else {
            fileURL = getCruiseFile(docName)
        }
        
        let jsonData = try Data(contentsOf: fileURL!, options: .mappedIfSafe)
        let encode = try JSONDecoder().decode(file.self, from: jsonData)
        return encode
    }
    
     public func getData(_ docName: String) throws -> Data {
        let fileURL = getCruiseFile(docName)
        let data = try Data(contentsOf: fileURL!, options: .mappedIfSafe)
        return data
    }
   
     public func getCruiseFile(_ fileName: String) -> URL?{
        let filePath = "\(CruiseDataHolderUseCase.shared.cruiseId)" + "/" + "\(fileName)" + ".json"
        return documentsDirectory?.appendingPathComponent(filePath)
    }
    
}

//MARK: - FOLDER MANAGER
extension FileIO {
    
    func createFolder(_ name: String,
                      directory: FileManager.SearchPathDirectory = .applicationDirectory,
                      domainMask: FileManager.SearchPathDomainMask = .userDomainMask) throws {
        let folderUrl = try folderUrl(name, directory, domainMask)
        try fileManager.createDirectory(at: folderUrl, withIntermediateDirectories: false, attributes: nil)
    }
    
    func folderUrl(_ name: String,
                   _ directory: FileManager.SearchPathDirectory = .applicationDirectory,
                   _ domainMask: FileManager.SearchPathDomainMask = .userDomainMask) throws -> URL{
        let rootFolderUrl = try fileManager.url(for: directory, in: domainMask, appropriateFor: nil, create: false)
        return rootFolderUrl.appendingPathComponent(name)
    }
    
    func getBundleUrl(name: String) -> URL? {
        
        if let path = Bundle(identifier: "com.tripian.demoapp")?.path(forResource: name, ofType: "json") {
            return URL(fileURLWithPath: path)
        }else {
            print("[Offline] Dosya bulunamadı")
        }
        return nil
    }
}

public class CruiseDataHolderUseCase {
     public static var shared = CruiseDataHolderUseCase()
    
    public var cruiseId: Int = 0
    public var cityId: Int?
}
