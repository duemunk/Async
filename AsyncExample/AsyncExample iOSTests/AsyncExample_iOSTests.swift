//
//  AsyncExample_iOSTests.swift
//  AsyncExample iOSTests
//
//  Created by Tobias DM on 15/07/14.
//  Copyright (c) 2014 Tobias Due Munk. All rights reserved.
//

import UIKit
import XCTest

class AsyncExample_iOSTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAsyncMain() {
		let expectation = expectationWithDescription("Expected on main queue")
		var calledStuffAfterSinceAsync = false
		Async.main {
			XCTAssertEqual(+qos_class_self(), +qos_class_main(), "On main queue")
			XCTAssert(calledStuffAfterSinceAsync, "Should be async")
			expectation.fulfill()
		}
		calledStuffAfterSinceAsync = true
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testAsyncUserInteractive() {
		let expectation = expectationWithDescription("Expected on user interactive queue")
		Async.userInteractive {
			XCTAssertEqual(+qos_class_self(), +QOS_CLASS_USER_INTERACTIVE, "On user interactive queue")
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testAsyncUserInitiared() {
		let expectation = expectationWithDescription("Expected on user initiated queue")
		Async.userInitiated {
			XCTAssertEqual(+qos_class_self(), +QOS_CLASS_USER_INITIATED, "On user initiated queue")
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	// Not expected to succeed (Apples wording: "Not intended as a work classification")
//	func testAsyncDefault() {
//		let expectation = expectationWithDescription("Expected on default queue")
//		Async.default_ {
//			XCTAssertEqual(+qos_class_self(), +QOS_CLASS_DEFAULT, "On default queue")
//			expectation.fulfill()
//		}
//		waitForExpectationsWithTimeout(1, handler: nil)
//	}
	
	func testAsyncUtility() {
		let expectation = expectationWithDescription("Expected on user interactive queue")
		Async.utility {
			XCTAssertEqual(+qos_class_self(), +QOS_CLASS_UTILITY, "On utility queue")
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testAsyncBackground() {
		let expectation = expectationWithDescription("Expected on background queue")
		Async.background {
			XCTAssertEqual(+qos_class_self(), +QOS_CLASS_BACKGROUND, "On background queue")
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testAsyncBackgroundToMain() {
		let expectation = expectationWithDescription("Expected on background to main queue")
		var wasInBackground = false
		Async.background {
			XCTAssertEqual(+qos_class_self(), +QOS_CLASS_BACKGROUND, "On background queue")
			wasInBackground = true
		}.main {
			XCTAssertEqual(+qos_class_self(), +qos_class_main(), "On main queue")
			XCTAssert(wasInBackground, "Was in background first")
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testChaining() {
		let expectation = expectationWithDescription("Expected on user interactive queue")
		var id = 0
		Async.main {
			XCTAssertEqual(+qos_class_self(), +qos_class_main(), "On main queue")
			XCTAssertEqual(++id, 1, "Count main queue")
		}.userInteractive {
			XCTAssertEqual(+qos_class_self(), +QOS_CLASS_USER_INTERACTIVE, "On user interactive queue")
			XCTAssertEqual(++id, 2, "Count user interactive queue")
		}.userInitiated {
			XCTAssertEqual(+qos_class_self(), +QOS_CLASS_USER_INITIATED, "On user initiated queue")
			XCTAssertEqual(++id, 3, "Count user initiated queue")
		}.utility {
			XCTAssertEqual(+qos_class_self(), +QOS_CLASS_UTILITY, "On utility queue")
			XCTAssertEqual(++id, 4, "Count utility queue")
		}.background {
			XCTAssertEqual(+qos_class_self(), +QOS_CLASS_BACKGROUND, "On background queue")
			XCTAssertEqual(++id, 5, "Count background queue")
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout(1, handler: nil)
	}
    
}
