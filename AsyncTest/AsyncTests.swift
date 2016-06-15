//
//  AsyncExample_iOSTests.swift
//  AsyncExample iOSTests
//
//  Created by Tobias DM on 15/07/14.
//  Copyright (c) 2014 Tobias Due Munk. All rights reserved.
//

import Foundation
import XCTest


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

        let expectation = self.expectation(withDescription: "Expected after time")

        let qos: DispatchQueue.GlobalAttributes = .qosBackground
        let queue = DispatchQueue.global(attributes: qos)
        queue.async {
            XCTAssertEqual(qos_class_self(), QOS_CLASS_BACKGROUND)
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: timeMargin, handler: nil)
    }


    /* dispatch_async() */

    func testAsyncMain() {
        let expectation = self.expectation(withDescription: "Expected on main queue")
        var calledStuffAfterSinceAsync = false
        Async.main {
            #if (arch(i386) || arch(x86_64)) && (os(iOS) || os(tvOS)) // Simulator
                XCTAssert(Thread.isMainThread(), "Should be on main thread (simulator)")
            #else
                XCTAssertEqual(qos_class_self(), qos_class_main())
            #endif
            XCTAssert(calledStuffAfterSinceAsync, "Should be async")
            expectation.fulfill()
        }
        calledStuffAfterSinceAsync = true
        waitForExpectations(withTimeout: timeMargin, handler: nil)
    }

    func testAsyncUserInteractive() {
        let expectation = self.expectation(withDescription: "Expected on user interactive queue")
        Async.userInteractive {
            XCTAssertEqual(qos_class_self(), QOS_CLASS_USER_INTERACTIVE)
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: timeMargin, handler: nil)
    }

    func testAsyncUserInitiated() {
        let expectation = self.expectation(withDescription: "Expected on user initiated queue")
        Async.userInitiated {
            XCTAssertEqual(qos_class_self(), QOS_CLASS_USER_INITIATED)
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: timeMargin, handler: nil)
    }

    func testAsyncUtility() {
        let expectation = self.expectation(withDescription: "Expected on utility queue")
        Async.utility {
            XCTAssertEqual(qos_class_self(), QOS_CLASS_UTILITY)
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: timeMargin, handler: nil)
    }

    func testAsyncBackground() {
        let expectation = self.expectation(withDescription: "Expected on background queue")
        Async.background {
            XCTAssertEqual(qos_class_self(), QOS_CLASS_BACKGROUND)
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: timeMargin, handler: nil)
    }

    func testAsyncCustomQueueConcurrent() {
        let expectation = self.expectation(withDescription: "Expected custom queue")
        let label = "CustomQueueLabel"
        let customQueue = DispatchQueue(label: label, attributes: DispatchQueueAttributes.concurrent)
        let key = DispatchSpecificKey<String>()
        customQueue.setSpecific(key: key, value: label)
        Async.custom(queue: customQueue) {
            XCTAssertEqual(DispatchQueue.getSpecific(key: key), label)
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: timeMargin, handler: nil)
    }

    func testAsyncCustomQueueSerial() {
        let expectation = self.expectation(withDescription: "Expected custom queue")
        let label = "CustomQueueLabel"
        let customQueue = DispatchQueue(label: label, attributes: DispatchQueueAttributes.serial)
        let key = DispatchSpecificKey<String>()
        customQueue.setSpecific(key: key, value: label)
        Async.custom(queue: customQueue) {
            XCTAssertEqual(DispatchQueue.getSpecific(key: key), label)
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: timeMargin, handler: nil)
    }


    /* Chaining */

    func testAsyncBackgroundToMain() {
        let expectation = self.expectation(withDescription: "Expected on background to main queue")
        var wasInBackground = false
        Async.background {
            XCTAssertEqual(qos_class_self(), QOS_CLASS_BACKGROUND)
            wasInBackground = true
        }.main {
            #if (arch(i386) || arch(x86_64)) && (os(iOS) || os(tvOS)) // Simulator
                XCTAssert(Thread.isMainThread(), "Should be on main thread (simulator)")
            #else
                XCTAssertEqual(qos_class_self(), qos_class_main())
            #endif
            XCTAssert(wasInBackground, "Was in background first")
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: timeMargin*2, handler: nil)
    }

    func testChaining() {
        let expectation = self.expectation(withDescription: "Expected On \(qos_class_self()) (expected \(QOS_CLASS_USER_INITIATED))")
        var id = 0
        Async.main {
            #if (arch(i386) || arch(x86_64)) && (os(iOS) || os(tvOS)) // Simulator
                XCTAssert(Thread.isMainThread(), "Should be on main thread (simulator)")
            #else
                XCTAssertEqual(qos_class_self(), qos_class_main())
            #endif
            id += 1
            XCTAssertEqual(id, 1, "Count main queue")
        }.userInteractive {
            XCTAssertEqual(qos_class_self(), QOS_CLASS_USER_INTERACTIVE)
            id += 1
            XCTAssertEqual(id, 2, "Count user interactive queue")
        }.userInitiated {
            XCTAssertEqual(qos_class_self(), QOS_CLASS_USER_INITIATED)
            id += 1
            XCTAssertEqual(id, 3, "Count user initiated queue")
        }.utility {
            XCTAssertEqual(qos_class_self(), QOS_CLASS_UTILITY)
            id += 1
            XCTAssertEqual(id, 4, "Count utility queue")
        }.background {
            XCTAssertEqual(qos_class_self(), QOS_CLASS_BACKGROUND)
            id += 1
            XCTAssertEqual(id, 5, "Count background queue")
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: timeMargin*5, handler: nil)
    }

    func testAsyncCustomQueueChaining() {
        let expectation = self.expectation(withDescription: "Expected custom queues")
        var id = 0
        let customQueue = DispatchQueue(label: "CustomQueueLabel", attributes: DispatchQueueAttributes.concurrent)
        let otherCustomQueue = DispatchQueue(label: "OtherCustomQueueLabel", attributes: DispatchQueueAttributes.serial)
        Async.custom(queue: customQueue) {
            id += 1
            XCTAssertEqual(id, 1, "Count custom queue")
        }.custom(queue: otherCustomQueue) {
            id += 1
            XCTAssertEqual(id, 2, "Count other custom queue")
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: timeMargin*2, handler: nil)
    }


    /* dispatch_after() */

    func testAfterGCD() {

        let expectation = self.expectation(withDescription: "Expected after time")
        let date = Date()
        let lowerTimeDelay = timeDelay - timeMargin
        let time = DispatchTime.now() + timeDelay
        let queue = DispatchQueue.global(attributes: .qosBackground)
        queue.after(when: time) {
            let timePassed = Date().timeIntervalSince(date)
            XCTAssert(timePassed >= lowerTimeDelay, "Should wait \(timePassed) >= \(lowerTimeDelay) seconds before firing")
            XCTAssertEqual(qos_class_self(), QOS_CLASS_BACKGROUND)
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: timeDelay + timeMargin, handler: nil)
    }

    func testAfterMain() {
        let expectation = self.expectation(withDescription: "Expected after time")
        let date = Date()
        let lowerTimeDelay = timeDelay - timeMargin
        Async.main(after: timeDelay) {
            let timePassed = Date().timeIntervalSince(date)
            XCTAssert(timePassed >= lowerTimeDelay, "Should wait \(timePassed) >= \(lowerTimeDelay) seconds before firing")
            #if (arch(i386) || arch(x86_64)) && (os(iOS) || os(tvOS)) // Simulator
                XCTAssert(Thread.isMainThread(), "Should be on main thread (simulator)")
            #else
                XCTAssertEqual(qos_class_self(), qos_class_main())
            #endif
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: timeDelay + timeMargin, handler: nil)
    }

    func testAfterUserInteractive() {
        let expectation = self.expectation(withDescription: "Expected after time")
        let date = Date()
        let lowerTimeDelay = timeDelay - timeMargin
        Async.userInteractive(after: timeDelay) {
            let timePassed = Date().timeIntervalSince(date)
            XCTAssert(timePassed >= lowerTimeDelay, "Should wait \(timePassed) >= \(lowerTimeDelay) seconds before firing")
            XCTAssertEqual(qos_class_self(), QOS_CLASS_USER_INTERACTIVE)
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: timeDelay + timeMargin, handler: nil)
    }

    func testAfterUserInitated() {
        let expectation = self.expectation(withDescription: "Expected after time")
        let date = Date()
        let lowerTimeDelay = timeDelay - timeMargin
        Async.userInitiated(after: timeDelay) {
            let timePassed = Date().timeIntervalSince(date)
            XCTAssert(timePassed >= lowerTimeDelay, "Should wait \(timePassed) >= \(lowerTimeDelay) seconds before firing")
            XCTAssertEqual(qos_class_self(), QOS_CLASS_USER_INITIATED)
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: timeDelay + timeMargin, handler: nil)
    }

    func testAfterUtility() {
        let expectation = self.expectation(withDescription: "Expected after time")
        let date = Date()
        let lowerTimeDelay = timeDelay - timeMargin
        Async.utility(after: timeDelay) {
            let timePassed = Date().timeIntervalSince(date)
            XCTAssert(timePassed >= lowerTimeDelay, "Should wait \(timePassed) >= \(lowerTimeDelay) seconds before firing")
            XCTAssertEqual(qos_class_self(), QOS_CLASS_UTILITY)
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: timeDelay + timeMargin, handler: nil)
    }

    func testAfterBackground() {
        let expectation = self.expectation(withDescription: "Expected after time")
        let date = Date()
        let lowerTimeDelay = timeDelay - timeMargin
        Async.background(after: timeDelay) {
            let timePassed = Date().timeIntervalSince(date)
            XCTAssert(timePassed >= lowerTimeDelay, "Should wait \(timePassed) >= \(lowerTimeDelay) seconds before firing")
            XCTAssertEqual(qos_class_self(), QOS_CLASS_BACKGROUND)
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: timeDelay + timeMargin, handler: nil)
    }

    func testAfterCustomQueue() {
        let expectation = self.expectation(withDescription: "Expected after time")
        let date = Date()
        let timeDelay = 1.0
        let lowerTimeDelay = timeDelay - timeMargin
        let label = "CustomQueueLabel"
        let customQueue = DispatchQueue(label: label, attributes: DispatchQueueAttributes.concurrent)
        let key = DispatchSpecificKey<String>()
        customQueue.setSpecific(key: key, value: label)
        Async.custom(queue: customQueue, after: timeDelay) {
            let timePassed = Date().timeIntervalSince(date)
            XCTAssert(timePassed >= lowerTimeDelay, "Should wait \(timePassed) >= \(lowerTimeDelay) seconds before firing")
            XCTAssertEqual(DispatchQueue.getSpecific(key: key), label)
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: timeDelay + timeMargin, handler: nil)
    }

    func testAfterChainedMix() {
        let expectation = self.expectation(withDescription: "Expected after time")
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
            XCTAssertEqual(qos_class_self(), QOS_CLASS_USER_INTERACTIVE)

            date2 = Date() // Update
        }.utility(after: timeDelay2) {
            id += 1
            XCTAssertEqual(id, 2, "Second after")

            let timePassed = Date().timeIntervalSince(date2)
            XCTAssert(timePassed >= lowerTimeDelay2, "Should wait \(timePassed) >= \(lowerTimeDelay2) seconds before firing")
            XCTAssertEqual(qos_class_self(), QOS_CLASS_UTILITY)
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: (timeDelay1 + timeDelay2) + timeMargin*2, handler: nil)
    }

    func testAfterChainedUserInteractive() {
        let expectation = self.expectation(withDescription: "Expected after time")
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
            XCTAssertEqual(qos_class_self(), QOS_CLASS_USER_INTERACTIVE)

            date2 = Date() // Update
        }.userInteractive(after: timeDelay2) {
            id += 1
            XCTAssertEqual(id, 2, "Second after")

            let timePassed = Date().timeIntervalSince(date2)
            XCTAssert(timePassed >= lowerTimeDelay2, "Should wait \(timePassed) >= \(lowerTimeDelay2) seconds before firing")
            XCTAssertEqual(qos_class_self(), QOS_CLASS_USER_INTERACTIVE)
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: (timeDelay1 + timeDelay2) + timeMargin*2, handler: nil)
    }

    func testAfterChainedUserInitiated() {
        let expectation = self.expectation(withDescription: "Expected after time")
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
            XCTAssertEqual(qos_class_self(), QOS_CLASS_USER_INITIATED)

            date2 = Date() // Update
        }.userInitiated(after: timeDelay2) {
            id += 1
            XCTAssertEqual(id, 2, "Second after")

            let timePassed = Date().timeIntervalSince(date2)
            XCTAssert(timePassed >= lowerTimeDelay2, "Should wait \(timePassed) >= \(lowerTimeDelay2) seconds before firing")
            XCTAssertEqual(qos_class_self(), QOS_CLASS_USER_INITIATED)
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: (timeDelay1 + timeDelay2) + timeMargin*2, handler: nil)
    }

    func testAfterChainedUtility() {
        let expectation = self.expectation(withDescription: "Expected after time")
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
            XCTAssertEqual(qos_class_self(), QOS_CLASS_UTILITY)

            date2 = Date() // Update
        }.utility(after: timeDelay2) {
            id += 1
            XCTAssertEqual(id, 2, "Second after")

            let timePassed = Date().timeIntervalSince(date2)
            XCTAssert(timePassed >= lowerTimeDelay2, "Should wait \(timePassed) >= \(lowerTimeDelay2) seconds before firing")
            XCTAssertEqual(qos_class_self(), QOS_CLASS_UTILITY)
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: (timeDelay1 + timeDelay2) * 2, handler: nil)
    }

    func testAfterChainedBackground() {
        let expectation = self.expectation(withDescription: "Expected after time")
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
            XCTAssertEqual(qos_class_self(), QOS_CLASS_BACKGROUND)

            date2 = Date() // Update
        }.background(after: timeDelay2) {
            id += 1
            XCTAssertEqual(id, 2, "Second after")

            let timePassed = Date().timeIntervalSince(date2)
            XCTAssert(timePassed >= lowerTimeDelay2, "Should wait \(timePassed) >= \(lowerTimeDelay2) seconds before firing")
            XCTAssertEqual(qos_class_self(), QOS_CLASS_BACKGROUND)
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: (timeDelay1 + timeDelay2) + timeMargin*2, handler: nil)
    }


    /* dispatch_block_cancel() */

    func testCancel() {
        let expectation = self.expectation(withDescription: "Block1 should run")

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

        waitForExpectations(withTimeout: 0.2 + 0.1 + timeMargin*3, handler: nil)
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
        XCTAssertEqual(id, 0, "The id should be 0, since block is send to background")
        // Wait
        block.wait(seconds: timeDelay)
        id += 1
        XCTAssertEqual(id, 2, "The id should be 2, since the block has begun running") // B
        let timePassed = Date().timeIntervalSince(date)
        XCTAssert(timePassed < upperTimeDelay, "Shouldn't wait \(upperTimeDelay) seconds before firing")
    }


    /* dispatch_apply() */

    func testApplyUserInteractive() {
        let expectation1 = expectation(withDescription: "1")
        let expectation2 = expectation(withDescription: "2")
        let expectation3 = expectation(withDescription: "3")
        let expectations = [expectation1, expectation2, expectation3]
        var count = 0
        Apply.userInteractive(3) { i in
            XCTAssertEqual(qos_class_self(), QOS_CLASS_USER_INTERACTIVE)
            expectations[i].fulfill()
            count += 1
        }
        XCTAssertEqual(count, 3, "Wrong count")
        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testApplyUserInitiated() {
        let expectation1 = expectation(withDescription: "1")
        let expectation2 = expectation(withDescription: "2")
        let expectation3 = expectation(withDescription: "3")
        let expectations = [expectation1, expectation2, expectation3]
        var count = 0
        Apply.userInitiated(3) { i in
            XCTAssertEqual(qos_class_self(), QOS_CLASS_USER_INITIATED)
            expectations[i].fulfill()
            count += 1
        }
        XCTAssertEqual(count, 3, "Wrong count")
        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testApplyUtility() {
        let expectation1 = expectation(withDescription: "1")
        let expectation2 = expectation(withDescription: "2")
        let expectation3 = expectation(withDescription: "3")
        let expectations = [expectation1, expectation2, expectation3]
        var count = 0
        Apply.utility(3) { i in
            XCTAssertEqual(qos_class_self(), QOS_CLASS_UTILITY)
            expectations[i].fulfill()
            count += 1
        }
        XCTAssertEqual(count, 3, "Wrong count")
        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testApplyBackground() {
        let expectation1 = expectation(withDescription: "1")
        let expectation2 = expectation(withDescription: "2")
        let expectation3 = expectation(withDescription: "3")
        let expectations = [expectation1, expectation2, expectation3]
        var count = 0
        Apply.background(3) { i in
            XCTAssertEqual(qos_class_self(), QOS_CLASS_BACKGROUND)
            expectations[i].fulfill()
            count += 1
        }
        XCTAssertEqual(count, 3, "Wrong count")
        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testApplyCustomQueueConcurrent() {
        let expectation1 = expectation(withDescription: "1")
        let expectation2 = expectation(withDescription: "2")
        let expectation3 = expectation(withDescription: "3")
        let expectations = [expectation1, expectation2, expectation3]
        var count = 0
        let label = "CustomQueueConcurrentLabel"
        let customQueue = DispatchQueue(label: label, attributes: DispatchQueueAttributes.concurrent)
        let key = DispatchSpecificKey<String>()
        customQueue.setSpecific(key: key, value: label)
        Apply.custom(queue: customQueue, iterations: 3) { i in
            XCTAssertEqual(DispatchQueue.getSpecific(key: key), label)
            expectations[i].fulfill()
            count += 1
        }
        XCTAssertEqual(count, 3, "Wrong count")
        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testApplyCustomQueueSerial() {
        let count = 3
        let iterations = 0..<count
        let expectations = iterations.map { expectation(withDescription: "\($0)") }
        var index = 0
        let label = "CustomQueueSerialLabel"
        let customQueue = DispatchQueue(label: label, attributes: DispatchQueueAttributes.serial)
        let key = DispatchSpecificKey<String>()
        customQueue.setSpecific(key: key, value: label)
        Apply.custom(queue: customQueue, iterations: count) { i in
            XCTAssertEqual(DispatchQueue.getSpecific(key: key), label)
            expectations[i].fulfill()
            index += 1
        }
        XCTAssertEqual(index, count, "Wrong count")
        waitForExpectations(withTimeout: 1, handler: nil)
    }

}
