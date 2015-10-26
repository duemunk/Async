//
//  ViewController.swift
//  AsyncExample iOS
//
//  Created by Tobias DM on 15/07/14.
//  Copyright (c) 2014 Tobias Due Munk. All rights reserved.
//

import UIKit
import Async

class ViewController: UIViewController {
                            
	override func viewDidLoad() {
		super.viewDidLoad()

		// Async syntactic sugar
		Async.background {
			print("A: This is run on the \(qos_class_self().description) (expected \(QOS_CLASS_BACKGROUND.description))")
		}.main {
			print("B: This is run on the \(qos_class_self().description) (expected \(qos_class_main().description)), after the previous block")
		}

		// Regular GCD
		/*
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
			print("REGULAR GCD: This is run on the background queue")

			dispatch_async(dispatch_get_main_queue(), 0), {
				print("REGULAR GCD: This is run on the main queue")
			})
		})
		*/

		/*
		// Chaining with Async
		var id = 0
		Async.main {
			print("This is run on the \(qos_class_self().description) (expected \(qos_class_main().description)) count: \(++id) (expected 1) ")
			// Prints: "This is run on the Main (expected Main) count: 1 (expected 1)"
		}.userInteractive {
			print("This is run on the \(qos_class_self().description) (expected \(QOS_CLASS_USER_INTERACTIVE.description)) count: \(++id) (expected 2) ")
			// Prints: "This is run on the Main (expected Main) count: 2 (expected 2)"
		}.userInitiated {
			print("This is run on the \(qos_class_self().description) (expected \(QOS_CLASS_USER_INITIATED.description)) count: \(++id) (expected 3) ")
			// Prints: "This is run on the User Initiated (expected User Initiated) count: 3 (expected 3)"
		}.utility {
			print("This is run on the \(qos_class_self().description) (expected \(QOS_CLASS_UTILITY.description)) count: \(++id) (expected 4) ")
			// Prints: "This is run on the Utility (expected Utility) count: 4 (expected 4)"
		}.background {
			print("This is run on the \(qos_class_self().description) (expected \(QOS_CLASS_BACKGROUND.description)) count: \(++id) (expected 5) ")
			// Prints: "This is run on the User Interactive (expected User Interactive) count: 5 (expected 5)"
		}
		*/
		
		/*
		// Keep reference for block for later chaining
		let backgroundBlock = Async.background {
			print("This is run on the \(qos_class_self().description) (expected \(QOS_CLASS_BACKGROUND.description))")
		}
		// Run other code here...
		backgroundBlock.main {
			print("This is run on the \(qos_class_self().description) (expected \(qos_class_main().description)), after the previous block")
		}
		*/
		
		/*
		// Custom queues
		let customQueue = dispatch_queue_create("CustomQueueLabel", DISPATCH_QUEUE_CONCURRENT)
		let otherCustomQueue = dispatch_queue_create("OtherCustomQueueLabel", DISPATCH_QUEUE_CONCURRENT)
		Async.customQueue(customQueue) {
			print("Custom queue")
		}.customQueue(otherCustomQueue) {
			print("Other custom queue")
		}
		*/
		
		/*
		// After
		let seconds = 0.5
		Async.main(after: seconds) {
			print("Is called after 0.5 seconds")
		}.background(after: 0.4) {
			print("At least 0.4 seconds after previous block, and 0.9 after Async code is called")
		}
		*/
		
		/*
		// Cancel blocks not yet dispatched
		let block1 = Async.background {
			// Heavy work
			for i in 0...1000 {
				print("A \(i)")
			}
		}
		let block2 = block1.background {
			print("B – shouldn't be reached, since cancelled")
		}
		Async.main {
			block1.cancel() // First block is _not_ cancelled
			block2.cancel() // Second block _is_ cancelled
		}
		*/
	}
}

