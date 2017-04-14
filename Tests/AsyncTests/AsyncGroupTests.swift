//
//  AsyncGroupTests.swift
//  Async
//
//  Created by Eneko Alonso on 2/2/16.
//  Copyright © 2016 developmunk. All rights reserved.
//

import Foundation
import XCTest
import Async

class AsyncGroupTests: XCTestCase {

    // Typical testing time delay. Must be bigger than `timeMargin`
    let timeDelay = 0.3
    // Allowed error for timeDelay
    let timeMargin = 0.2

    func testMainGroup() {
        let expectation = self.expectation(description: "Expected on main queue")
        let group = AsyncGroup()
        group.main {
            #if (arch(i386) || arch(x86_64)) && (os(iOS) || os(tvOS)) // Simulator
                XCTAssert(Thread.isMainThread, "Should be on main thread (simulator)")
            #else
                XCTAssertEqual(qos_class_self(), qos_class_main())
            #endif
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeMargin, handler: nil)
    }

    func testUserInteractiveGroup() {
        let expectation = self.expectation(description: "Expected on user interactive queue")
        let group = AsyncGroup()
        group.userInteractive {
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.userInteractive.rawValue)
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeMargin, handler: nil)
    }

    func testUserInitiatedGroup() {
        let expectation = self.expectation(description: "Expected on user initiated queue")
        let group = AsyncGroup()
        group.userInitiated {
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.userInitiated.rawValue)
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeMargin, handler: nil)
    }

    func testUtilityGroup() {
        let expectation = self.expectation(description: "Expected on utility queue")
        let group = AsyncGroup()
        group.utility {
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.utility.rawValue)
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeMargin, handler: nil)
    }

    func testBackgroundGroup() {
        let expectation = self.expectation(description: "Expected on background queue")
        let group = AsyncGroup()
        group.background {
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.background.rawValue)
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeMargin, handler: nil)
    }

    func testGroupCustomQueueConcurrent() {
        let expectation = self.expectation(description: "Expected custom queue")
        let label = "CustomQueueLabel"
        let customQueue = DispatchQueue(label: label, attributes: [.concurrent])
        let key = DispatchSpecificKey<String>()
        customQueue.setSpecific(key: key, value: label)
        let group = AsyncGroup()
        group.custom(queue: customQueue) {
            XCTAssertEqual(DispatchQueue.getSpecific(key: key), label)
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeMargin, handler: nil)
    }

    func testGroupCustomQueueSerial() {
        let expectation = self.expectation(description: "Expected custom queue")
        let label = "CustomQueueLabel"
        let customQueue = DispatchQueue(label: label, attributes: [])
        let key = DispatchSpecificKey<String>()
        customQueue.setSpecific(key: key, value: label)
        let group = AsyncGroup()
        group.custom(queue: customQueue) {
            XCTAssertEqual(DispatchQueue.getSpecific(key: key), label)
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeMargin, handler: nil)
    }

    func testGroupWait() {
        var id = 0
        let group = AsyncGroup()
        group.background {
            // Some work
            Thread.sleep(forTimeInterval: 0.1)
            id += 1
            XCTAssertEqual(id, 1, "")
        }
        XCTAssertEqual(id, 0, "")

        group.wait()
        id += 1
        XCTAssertEqual(id, 2, "")
    }
    
    func testGroupWaitMax() {
        var id = 0
        let date = Date()
        let upperTimeDelay = timeDelay + timeMargin
        let group = AsyncGroup()
        group.background {
            id += 1
            XCTAssertEqual(id, 1, "The id should be 1") // A
            // Some work that takes longer than we want to wait for
            Thread.sleep(forTimeInterval: self.timeDelay + self.timeMargin)
            id += 1 // C
        }
        XCTAssertEqual(id, 0, "The id should be 0, since block is send to background")
        // Wait
        group.wait(seconds: timeDelay)
        id += 1
        XCTAssertEqual(id, 2, "The id should be 2, since the block has begun running") // B
        let timePassed = Date().timeIntervalSince(date)
        XCTAssert(timePassed < upperTimeDelay, "Shouldn't wait \(upperTimeDelay) seconds before firing")
    }

    func testMultipleGroups() {
        let count = 3
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
        waitForExpectations(timeout: timeMargin, handler: nil)
    }

    func testCustomBlockGroups() {
        let count = 3
        let iterations = 0..<count
        let expectations = iterations.map { expectation(description: "\($0)") }
        var counter = 0
        let group = AsyncGroup()
        for i in iterations {
            group.enter()
            Async.background {
                XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.background.rawValue)
                expectations[i].fulfill()
                counter += 1
                group.leave()
            }
        }
        group.wait(seconds: timeMargin)
        XCTAssertEqual(counter, count)
        waitForExpectations(timeout: timeMargin, handler: nil)
    }

    func testNestedAsyncGroups() {
        let count = 3
        let iterations = 0..<count
        let expectations = iterations.map { expectation(description: "\($0)") }
        let expectationsNested = iterations.map { expectation(description: "Nested \($0)") }
        var counter = 0
        let group = AsyncGroup()
        for i in iterations {
            group.background {
                XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.background.rawValue)
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
        waitForExpectations(timeout: timeMargin, handler: nil)
    }

}
