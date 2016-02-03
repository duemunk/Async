//
//  AsyncGroupTests.swift
//  Async
//
//  Created by Eneko Alonso on 2/2/16.
//  Copyright © 2016 developmunk. All rights reserved.
//

import Foundation
import XCTest

class AsyncGroupTests: XCTestCase {

    // Typical testing time delay. Must be bigger than `timeMargin`
    let timeDelay = 0.3
    // Allowed error for timeDelay
    let timeMargin = 0.2

    func testBackgroundGroup() {
        let expectation = expectationWithDescription("Expected on background queue")
        let group = AsyncGroup()
        group.background {
            XCTAssertEqual(qos_class_self(), QOS_CLASS_BACKGROUND, "On \(qos_class_self().description) (expected \(QOS_CLASS_BACKGROUND.description))")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(timeMargin, handler: nil)
    }

    func testGroupWait() {
        var complete = false
        let group = AsyncGroup()
        group.background {
            XCTAssertEqual(qos_class_self(), QOS_CLASS_BACKGROUND, "On \(qos_class_self().description) (expected \(QOS_CLASS_BACKGROUND.description))")
            complete = true
        }
        group.wait(seconds: timeMargin)
        XCTAssertEqual(complete, true)
    }

    func testMultipleGroups() {
        var count = 0
        let group = AsyncGroup()
        for _ in 1...10 {
            group.background {
                XCTAssertEqual(qos_class_self(), QOS_CLASS_BACKGROUND, "On \(qos_class_self().description) (expected \(QOS_CLASS_BACKGROUND.description))")
                count++
            }
        }
        group.wait(seconds: timeMargin)
        XCTAssertEqual(count, 10)
    }

    func testCustomBlockGroups() {
        var count = 0
        let group = AsyncGroup()
        for _ in 1...10 {
            group.enter()
            Async.background {
                XCTAssertEqual(qos_class_self(), QOS_CLASS_BACKGROUND, "On \(qos_class_self().description) (expected \(QOS_CLASS_BACKGROUND.description))")
                count++
                group.leave()
            }
        }
        group.wait(seconds: timeMargin)
        XCTAssertEqual(count, 10)
    }

    func testNestedAsyncGroups() {
        var count = 0
        let group = AsyncGroup()
        for _ in 1...10 {
            group.background {
                XCTAssertEqual(qos_class_self(), QOS_CLASS_BACKGROUND, "On \(qos_class_self().description) (expected \(QOS_CLASS_BACKGROUND.description))")
                group.enter()
                Async.background {
                    count++
                    group.leave()
                }
            }
        }
        group.wait(seconds: timeMargin)
        XCTAssertEqual(count, 10)
    }

}
