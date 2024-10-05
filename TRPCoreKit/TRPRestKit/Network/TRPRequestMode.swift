//
//  TRPRequestMode.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 2.05.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation

/// A type representing a HTTP Request Mode values.
///
/// - get: Get
/// - post: Post
/// - put: Put
/// - delete: Delete
public enum TRPRequestMode: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}
