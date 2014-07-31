//
//  Async.swift
//
//  Created by Tobias DM on 15/07/14.
//
//	OS X 10.10+ and iOS 8.0+
//	Only use with ARC
//
//	The MIT License (MIT)
//	Copyright (c) 2014 Tobias Due Munk
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy of
//	this software and associated documentation files (the "Software"), to deal in
//	the Software without restriction, including without limitation the rights to
//	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//	the Software, and to permit persons to whom the Software is furnished to do so,
//	subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//	FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//	COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//	IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


import Foundation

// HACK: For Beta 4
@prefix func +(v: qos_class_t) -> Int {
	let i: UInt32 = reinterpretCast(v)
	return Int(i)
}

private class GCD {
	
	class func mainQueue() -> dispatch_queue_t {
		return dispatch_get_main_queue()
		// Could use return dispatch_get_global_queue(+qos_class_main(), 0)
	}
	class func userInteractiveQueue() -> dispatch_queue_t {
		return dispatch_get_global_queue(+QOS_CLASS_USER_INTERACTIVE, 0)
	}
	class func userInitiatedQueue() -> dispatch_queue_t {
		 return dispatch_get_global_queue(+QOS_CLASS_USER_INITIATED, 0)
	}
	class func defaultQueue() -> dispatch_queue_t {
		return dispatch_get_global_queue(+QOS_CLASS_DEFAULT, 0)
	}
	class func utilityQueue() -> dispatch_queue_t {
		return dispatch_get_global_queue(+QOS_CLASS_UTILITY, 0)
	}
	class func backgroundQueue() -> dispatch_queue_t {
		return dispatch_get_global_queue(+QOS_CLASS_BACKGROUND, 0)
	}
}


// Shared instance
private let _async = Async()

class Async {
	
	private class func run(block: dispatch_block_t, inQueue queue: dispatch_queue_t) -> dispatch_block_t_wrapper {
		// Create a new block (Qos Class) from block to allow adding a notification to it later (see dispatch_block_t_wrapper)
		// Create block with the "inherit" type
		let _block = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, block)
		// Add block to queue
		dispatch_async(queue, _block)
		// Wrap block in a struct since dispatch_block_t can't be extended
		return dispatch_block_t_wrapper(_block)
	}
	class func main(block: dispatch_block_t) -> dispatch_block_t_wrapper {
		return Async.run(block, inQueue: GCD.mainQueue())
	}
	class func userInteractive(block: dispatch_block_t) -> dispatch_block_t_wrapper {
		return Async.run(block, inQueue: GCD.userInteractiveQueue())
	}
	class func userInitiated(block: dispatch_block_t) -> dispatch_block_t_wrapper {
		return Async.run(block, inQueue: GCD.userInitiatedQueue())
	}
	class func default_(block: dispatch_block_t) -> dispatch_block_t_wrapper {
		return Async.run(block, inQueue: GCD.defaultQueue())
	}
	class func utility(block: dispatch_block_t) -> dispatch_block_t_wrapper {
		return Async.run(block, inQueue: GCD.utilityQueue())
	}
	class func background(block: dispatch_block_t) -> dispatch_block_t_wrapper {
		return Async.run(block, inQueue: GCD.backgroundQueue())
	}
	class func customQueue(queue: dispatch_queue_t, block: dispatch_block_t) -> dispatch_block_t_wrapper {
		return Async.run(block, inQueue: queue)
	}
}


// Wrapper since non-nominal type 'dispatch_block_t' cannot be extended (extension dispatch_block_t {})
struct dispatch_block_t_wrapper {
	
	let block: dispatch_block_t
	init(_ block: dispatch_block_t) {
		self.block = block
	}
	
	private func chain(block chainingBlock: dispatch_block_t, runInQueue queue: dispatch_queue_t) -> dispatch_block_t_wrapper {
		let _chainingBlock = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, chainingBlock)
		dispatch_block_notify(self.block, queue, _chainingBlock)
		return dispatch_block_t_wrapper(_chainingBlock)
	}
	
	func main(chainingBlock: dispatch_block_t) -> dispatch_block_t_wrapper {
		return chain(block: chainingBlock, runInQueue: GCD.mainQueue())
	}
	func userInteractive(chainingBlock: dispatch_block_t) -> dispatch_block_t_wrapper {
		return chain(block: chainingBlock, runInQueue: GCD.userInteractiveQueue())
	}
	func userInitiated(chainingBlock: dispatch_block_t) -> dispatch_block_t_wrapper {
		return chain(block: chainingBlock, runInQueue: GCD.userInitiatedQueue())
	}
	func default_(chainingBlock: dispatch_block_t) -> dispatch_block_t_wrapper {
		return chain(block: chainingBlock, runInQueue: GCD.defaultQueue())
	}
	func utility(chainingBlock: dispatch_block_t) -> dispatch_block_t_wrapper {
		return chain(block: chainingBlock, runInQueue: GCD.utilityQueue())
	}
	func background(chainingBlock: dispatch_block_t) -> dispatch_block_t_wrapper {
		return chain(block: chainingBlock, runInQueue: GCD.backgroundQueue())
	}
	func customQueue(queue: dispatch_queue_t, chainingBlock: dispatch_block_t) -> dispatch_block_t_wrapper {
		return chain(block: chainingBlock, runInQueue: queue)
	}
}

// Convenience
extension qos_class_t {

	// Calculated property
	var description: String {
		get {
			switch +self {
				case +qos_class_main(): return "Main"
				case +QOS_CLASS_USER_INTERACTIVE: return "User Interactive"
				case +QOS_CLASS_USER_INITIATED: return "User Initiated"
				case +QOS_CLASS_DEFAULT: return "Default"
				case +QOS_CLASS_UTILITY: return "Utility"
				case +QOS_CLASS_BACKGROUND: return "Background"
				case +QOS_CLASS_UNSPECIFIED: return "Unspecified"
				default: return "Unknown"
			}
		}
	}
}



