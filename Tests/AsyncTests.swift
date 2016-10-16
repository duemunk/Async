//
//  AsyncExample_iOSTests.swift
//  AsyncExample iOSTests
//
//  Created by Tobias DM on 15/07/14.
//  Copyright (c) 2014 Tobias Due Munk. All rights reserved.
//

import Foundation
import XCTest
import Async


extension qos_class_t: CustomDebugStringConvertible {
    public var debugDescription: String {
        return description
    }
}


class AsyncTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // Typical testing time delay. Must be bigger than `timeMargin`
    let timeDelay = 0.3
    // Allowed error for timeDelay
    let timeMargin = 0.2

    /* GCD */

    func testGCD() {
        let expectation = self.expectation(description: "Expected after time")

        let qos: DispatchQoS.QoSClass = .background
        let queue = DispatchQueue.global(qos: qos)
        queue.async {
            XCTAssertEqual(qos_class_self(), qos.rawValue)
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeMargin, handler: nil)
    }


    /* dispatch_async() */

    func testAsyncMain() {
        let expectation = self.expectation(description: "Expected on main queue")
        var calledStuffAfterSinceAsync = false
        Async.main {
            #if (arch(i386) || arch(x86_64)) && (os(iOS) || os(tvOS)) // Simulator
                XCTAssert(Thread.isMainThread, "Should be on main thread (simulator)")
            #else
                XCTAssertEqual(qos_class_self(), qos_class_main())
            #endif
            XCTAssert(calledStuffAfterSinceAsync, "Should be async")
            expectation.fulfill()
            
        }
        calledStuffAfterSinceAsync = true
        waitForExpectations(timeout: timeMargin, handler: nil)
    }

    func testAsyncUserInteractive() {
        let expectation = self.expectation(description: "Expected on user interactive queue")
        Async.userInteractive {
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.userInteractive.rawValue)
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeMargin, handler: nil)
    }

    func testAsyncUserInitiated() {
        let expectation = self.expectation(description: "Expected on user initiated queue")
        Async.userInitiated {
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.userInitiated.rawValue)
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeMargin, handler: nil)
    }

    func testAsyncUtility() {
        let expectation = self.expectation(description: "Expected on utility queue")
        Async.utility {
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.utility.rawValue)
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeMargin, handler: nil)
    }

    func testAsyncBackground() {
        let expectation = self.expectation(description: "Expected on background queue")
        Async.background {
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.background.rawValue)
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeMargin, handler: nil)
    }

    func testAsyncCustomQueueConcurrent() {
        let expectation = self.expectation(description: "Expected custom queue")
        let label = "CustomQueueLabel"
        let customQueue = DispatchQueue(label: label, attributes: [.concurrent])
        let key = DispatchSpecificKey<String>()
        customQueue.setSpecific(key: key, value: label)
        Async.custom(queue: customQueue) {
            XCTAssertEqual(DispatchQueue.getSpecific(key: key), label)
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeMargin, handler: nil)
    }

    func testAsyncCustomQueueSerial() {
        let expectation = self.expectation(description: "Expected custom queue")
        let label = "CustomQueueLabel"
        let customQueue = DispatchQueue(label: label, attributes: [])
        let key = DispatchSpecificKey<String>()
        customQueue.setSpecific(key: key, value: label)
        Async.custom(queue: customQueue) {
            XCTAssertEqual(DispatchQueue.getSpecific(key: key), label)
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeMargin, handler: nil)
    }


    /* Chaining */

    func testAsyncBackgroundToMain() {
        let expectation = self.expectation(description: "Expected on background to main queue")
        var wasInBackground = false
        Async.background {
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.background.rawValue)
            wasInBackground = true
        }.main {
            #if (arch(i386) || arch(x86_64)) && (os(iOS) || os(tvOS)) // Simulator
                XCTAssert(Thread.isMainThread, "Should be on main thread (simulator)")
            #else
                XCTAssertEqual(qos_class_self(), qos_class_main())
            #endif
            XCTAssert(wasInBackground, "Was in background first")
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeMargin*2, handler: nil)
    }

    func testChaining() {
        let expectation = self.expectation(description: "Expected On \(qos_class_self()) (expected \(DispatchQoS.QoSClass.userInitiated.rawValue))")
        var id = 0
        Async.main {
            #if (arch(i386) || arch(x86_64)) && (os(iOS) || os(tvOS)) // Simulator
                XCTAssert(Thread.isMainThread, "Should be on main thread (simulator)")
            #else
                XCTAssertEqual(qos_class_self(), qos_class_main())
            #endif
            id += 1
            XCTAssertEqual(id, 1, "Count main queue")
        }.userInteractive {
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.userInteractive.rawValue)
            id += 1
            XCTAssertEqual(id, 2, "Count user interactive queue")
        }.userInitiated {
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.userInitiated.rawValue)
            id += 1
            XCTAssertEqual(id, 3, "Count user initiated queue")
        }.utility {
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.utility.rawValue)
            id += 1
            XCTAssertEqual(id, 4, "Count utility queue")
        }.background {
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.background.rawValue)
            id += 1
            XCTAssertEqual(id, 5, "Count background queue")
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeMargin*5, handler: nil)
    }

    func testAsyncCustomQueueChaining() {
        let expectation = self.expectation(description: "Expected custom queues")
        var id = 0
        let customQueue = DispatchQueue(label: "CustomQueueLabel", attributes: [.concurrent])
        let otherCustomQueue = DispatchQueue(label: "OtherCustomQueueLabel", attributes: [])
        Async.custom(queue: customQueue) {
            id += 1
            XCTAssertEqual(id, 1, "Count custom queue")
        }.custom(queue: otherCustomQueue) {
            id += 1
            XCTAssertEqual(id, 2, "Count other custom queue")
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeMargin*2, handler: nil)
    }


    /* dispatch_after() */

    func testAfterGCD() {

        let expectation = self.expectation(description: "Expected after time")
        let date = Date()
        let lowerTimeDelay = timeDelay - timeMargin
        let time = DispatchTime.now() + timeDelay
        let qos = DispatchQoS.QoSClass.background
        let queue = DispatchQueue.global(qos: qos)
        queue.asyncAfter(deadline: time) {
            let timePassed = Date().timeIntervalSince(date)
            XCTAssert(timePassed >= lowerTimeDelay, "Should wait \(timePassed) >= \(lowerTimeDelay) seconds before firing")
            XCTAssertEqual(qos_class_self(), qos.rawValue)
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeDelay + timeMargin, handler: nil)
    }

    func testAfterMain() {
        let expectation = self.expectation(description: "Expected after time")
        let date = Date()
        let lowerTimeDelay = timeDelay - timeMargin
        Async.main(after: timeDelay) {
            let timePassed = Date().timeIntervalSince(date)
            XCTAssert(timePassed >= lowerTimeDelay, "Should wait \(timePassed) >= \(lowerTimeDelay) seconds before firing")
            #if (arch(i386) || arch(x86_64)) && (os(iOS) || os(tvOS)) // Simulator
                XCTAssert(Thread.isMainThread, "Should be on main thread (simulator)")
            #else
                XCTAssertEqual(qos_class_self(), qos_class_main())
            #endif
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeDelay + timeMargin, handler: nil)
    }

    func testAfterUserInteractive() {
        let expectation = self.expectation(description: "Expected after time")
        let date = Date()
        let lowerTimeDelay = timeDelay - timeMargin
        Async.userInteractive(after: timeDelay) {
            let timePassed = Date().timeIntervalSince(date)
            XCTAssert(timePassed >= lowerTimeDelay, "Should wait \(timePassed) >= \(lowerTimeDelay) seconds before firing")
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.userInteractive.rawValue)
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeDelay + timeMargin, handler: nil)
    }

    func testAfterUserInitated() {
        let expectation = self.expectation(description: "Expected after time")
        let date = Date()
        let lowerTimeDelay = timeDelay - timeMargin
        Async.userInitiated(after: timeDelay) {
            let timePassed = Date().timeIntervalSince(date)
            XCTAssert(timePassed >= lowerTimeDelay, "Should wait \(timePassed) >= \(lowerTimeDelay) seconds before firing")
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.userInitiated.rawValue)
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeDelay + timeMargin, handler: nil)
    }

    func testAfterUtility() {
        let expectation = self.expectation(description: "Expected after time")
        let date = Date()
        let lowerTimeDelay = timeDelay - timeMargin
        Async.utility(after: timeDelay) {
            let timePassed = Date().timeIntervalSince(date)
            XCTAssert(timePassed >= lowerTimeDelay, "Should wait \(timePassed) >= \(lowerTimeDelay) seconds before firing")
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.utility.rawValue)
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeDelay + timeMargin, handler: nil)
    }

    func testAfterBackground() {
        let expectation = self.expectation(description: "Expected after time")
        let date = Date()
        let lowerTimeDelay = timeDelay - timeMargin
        Async.background(after: timeDelay) {
            let timePassed = Date().timeIntervalSince(date)
            XCTAssert(timePassed >= lowerTimeDelay, "Should wait \(timePassed) >= \(lowerTimeDelay) seconds before firing")
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.background.rawValue)
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeDelay + timeMargin, handler: nil)
    }

    func testAfterCustomQueue() {
        let expectation = self.expectation(description: "Expected after time")
        let date = Date()
        let timeDelay = 1.0
        let lowerTimeDelay = timeDelay - timeMargin
        let label = "CustomQueueLabel"
        let customQueue = DispatchQueue(label: label, attributes: [.concurrent])
        let key = DispatchSpecificKey<String>()
        customQueue.setSpecific(key: key, value: label)
        Async.custom(queue: customQueue, after: timeDelay) {
            let timePassed = Date().timeIntervalSince(date)
            XCTAssert(timePassed >= lowerTimeDelay, "Should wait \(timePassed) >= \(lowerTimeDelay) seconds before firing")
            XCTAssertEqual(DispatchQueue.getSpecific(key: key), label)
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeDelay + timeMargin, handler: nil)
    }

    func testAfterChainedMix() {
        let expectation = self.expectation(description: "Expected after time")
        let date1 = Date()
        var date2 = Date()
        let timeDelay1 = timeDelay
        let lowerTimeDelay1 = timeDelay1 - timeMargin
        let upperTimeDelay1 = timeDelay1 + timeMargin
        let timeDelay2 = timeDelay
        let lowerTimeDelay2 = timeDelay2 - timeMargin
        var id = 0
        Async.userInteractive(after: timeDelay1) {
            id += 1
            XCTAssertEqual(id, 1, "First after")

            let timePassed = Date().timeIntervalSince(date1)
            XCTAssert(timePassed >= lowerTimeDelay1, "Should wait \(timePassed) >= \(lowerTimeDelay1) seconds before firing")
            XCTAssert(timePassed < upperTimeDelay1, "Shouldn't wait \(timePassed), but <\(upperTimeDelay1) seconds before firing")
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.userInteractive.rawValue)

            date2 = Date() // Update
        }.utility(after: timeDelay2) {
            id += 1
            XCTAssertEqual(id, 2, "Second after")

            let timePassed = Date().timeIntervalSince(date2)
            XCTAssert(timePassed >= lowerTimeDelay2, "Should wait \(timePassed) >= \(lowerTimeDelay2) seconds before firing")
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.utility.rawValue)
            expectation.fulfill()
        }
        waitForExpectations(timeout: (timeDelay1 + timeDelay2) + timeMargin*2, handler: nil)
    }

    func testAfterChainedUserInteractive() {
        let expectation = self.expectation(description: "Expected after time")
        let date1 = Date()
        var date2 = Date()
        let timeDelay1 = timeDelay
        let lowerTimeDelay1 = timeDelay1 - timeMargin
        let upperTimeDelay1 = timeDelay1 + timeMargin
        let timeDelay2 = timeDelay
        let lowerTimeDelay2 = timeDelay2 - timeMargin
        var id = 0
        Async.userInteractive(after: timeDelay1) {
            id += 1
            XCTAssertEqual(id, 1, "First after")

            let timePassed = Date().timeIntervalSince(date1)
            XCTAssert(timePassed >= lowerTimeDelay1, "Should wait \(timePassed) >= \(lowerTimeDelay1) seconds before firing")
            XCTAssert(timePassed < upperTimeDelay1, "Shouldn't wait \(timePassed), but <\(upperTimeDelay1) seconds before firing")
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.userInteractive.rawValue)

            date2 = Date() // Update
        }.userInteractive(after: timeDelay2) {
            id += 1
            XCTAssertEqual(id, 2, "Second after")

            let timePassed = Date().timeIntervalSince(date2)
            XCTAssert(timePassed >= lowerTimeDelay2, "Should wait \(timePassed) >= \(lowerTimeDelay2) seconds before firing")
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.userInteractive.rawValue)
            expectation.fulfill()
        }
        waitForExpectations(timeout: (timeDelay1 + timeDelay2) + timeMargin*2, handler: nil)
    }

    func testAfterChainedUserInitiated() {
        let expectation = self.expectation(description: "Expected after time")
        let date1 = Date()
        var date2 = Date()
        let timeDelay1 = timeDelay
        let lowerTimeDelay1 = timeDelay1 - timeMargin
        let upperTimeDelay1 = timeDelay1 + timeMargin
        let timeDelay2 = timeDelay
        let lowerTimeDelay2 = timeDelay2 - timeMargin
        var id = 0
        Async.userInitiated(after: timeDelay1) {
            id += 1
            XCTAssertEqual(id, 1, "First after")

            let timePassed = Date().timeIntervalSince(date1)
            XCTAssert(timePassed >= lowerTimeDelay1, "Should wait \(timePassed) >= \(lowerTimeDelay1) seconds before firing")
            XCTAssert(timePassed < upperTimeDelay1, "Shouldn't wait \(timePassed), but <\(upperTimeDelay1) seconds before firing")
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.userInitiated.rawValue)

            date2 = Date() // Update
        }.userInitiated(after: timeDelay2) {
            id += 1
            XCTAssertEqual(id, 2, "Second after")

            let timePassed = Date().timeIntervalSince(date2)
            XCTAssert(timePassed >= lowerTimeDelay2, "Should wait \(timePassed) >= \(lowerTimeDelay2) seconds before firing")
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.userInitiated.rawValue)
            expectation.fulfill()
        }
        waitForExpectations(timeout: (timeDelay1 + timeDelay2) + timeMargin*2, handler: nil)
    }

    func testAfterChainedUtility() {
        let expectation = self.expectation(description: "Expected after time")
        let date1 = Date()
        var date2 = Date()
        let timeDelay1 = timeDelay
        let lowerTimeDelay1 = timeDelay1 - timeMargin
        let upperTimeDelay1 = timeDelay1 + timeMargin
        let timeDelay2 = timeDelay
        let lowerTimeDelay2 = timeDelay2 - timeMargin
        var id = 0
        Async.utility(after: timeDelay1) {
            id += 1
            XCTAssertEqual(id, 1, "First after")

            let timePassed = Date().timeIntervalSince(date1)
            XCTAssert(timePassed >= lowerTimeDelay1, "Should wait \(timePassed)>=\(lowerTimeDelay1) seconds before firing")
            XCTAssert(timePassed < upperTimeDelay1, "Shouldn't wait \(timePassed), but <\(upperTimeDelay1) seconds before firing")
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.utility.rawValue)

            date2 = Date() // Update
        }.utility(after: timeDelay2) {
            id += 1
            XCTAssertEqual(id, 2, "Second after")

            let timePassed = Date().timeIntervalSince(date2)
            XCTAssert(timePassed >= lowerTimeDelay2, "Should wait \(timePassed) >= \(lowerTimeDelay2) seconds before firing")
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.utility.rawValue)
            expectation.fulfill()
        }
        waitForExpectations(timeout: (timeDelay1 + timeDelay2) * 2, handler: nil)
    }

    func testAfterChainedBackground() {
        let expectation = self.expectation(description: "Expected after time")
        let date1 = Date()
        var date2 = Date()
        let timeDelay1 = timeDelay
        let lowerTimeDelay1 = timeDelay1 - timeMargin
        let upperTimeDelay1 = timeDelay1 + timeMargin
        let timeDelay2 = timeDelay
        let lowerTimeDelay2 = timeDelay2 - timeMargin
        var id = 0
        Async.background(after: timeDelay1) {
            id += 1
            XCTAssertEqual(id, 1, "First after")

            let timePassed = Date().timeIntervalSince(date1)
            XCTAssert(timePassed >= lowerTimeDelay1, "Should wait \(timePassed) >= \(lowerTimeDelay1) seconds before firing")
            XCTAssert(timePassed < upperTimeDelay1, "Shouldn't wait \(timePassed), but <\(upperTimeDelay1) seconds before firing")
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.background.rawValue)

            date2 = Date() // Update
        }.background(after: timeDelay2) {
            id += 1
            XCTAssertEqual(id, 2, "Second after")

            let timePassed = Date().timeIntervalSince(date2)
            XCTAssert(timePassed >= lowerTimeDelay2, "Should wait \(timePassed) >= \(lowerTimeDelay2) seconds before firing")
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.background.rawValue)
            expectation.fulfill()
        }
        waitForExpectations(timeout: (timeDelay1 + timeDelay2) + timeMargin*2, handler: nil)
    }


    /* dispatch_block_cancel() */

    func testCancel() {
        let expectation = self.expectation(description: "Block1 should run")

        let block1 = Async.background {
            // Some work
            Thread.sleep(forTimeInterval: 0.2)
            expectation.fulfill()
        }
        let block2 = block1.background {
            XCTFail("Shouldn't be reached, since cancelled")
        }

        Async.main(after: 0.1) {
            block1.cancel() // First block is _not_ cancelled
            block2.cancel() // Second block _is_ cancelled
        }

        waitForExpectations(timeout: 0.2 + 0.1 + timeMargin*3, handler: nil)
    }


    /* dispatch_wait() */

    func testWait() {
        var id = 0
        let block = Async.background {
            // Some work
            Thread.sleep(forTimeInterval: 0.1)
            id += 1
            XCTAssertEqual(id, 1, "")
        }
        XCTAssertEqual(id, 0, "")

        block.wait()
        id += 1
        XCTAssertEqual(id, 2, "")
    }

    func testWaitMax() {
        var id = 0
        let date = Date()
        let upperTimeDelay = timeDelay + timeMargin
        let block = Async.background {
            id += 1
            XCTAssertEqual(id, 1, "The id should be 1") // A
            // Some work that takes longer than we want to wait for
            Thread.sleep(forTimeInterval: self.timeDelay + self.timeMargin)
            id += 1 // C
        }
        let idCheck = id // XCTAssertEqual is experienced to behave as a wait
        XCTAssertEqual(idCheck, 0, "The id should be 0, since block is send to background")
        // Wait
        block.wait(seconds: timeDelay)
        id += 1
        XCTAssertEqual(id, 2, "The id should be 2, since the block has begun running") // B
        let timePassed = Date().timeIntervalSince(date)
        XCTAssert(timePassed < upperTimeDelay, "Shouldn't wait \(upperTimeDelay) seconds before firing")
    }


    /* Generics */

    func testGenericsChain() {
        let expectationBackground = self.expectation(description: "Expected on background queue")
        let expectationMain = self.expectation(description: "Expected on main queue")
        let testValue = 10

        Async.background {
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.background.rawValue)
            expectationBackground.fulfill()
            return testValue
        }.main { (value: Int) in
            #if (arch(i386) || arch(x86_64)) && (os(iOS) || os(tvOS)) // Simulator
                XCTAssert(Thread.isMainThread, "Should be on main thread (simulator)")
            #else
                XCTAssertEqual(qos_class_self(), qos_class_main())
            #endif
            expectationMain.fulfill()
            XCTAssertEqual(value, testValue)
            return
        }
        waitForExpectations(timeout: timeMargin, handler: nil)
    }

    func testGenericsWait() {
        let asyncBlock = Async.background {
            return 10
        }.utility {
            return "T\($0)"
        }
        asyncBlock.wait()
        XCTAssertEqual(asyncBlock.output, Optional("T10"))
    }

    func testGenericsWaitMax() {
        var complete1 = false
        var complete2 = false
        let asyncBlock = Async.background {
            complete1 = true
            // Some work that takes longer than we want to wait for
            Thread.sleep(forTimeInterval: self.timeDelay + self.timeMargin)
            complete2 = true
            return 10
        }.utility { (_: Int) -> Void in }
        asyncBlock.wait(seconds: timeMargin)
        XCTAssertNil(asyncBlock.output)
        XCTAssert(complete1, "Should have been set in background block")
        XCTAssertFalse(complete2, "Should not have been set/reached in background block")
    }


    /* dispatch_apply() */

    func testApplyUserInteractive() {
        let count = 3
        let iterations = 0..<count
        let expectations = iterations.map { expectation(description: "\($0)") }
        Apply.userInteractive(count) { i in
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.userInteractive.rawValue)
            expectations[i].fulfill()
        }
        waitForExpectations(timeout: timeMargin, handler: nil)
    }

    func testApplyUserInitiated() {
        let count = 3
        let iterations = 0..<count
        let expectations = iterations.map { expectation(description: "\($0)") }
        Apply.userInitiated(count) { i in
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.userInitiated.rawValue)
            expectations[i].fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testApplyUtility() {
        let count = 3
        let iterations = 0..<count
        let expectations = iterations.map { expectation(description: "\($0)") }
        Apply.utility(count) { i in
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.utility.rawValue)
            expectations[i].fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testApplyBackground() {
        let count = 3
        let iterations = 0..<count
        let expectations = iterations.map { expectation(description: "\($0)") }
        Apply.background(count) { i in
            XCTAssertEqual(qos_class_self(), DispatchQoS.QoSClass.background.rawValue)
            expectations[i].fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testApplyCustomQueueConcurrent() {
        let count = 3
        let iterations = 0..<count
        let expectations = iterations.map { expectation(description: "\($0)") }
        let label = "CustomQueueConcurrentLabel"
        let customQueue = DispatchQueue(label: label, qos: .utility, attributes: [.concurrent])
        Apply.custom(queue: customQueue, iterations: count) { i in
            XCTAssertEqual(qos_class_self(), customQueue.qos.qosClass.rawValue)
            expectations[i].fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testApplyCustomQueueSerial() {
        let count = 3
        let iterations = 0..<count
        let expectations = iterations.map { expectation(description: "\($0)") }
        let label = "CustomQueueSerialLabel"
        let customQueue = DispatchQueue(label: label, qos: .utility, attributes: [])
        Apply.custom(queue: customQueue, iterations: count) { i in
            XCTAssertEqual(qos_class_self(), customQueue.qos.qosClass.rawValue)
            expectations[i].fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

}
