//
//  AsyncExample_iOSTests.swift
//  AsyncExample iOSTests
//
//  Created by Tobias DM on 15/07/14.
//  Copyright (c) 2014 Tobias Due Munk. All rights reserved.
//

import UIKit
import XCTest
import Async

class AsyncExample_iOSTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
	
	
	/* GCD */
	
	func testGCD() {
		
		let expectation = expectationWithDescription("Expected after time")
		
		let qos = QOS_CLASS_BACKGROUND
		let queue = dispatch_get_global_queue(qos, 0)
		dispatch_async(queue) {
			let currentQos = qos_class_self()
			XCTAssertEqual(currentQos, qos, "On \(currentQos.description) (expected \(qos.description))")
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	
	/* dispatch_async() */
    
    func testAsyncMain() {
		let expectation = expectationWithDescription("Expected on main queue")
		var calledStuffAfterSinceAsync = false
		Async.main {
			XCTAssertEqual(qos_class_self(), qos_class_main(), "On \(qos_class_self().description) (expexted \(qos_class_main().description))")
			XCTAssert(calledStuffAfterSinceAsync, "Should be async")
			expectation.fulfill()
		}
		calledStuffAfterSinceAsync = true
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testAsyncUserInteractive() {
		let expectation = expectationWithDescription("Expected On \(qos_class_self().description) (expected \(QOS_CLASS_USER_INTERACTIVE.description))")
		Async.userInteractive {
			XCTAssertEqual(qos_class_self(), QOS_CLASS_USER_INTERACTIVE, "On \(qos_class_self().description) (expected \(QOS_CLASS_USER_INTERACTIVE.description))")
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testAsyncUserInitiared() {
		let expectation = expectationWithDescription("Expected On \(qos_class_self().description) (expected \(QOS_CLASS_USER_INITIATED.description))")
		Async.userInitiated {
			XCTAssertEqual(qos_class_self(), QOS_CLASS_USER_INITIATED, "On \(qos_class_self().description) (expected \(QOS_CLASS_USER_INITIATED.description))")
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testAsyncUtility() {
		let expectation = expectationWithDescription("Expected On \(qos_class_self().description) (expected \(QOS_CLASS_USER_INTERACTIVE.description))")
		Async.utility {
			XCTAssertEqual(qos_class_self(), QOS_CLASS_UTILITY, "On \(qos_class_self().description) (expected \(QOS_CLASS_UTILITY.description))")
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testAsyncBackground() {
		let expectation = expectationWithDescription("Expected On \(qos_class_self().description) (expected \(QOS_CLASS_BACKGROUND.description))")
		Async.background {
			XCTAssertEqual(qos_class_self(), QOS_CLASS_BACKGROUND, "On \(qos_class_self().description) (expected \(QOS_CLASS_BACKGROUND.description))")
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testAsyncBackgroundToMain() {
		let expectation = expectationWithDescription("Expected on background to main queue")
		var wasInBackground = false
		Async.background {
			XCTAssertEqual(qos_class_self(), QOS_CLASS_BACKGROUND, "On \(qos_class_self().description) (expected \(QOS_CLASS_BACKGROUND.description))")
			wasInBackground = true
		}.main {
			XCTAssertEqual(qos_class_self(), qos_class_main(), "On \(qos_class_self().description) (expected \(qos_class_main().description))")
			XCTAssert(wasInBackground, "Was in background first")
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testChaining() {
		let expectation = expectationWithDescription("Expected On \(qos_class_self().description) (expected \(QOS_CLASS_USER_INTERACTIVE.description))")
		var id = 0
		Async.main {
			XCTAssertEqual(qos_class_self(), qos_class_main(), "On \(qos_class_self().description) (expexted \(qos_class_main().description))")
			XCTAssertEqual(++id, 1, "Count main queue")
		}.userInteractive {
			XCTAssertEqual(qos_class_self(), QOS_CLASS_USER_INTERACTIVE, "On \(qos_class_self().description) (expected \(QOS_CLASS_USER_INTERACTIVE.description))")
			XCTAssertEqual(++id, 2, "Count user interactive queue")
		}.userInitiated {
			XCTAssertEqual(qos_class_self(), QOS_CLASS_USER_INITIATED, "On \(qos_class_self().description) (expected \(QOS_CLASS_USER_INITIATED.description))")
			XCTAssertEqual(++id, 3, "Count user initiated queue")
		}.utility {
			XCTAssertEqual(qos_class_self(), QOS_CLASS_UTILITY, "On \(qos_class_self().description) (expected \(QOS_CLASS_UTILITY.description))")
			XCTAssertEqual(++id, 4, "Count utility queue")
		}.background {
			XCTAssertEqual(qos_class_self(), QOS_CLASS_BACKGROUND, "On \(qos_class_self().description) (expected \(QOS_CLASS_BACKGROUND.description))")
			XCTAssertEqual(++id, 5, "Count background queue")
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testCustomQueue() {
		let expectation = expectationWithDescription("Expected custom queues")
		var id = 0
		let customQueue = dispatch_queue_create("CustomQueueLabel", DISPATCH_QUEUE_CONCURRENT)
		let otherCustomQueue = dispatch_queue_create("OtherCustomQueueLabel", DISPATCH_QUEUE_SERIAL)
		Async.customQueue(customQueue) {
			XCTAssertEqual(++id, 1, "Count custom queue")
		}.customQueue(otherCustomQueue) {
			XCTAssertEqual(++id, 2, "Count other custom queue")
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	
	/* dispatch_after() */
	
	func testAfterGCD() {
		
		let expectation = expectationWithDescription("Expected after time")
		let date = NSDate()
		let timeDelay = 1.0
		let upperTimeDelay = timeDelay + 0.2
		let time = dispatch_time(DISPATCH_TIME_NOW, Int64(timeDelay * Double(NSEC_PER_SEC)))
		let queue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
		dispatch_after(time, queue, {
			let timePassed = NSDate().timeIntervalSinceDate(date)
			print("\(timePassed)")
			XCTAssert(timePassed >= timeDelay, "Should wait \(timeDelay) seconds before firing")
			XCTAssert(timePassed < upperTimeDelay, "Shouldn't wait \(upperTimeDelay) seconds before firing")
			XCTAssertEqual(qos_class_self(), QOS_CLASS_BACKGROUND, "On \(qos_class_self().description) (expected \(QOS_CLASS_BACKGROUND.description))")
			expectation.fulfill()
		})
		waitForExpectationsWithTimeout(timeDelay*2, handler: nil)
	}
	
	func testAfterMain() {
		let expectation = expectationWithDescription("Expected after time")
		let date = NSDate()
		let timeDelay = 1.0
		let upperTimeDelay = timeDelay + 0.2
		Async.main(after: timeDelay) {
			let timePassed = NSDate().timeIntervalSinceDate(date)
			XCTAssert(timePassed >= timeDelay, "Should wait \(timeDelay) seconds before firing")
			XCTAssert(timePassed < upperTimeDelay, "Shouldn't wait \(upperTimeDelay) seconds before firing")
			XCTAssertEqual(qos_class_self(), qos_class_main(), "On main queue")
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout(timeDelay*2, handler: nil)
	}
	
	func testChainedAfter() {
		let expectation = expectationWithDescription("Expected after time")
		let date1 = NSDate()
		var date2 = NSDate()
		let timeDelay1 = 1.1
		let upperTimeDelay1 = timeDelay1 + 0.2
		let timeDelay2 = 1.2
		let upperTimeDelay2 = timeDelay2 + 0.2
		var id = 0
		Async.userInteractive(after: timeDelay1) {
			XCTAssertEqual(++id, 1, "First after")
			
			let timePassed = NSDate().timeIntervalSinceDate(date1)
			XCTAssert(timePassed >= timeDelay1, "Should wait \(timeDelay1) seconds before firing")
			XCTAssert(timePassed < upperTimeDelay1, "Shouldn't wait \(upperTimeDelay1) seconds before firing")
			XCTAssertEqual(qos_class_self(), QOS_CLASS_USER_INTERACTIVE, "On \(qos_class_self().description) (expected \(QOS_CLASS_USER_INTERACTIVE.description))")
			
			date2 = NSDate() // Update
		}.utility(after: timeDelay2) {
			XCTAssertEqual(++id, 2, "Second after")
			
			let timePassed = NSDate().timeIntervalSinceDate(date2)
			XCTAssert(timePassed >= timeDelay2, "Should wait \(timeDelay2) seconds before firing")
			XCTAssert(timePassed < upperTimeDelay2, "Shouldn't wait \(upperTimeDelay2) seconds before firing")
			XCTAssertEqual(qos_class_self(), QOS_CLASS_UTILITY, "On \(qos_class_self().description) (expected \(QOS_CLASS_UTILITY.description))")
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout((timeDelay1 + timeDelay2) * 2, handler: nil)
	}
	
	func testAfterUserInteractive() {
		let expectation = expectationWithDescription("Expected after time")
		let date1 = NSDate()
		var date2 = NSDate()
		let timeDelay1 = 1.1
		let upperTimeDelay1 = timeDelay1 + 0.2
		let timeDelay2 = 1.2
		let upperTimeDelay2 = timeDelay2 + 0.2
		var id = 0
		Async.userInteractive(after: timeDelay1) {
			XCTAssertEqual(++id, 1, "First after")
			
			let timePassed = NSDate().timeIntervalSinceDate(date1)
			XCTAssert(timePassed >= timeDelay1, "Should wait \(timeDelay1) seconds before firing")
			XCTAssert(timePassed < upperTimeDelay1, "Shouldn't wait \(upperTimeDelay1) seconds before firing")
			XCTAssertEqual(qos_class_self(), QOS_CLASS_USER_INTERACTIVE, "On \(qos_class_self().description) (expected \(QOS_CLASS_USER_INTERACTIVE.description))")
			
			date2 = NSDate() // Update
		}.userInteractive(after: timeDelay2) {
			XCTAssertEqual(++id, 2, "Second after")
			
			let timePassed = NSDate().timeIntervalSinceDate(date2)
			XCTAssert(timePassed >= timeDelay2, "Should wait \(timeDelay2) seconds before firing")
			XCTAssert(timePassed < upperTimeDelay2, "Shouldn't wait \(upperTimeDelay2) seconds before firing")
			XCTAssertEqual(qos_class_self(), QOS_CLASS_USER_INTERACTIVE, "On \(qos_class_self().description) (expected \(QOS_CLASS_USER_INTERACTIVE.description))")
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout((timeDelay1 + timeDelay2) * 2, handler: nil)
	}
	
	func testAfterUserInitiated() {
		let expectation = expectationWithDescription("Expected after time")
		let date1 = NSDate()
		var date2 = NSDate()
		let timeDelay1 = 1.1
		let upperTimeDelay1 = timeDelay1 + 0.2
		let timeDelay2 = 1.2
		let upperTimeDelay2 = timeDelay2 + 0.2
		var id = 0
		Async.userInitiated(after: timeDelay1) {
			XCTAssertEqual(++id, 1, "First after")
			
			let timePassed = NSDate().timeIntervalSinceDate(date1)
			XCTAssert(timePassed >= timeDelay1, "Should wait \(timeDelay1) seconds before firing")
			XCTAssert(timePassed < upperTimeDelay1, "Shouldn't wait \(upperTimeDelay1) seconds before firing")
			XCTAssertEqual(qos_class_self(), QOS_CLASS_USER_INITIATED, "On \(qos_class_self().description) (expected \(QOS_CLASS_USER_INITIATED.description))")
			
			date2 = NSDate() // Update
		}.userInitiated(after: timeDelay2) {
			XCTAssertEqual(++id, 2, "Second after")
			
			let timePassed = NSDate().timeIntervalSinceDate(date2)
			XCTAssert(timePassed >= timeDelay2, "Should wait \(timeDelay2) seconds before firing")
			XCTAssert(timePassed < upperTimeDelay2, "Shouldn't wait \(upperTimeDelay2) seconds before firing")
			XCTAssertEqual(qos_class_self(), QOS_CLASS_USER_INITIATED, "On \(qos_class_self().description) (expected \(QOS_CLASS_USER_INITIATED.description))")
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout((timeDelay1 + timeDelay2) * 2, handler: nil)
    }
	
	func testAfterUtility() {
		let expectation = expectationWithDescription("Expected after time")
		let date1 = NSDate()
		var date2 = NSDate()
		let timeDelay1 = 1.1
		let upperTimeDelay1 = timeDelay1 + 0.2
		let timeDelay2 = 1.2
		let upperTimeDelay2 = timeDelay2 + 0.2
		var id = 0
		Async.utility(after: timeDelay1) {
			XCTAssertEqual(++id, 1, "First after")
			
			let timePassed = NSDate().timeIntervalSinceDate(date1)
			XCTAssert(timePassed >= timeDelay1, "Should wait \(timeDelay1) seconds before firing")
			XCTAssert(timePassed < upperTimeDelay1, "Shouldn't wait \(upperTimeDelay1) seconds before firing")
			XCTAssertEqual(qos_class_self(), QOS_CLASS_UTILITY, "On \(qos_class_self().description) (expected \(QOS_CLASS_UTILITY.description))")
			
			date2 = NSDate() // Update
		}.utility(after: timeDelay2) {
			XCTAssertEqual(++id, 2, "Second after")
			
			let timePassed = NSDate().timeIntervalSinceDate(date2)
			XCTAssert(timePassed >= timeDelay2, "Should wait \(timeDelay2) seconds before firing")
			XCTAssert(timePassed < upperTimeDelay2, "Shouldn't wait \(upperTimeDelay2) seconds before firing")
			XCTAssertEqual(qos_class_self(), QOS_CLASS_UTILITY, "On \(qos_class_self().description) (expected \(QOS_CLASS_UTILITY.description))")
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout((timeDelay1 + timeDelay2) * 2, handler: nil)
	}
	
	func testAfterBackground() {
		let expectation = expectationWithDescription("Expected after time")
		let date1 = NSDate()
		var date2 = NSDate()
		let timeDelay1 = 1.1
		let upperTimeDelay1 = timeDelay1 + 0.2
		let timeDelay2 = 1.2
		let upperTimeDelay2 = timeDelay2 + 0.2
		var id = 0
		Async.background(after: timeDelay1) {
			XCTAssertEqual(++id, 1, "First after")
			
			let timePassed = NSDate().timeIntervalSinceDate(date1)
			XCTAssert(timePassed >= timeDelay1, "Should wait \(timeDelay1) seconds before firing")
			XCTAssert(timePassed < upperTimeDelay1, "Shouldn't wait \(upperTimeDelay1) seconds before firing")
			XCTAssertEqual(qos_class_self(), QOS_CLASS_BACKGROUND, "On \(qos_class_self().description) (expected \(QOS_CLASS_BACKGROUND.description))")
			
			date2 = NSDate() // Update
		}.background(after: timeDelay2) {
			XCTAssertEqual(++id, 2, "Second after")
			
			let timePassed = NSDate().timeIntervalSinceDate(date2)
			XCTAssert(timePassed >= timeDelay2, "Should wait \(timeDelay2) seconds before firing")
			XCTAssert(timePassed < upperTimeDelay2, "Shouldn't wait \(upperTimeDelay2) seconds before firing")
			XCTAssertEqual(qos_class_self(), QOS_CLASS_BACKGROUND, "On \(qos_class_self().description) (expected \(QOS_CLASS_BACKGROUND.description))")
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout((timeDelay1 + timeDelay2) * 2, handler: nil)
	}


	/* dispatch_block_cancel() */

	func testCancel() {
		let expectation = expectationWithDescription("Block1 should run")
		
		let block1 = Async.background {
			// Heavy work
			for i in 0...1000 {
				print("A \(i)")
			}
			expectation.fulfill()
		}
		let block2 = block1.background {
			print("B – shouldn't be reached, since cancelled")
			XCTFail("Shouldn't be reached, since cancelled")
		}
		
		Async.main(after: 0.01) {
			block1.cancel() // First block is _not_ cancelled
			block2.cancel() // Second block _is_ cancelled
		}
		
		waitForExpectationsWithTimeout(20, handler: nil)
	}
	
	
	/* dispatch_wait() */
	
	func testWait() {
		var id = 0
		let block = Async.background {
			// Heavy work
			for i in 0...100 {
				print("A \(i)")
			}
			XCTAssertEqual(++id, 1, "")
		}
		XCTAssertEqual(id, 0, "")
		
		block.wait()
		XCTAssertEqual(++id, 2, "")
	}
	
	func testWaitMax() {
		var id = 0
		let block = Async.background {
			XCTAssertEqual(++id, 1, "") // A
			// Heavy work
			for i in 0...10000 {
				print("A \(i)")
			}
			XCTAssertEqual(++id, 3, "") // C
		}
		XCTAssertEqual(id, 0, "")
		
		let date = NSDate()
		let timeDelay = 0.3
		let upperTimeDelay = timeDelay + 0.2
		
		block.wait(seconds: timeDelay)
		
		XCTAssertEqual(++id, 2, "") // B
		let timePassed = NSDate().timeIntervalSinceDate(date)
		XCTAssert(timePassed < upperTimeDelay, "Shouldn't wait \(upperTimeDelay) seconds before firing")
	}
    
    
    /* dispatch_apply() */
    
    func testApplyUserInteractive() {
        let expectation1 = expectationWithDescription("1")
        let expectation2 = expectationWithDescription("2")
        let expectation3 = expectationWithDescription("3")
        let expectations = [expectation1, expectation2, expectation3]
        var count = 0
        Apply.userInteractive(3) { i in
            expectations[i].fulfill()
            count++
        }
        assert(count == 3, "Wrong count")
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testApplyUserInitiated() {
        let expectation1 = expectationWithDescription("1")
        let expectation2 = expectationWithDescription("2")
        let expectation3 = expectationWithDescription("3")
        let expectations = [expectation1, expectation2, expectation3]
        var count = 0
        Apply.userInitiated(3) { i in
            expectations[i].fulfill()
            count++
        }
        assert(count == 3, "Wrong count")
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testApplyUtility() {
        let expectation1 = expectationWithDescription("1")
        let expectation2 = expectationWithDescription("2")
        let expectation3 = expectationWithDescription("3")
        let expectations = [expectation1, expectation2, expectation3]
        var count = 0
        Apply.utility(3) { i in
            expectations[i].fulfill()
            count++
        }
        assert(count == 3, "Wrong count")
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testApplyBackground() {
        let expectation1 = expectationWithDescription("1")
        let expectation2 = expectationWithDescription("2")
        let expectation3 = expectationWithDescription("3")
        let expectations = [expectation1, expectation2, expectation3]
        var count = 0
        Apply.background(3) { i in
            expectations[i].fulfill()
            count++
        }
        assert(count == 3, "Wrong count")
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testApplyCustomQueueConcurrent() {
        let expectation1 = expectationWithDescription("1")
        let expectation2 = expectationWithDescription("2")
        let expectation3 = expectationWithDescription("3")
        let expectations = [expectation1, expectation2, expectation3]
        var count = 0
        let customQueue = dispatch_queue_create("CustomQueueConcurrentLabel", DISPATCH_QUEUE_CONCURRENT)
        Apply.customQueue(3, queue: customQueue) { i in
            print(i)
            expectations[i].fulfill()
            count++
        }
        assert(count == 3, "Wrong count")
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testApplyCustomQueueSerial() {
        let expectation1 = expectationWithDescription("1")
        let expectation2 = expectationWithDescription("2")
        let expectation3 = expectationWithDescription("3")
        let expectations = [expectation1, expectation2, expectation3]
        var count = 0
        let customQueue = dispatch_queue_create("CustomQueueSerialLabel", DISPATCH_QUEUE_SERIAL)
        Apply.customQueue(3, queue: customQueue) { i in
            print(i)
            expectations[i].fulfill()
            count++
        }
        assert(count == 3, "Wrong count")
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
