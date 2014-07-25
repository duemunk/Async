//
//  ViewController.swift
//  AsyncExample iOS
//
//  Created by Tobias DM on 15/07/14.
//  Copyright (c) 2014 Tobias Due Munk. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
                            
	override func viewDidLoad() {
		super.viewDidLoad()

		// Async syntactic sugar
		Async.background {
			println("A: This is run on the \(qos_class_self().description) (expected \(QOS_CLASS_BACKGROUND.description))")
		}.main {
			println("B: This is run on the \(qos_class_self().description) (expected \(qos_class_main().description)), after the previous block")
		}

		// Regular GCD
		/*
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
			println("REGULAR GCD: This is run on the background queue")

			dispatch_async(dispatch_get_main_queue(), 0), {
				println("REGULAR GCD: This is run on the main queue")
			})
		})
		*/

		/*
		// Chaining with Async
		var id = 0
		Async.main {
			println("This is run on the \(qos_class_self().description) (expected \(qos_class_main().description)) count: \(++id) (expected 1) ")
			// Prints: "This is run on the Main (expected Main) count: 1 (expected 1)"
		}.userInteractive {
			println("This is run on the \(qos_class_self().description) (expected \(QOS_CLASS_USER_INTERACTIVE.description)) count: \(++id) (expected 2) ")
			// Prints: "This is run on the Main (expected Main) count: 2 (expected 2)"
		}.userInitiated {
			println("This is run on the \(qos_class_self().description) (expected \(QOS_CLASS_USER_INITIATED.description)) count: \(++id) (expected 3) ")
			// Prints: "This is run on the User Initiated (expected User Initiated) count: 3 (expected 3)"
		}.utility {
			println("This is run on the \(qos_class_self().description) (expected \(QOS_CLASS_UTILITY.description)) count: \(++id) (expected 4) ")
			// Prints: "This is run on the Utility (expected Utility) count: 4 (expected 4)"
		}.background {
			println("This is run on the \(qos_class_self().description) (expected \(QOS_CLASS_BACKGROUND.description)) count: \(++id) (expected 5) ")
			// Prints: "This is run on the User Interactive (expected User Interactive) count: 5 (expected 5)"
		}
		*/
		
		/*
		// Keep reference for block for later chaining
		let backgroundBlock = Async.background {
			println("This is run on the \(qos_class_self().description) (expected \(QOS_CLASS_BACKGROUND.description))")
		}
		// Run other code here...
		backgroundBlock.main {
			println("This is run on the \(qos_class_self().description) (expected \(qos_class_main().description)), after the previous block")
		}
		*/
	}
}

