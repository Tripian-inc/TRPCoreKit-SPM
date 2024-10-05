//
//  TRPCoreKitTests.swift
//  TRPCoreKitTests
//
//  Created by Evren Yaşar on 15.11.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import XCTest
@testable import TRPCoreKit

class TRPCoreKitTests: XCTestCase {

    var fakeClass: FakeClassForTest?
    override func setUp() {
        fakeClass = FakeClassForTest()
    }

    override func tearDown() {
    }

    func testExample() {
        let sum = fakeClass!.sum(5, 7)
        XCTAssertEqual(sum, 12)
    }

    func testPerformanceExample() {
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
