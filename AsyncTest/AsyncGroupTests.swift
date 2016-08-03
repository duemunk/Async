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

    func testMainGroup() {
        let expectation = self.expectation(description: "Expected on main queue")
        let group = AsyncGroup()
        group.main {
            XCTAssertEqual(qos_class_self(), qos_class_main())
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeMargin, handler: nil)
    }

    func testUserInteractiveGroup() {
        let expectation = self.expectation(description: "Expected on user interactive queue")
        let group = AsyncGroup()
        group.userInteractive {
            XCTAssertEqual(qos_class_self(), QOS_CLASS_USER_INTERACTIVE)
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeMargin, handler: nil)
    }

    func testUserInitiatedGroup() {
        let expectation = self.expectation(description: "Expected on user initiated queue")
        let group = AsyncGroup()
        group.userInitiated {
            XCTAssertEqual(qos_class_self(), QOS_CLASS_USER_INITIATED)
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeMargin, handler: nil)
    }

    func testUtilityGroup() {
        let expectation = self.expectation(description: "Expected on utility queue")
        let group = AsyncGroup()
        group.utility {
            XCTAssertEqual(qos_class_self(), QOS_CLASS_UTILITY)
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeMargin, handler: nil)
    }

    func testBackgroundGroup() {
        let expectation = self.expectation(description: "Expected on background queue")
        let group = AsyncGroup()
        group.background {
            XCTAssertEqual(qos_class_self(), QOS_CLASS_BACKGROUND)
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeMargin, handler: nil)
    }

    func testGroupWait() {
        var complete = false
        let group = AsyncGroup()
        group.background {
            XCTAssertEqual(qos_class_self(), QOS_CLASS_BACKGROUND)
            complete = true
        }
        group.wait(seconds: timeMargin)
        XCTAssertEqual(complete, true)
    }

    func testMultipleGroups() {
        let count = 10
        let iterations = 0..<count
        let expectations = iterations.map { expectation(description: "\($0)") }
        var counter = 0
        let group = AsyncGroup()
        for i in iterations {
            group.background {
                XCTAssertEqual(qos_class_self(), QOS_CLASS_BACKGROUND)
                expectations[i].fulfill()
                counter += 1
            }
        }
        group.wait(seconds: timeMargin)
        XCTAssertEqual(counter, count)
        waitForExpectations(timeout: timeMargin*2, handler: nil)
    }

    func testCustomBlockGroups() {
        let count = 10
        let iterations = 0..<count
        let expectations = iterations.map { expectation(description: "\($0)") }
        var counter = 0
        let group = AsyncGroup()
        for i in iterations {
            group.enter()
            Async.background {
                XCTAssertEqual(qos_class_self(), QOS_CLASS_BACKGROUND)
                expectations[i].fulfill()
                counter += 1
                group.leave()
            }
        }
        group.wait(seconds: timeMargin)
        XCTAssertEqual(counter, count)
        waitForExpectations(timeout: timeMargin*2, handler: nil)
    }

    func testNestedAsyncGroups() {
        let count = 10
        let iterations = 0..<count
        let expectations = iterations.map { expectation(description: "\($0)") }
        let expectationsNested = iterations.map { expectation(description: "Nested \($0)") }
        var counter = 0
        let group = AsyncGroup()
        for i in iterations {
            group.background {
                XCTAssertEqual(qos_class_self(), QOS_CLASS_BACKGROUND)
                expectations[i].fulfill()
                group.enter()
                Async.background {
                    expectationsNested[i].fulfill()
                    counter += 1
                    group.leave()
                }
            }
        }
        group.wait(seconds: timeMargin)
        XCTAssertEqual(counter, count)
        waitForExpectations(timeout: timeMargin*2, handler: nil)
    }

}
