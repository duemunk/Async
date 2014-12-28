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

// HACK: For Swift 1.0
extension qos_class_t {
    
    public var id:Int {
        return Int(self.value)
    }
}

private class GCD {
	
	/* dispatch_get_queue() */
	class func mainQueue() -> dispatch_queue_t {
		return dispatch_get_main_queue()
		// Could use return dispatch_get_global_queue(qos_class_main().id, 0)
	}
	class func userInteractiveQueue() -> dispatch_queue_t {
		return dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE.id, 0)
	}
	class func userInitiatedQueue() -> dispatch_queue_t {
		 return dispatch_get_global_queue(QOS_CLASS_USER_INITIATED.id, 0)
	}
	class func utilityQueue() -> dispatch_queue_t {
		return dispatch_get_global_queue(QOS_CLASS_UTILITY.id, 0)
	}
	class func backgroundQueue() -> dispatch_queue_t {
		return dispatch_get_global_queue(QOS_CLASS_BACKGROUND.id, 0)
	}
}


public struct Async {
    
    private let block: dispatch_block_t
    
    private init(_ block: dispatch_block_t) {
        self.block = block
    }
}


extension Async { // Static methods

	
	/* dispatch_async() */

	private static func async(block: dispatch_block_t, inQueue queue: dispatch_queue_t) -> Async {
		// Create a new block (Qos Class) from block to allow adding a notification to it later (see matching regular Async methods)
		// Create block with the "inherit" type
		let _block = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, block)
		// Add block to queue
		dispatch_async(queue, _block)
		// Wrap block in a struct since dispatch_block_t can't be extended
		return Async(_block)
	}
	public static func main(block: dispatch_block_t) -> Async {
		return Async.async(block, inQueue: GCD.mainQueue())
	}
	public static func userInteractive(block: dispatch_block_t) -> Async {
		return Async.async(block, inQueue: GCD.userInteractiveQueue())
	}
	public static func userInitiated(block: dispatch_block_t) -> Async {
		return Async.async(block, inQueue: GCD.userInitiatedQueue())
	}
	static func utility(block: dispatch_block_t) -> Async {
		return Async.async(block, inQueue: GCD.utilityQueue())
	}
	public static func background(block: dispatch_block_t) -> Async {
		return Async.async(block, inQueue: GCD.backgroundQueue())
	}
	public static func customQueue(queue: dispatch_queue_t, block: dispatch_block_t) -> Async {
		return Async.async(block, inQueue: queue)
	}


	/* dispatch_after() */

	private static func after(seconds: Double, block: dispatch_block_t, inQueue queue: dispatch_queue_t) -> Async {
		let nanoSeconds = Int64(seconds * Double(NSEC_PER_SEC))
		let time = dispatch_time(DISPATCH_TIME_NOW, nanoSeconds)
		return at(time, block: block, inQueue: queue)
	}
	private static func at(time: dispatch_time_t, block: dispatch_block_t, inQueue queue: dispatch_queue_t) -> Async {
		// See Async.async() for comments
		let _block = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, block)
		dispatch_after(time, queue, _block)
		return Async(_block)
	}
	public static func main(#after: Double, block: dispatch_block_t) -> Async {
		return Async.after(after, block: block, inQueue: GCD.mainQueue())
	}
	public static func userInteractive(#after: Double, block: dispatch_block_t) -> Async {
		return Async.after(after, block: block, inQueue: GCD.userInteractiveQueue())
	}
	public static func userInitiated(#after: Double, block: dispatch_block_t) -> Async {
		return Async.after(after, block: block, inQueue: GCD.userInitiatedQueue())
	}
	static func utility(#after: Double, block: dispatch_block_t) -> Async {
		return Async.after(after, block: block, inQueue: GCD.utilityQueue())
	}
	public static func background(#after: Double, block: dispatch_block_t) -> Async {
		return Async.after(after, block: block, inQueue: GCD.backgroundQueue())
	}
	public static func customQueue(#after: Double, queue: dispatch_queue_t, block: dispatch_block_t) -> Async {
		return Async.after(after, block: block, inQueue: queue)
	}
}


extension Async { // Regualar methods matching static once


	/* dispatch_async() */
	
	private func chain(block chainingBlock: dispatch_block_t, runInQueue queue: dispatch_queue_t) -> Async {
		// See Async.async() for comments
		let _chainingBlock = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, chainingBlock)
		dispatch_block_notify(self.block, queue, _chainingBlock)
		return Async(_chainingBlock)
	}
	
	public func main(chainingBlock: dispatch_block_t) -> Async {
		return chain(block: chainingBlock, runInQueue: GCD.mainQueue())
	}
	public func userInteractive(chainingBlock: dispatch_block_t) -> Async {
		return chain(block: chainingBlock, runInQueue: GCD.userInteractiveQueue())
	}
	public func userInitiated(chainingBlock: dispatch_block_t) -> Async {
		return chain(block: chainingBlock, runInQueue: GCD.userInitiatedQueue())
	}
	func utility(chainingBlock: dispatch_block_t) -> Async {
		return chain(block: chainingBlock, runInQueue: GCD.utilityQueue())
	}
	public func background(chainingBlock: dispatch_block_t) -> Async {
		return chain(block: chainingBlock, runInQueue: GCD.backgroundQueue())
	}
	public func customQueue(queue: dispatch_queue_t, chainingBlock: dispatch_block_t) -> Async {
		return chain(block: chainingBlock, runInQueue: queue)
	}

	
	/* dispatch_after() */

	private func after(seconds: Double, block chainingBlock: dispatch_block_t, runInQueue queue: dispatch_queue_t) -> Async {
		
		// Create a new block (Qos Class) from block to allow adding a notification to it later (see Async)
		// Create block with the "inherit" type
		let _chainingBlock = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, chainingBlock)
		
		// Wrap block to be called when previous block is finished
		let chainingWrapperBlock: dispatch_block_t = {
			// Calculate time from now
			let nanoSeconds = Int64(seconds * Double(NSEC_PER_SEC))
			let time = dispatch_time(DISPATCH_TIME_NOW, nanoSeconds)
			dispatch_after(time, queue, _chainingBlock)
		}
		// Create a new block (Qos Class) from block to allow adding a notification to it later (see Async)
		// Create block with the "inherit" type
		let _chainingWrapperBlock = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, chainingWrapperBlock)
		// Add block to queue *after* previous block is finished
		dispatch_block_notify(self.block, queue, _chainingWrapperBlock)
		// Wrap block in a struct since dispatch_block_t can't be extended
		return Async(_chainingBlock)
	}
	public func main(#after: Double, block: dispatch_block_t) -> Async {
		return self.after(after, block: block, runInQueue: GCD.mainQueue())
	}
	public func userInteractive(#after: Double, block: dispatch_block_t) -> Async {
		return self.after(after, block: block, runInQueue: GCD.userInteractiveQueue())
	}
	public func userInitiated(#after: Double, block: dispatch_block_t) -> Async {
		return self.after(after, block: block, runInQueue: GCD.userInitiatedQueue())
	}
	func utility(#after: Double, block: dispatch_block_t) -> Async {
		return self.after(after, block: block, runInQueue: GCD.utilityQueue())
	}
	public func background(#after: Double, block: dispatch_block_t) -> Async {
		return self.after(after, block: block, runInQueue: GCD.backgroundQueue())
	}
	public func customQueue(#after: Double, queue: dispatch_queue_t, block: dispatch_block_t) -> Async {
		return self.after(after, block: block, runInQueue: queue)
	}


	/* cancel */

	func cancel() {
		dispatch_block_cancel(block)
	}
	

	/* wait */

	/// If optional parameter forSeconds is not provided, use DISPATCH_TIME_FOREVER
	func wait(seconds: Double = 0.0) {
		if seconds != 0.0 {
			let nanoSeconds = Int64(seconds * Double(NSEC_PER_SEC))
			let time = dispatch_time(DISPATCH_TIME_NOW, nanoSeconds)
			dispatch_block_wait(block, time)
		} else {
			dispatch_block_wait(block, DISPATCH_TIME_FOREVER)
		}
	}
}


public class AsyncIO<A, R> {
    
    private var block: dispatch_block_t?
    
    private typealias ReturnType = R
    private typealias ArgumentType = A
    
    private var _arguments: ArgumentType?
    private var _return: ReturnType?
    
    private func boost(block inBlock: A -> R, arguments: A) {
        _arguments = arguments
        
        let voidInOutBlock: () -> () = {
            if let arguments = self._arguments {
                self._return = inBlock(arguments)
                println(": \(self._return)")
            } else {
                println("| \(arguments)")
                self._return = nil
            }
        }
        // Create a new block (Qos Class) from block to allow adding a notification to it later (see matching regular Async methods)
        // Create block with the "inherit" type
        let cancellableVoidInOutBlock = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, voidInOutBlock)
        
        self.block = cancellableVoidInOutBlock
    }
    
    private func boost<T>(block inBlock: A -> R, chainTo: AsyncIO<T, ArgumentType>) {
        
        let voidInOutBlock: () -> () = {
            let returnFromPrevious = chainTo._return
            self._arguments = returnFromPrevious
            
            if let arguments = self._arguments {
                self._return = inBlock(arguments)
                println(": \(self._return)")
            } else {
                assert(false, "No return value from previous")
            }
        }
        // Create a new block (Qos Class) from block to allow adding a notification to it later (see matching regular Async methods)
        // Create block with the "inherit" type
        let cancellableVoidInOutBlock = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, voidInOutBlock)
        
        self.block = cancellableVoidInOutBlock
    }
    
    private func boost<T>(block inBlock: A -> R, chainTo: AsyncO<ArgumentType>) {
        
        let voidInOutBlock: () -> () = {
            let returnFromPrevious = chainTo._return
            self._arguments = returnFromPrevious
            
            if let arguments = self._arguments {
                self._return = inBlock(arguments)
                println(": \(self._return)")
            } else {
                assert(false, "No return value from previous")
            }
        }
        // Create a new block (Qos Class) from block to allow adding a notification to it later (see matching regular Async methods)
        // Create block with the "inherit" type
        let cancellableVoidInOutBlock = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, voidInOutBlock)
        
        self.block = cancellableVoidInOutBlock
    }
    
    /* dispatch_async() */
    
    private class func async<A, R>(block: A -> R, inQueue queue: dispatch_queue_t, arguments: A) -> AsyncIO<A, R> {
        
        let async = AsyncIO<A, R>()
        async.boost(block: block, arguments: arguments)
        // Add block to queue
        dispatch_async(queue, async.block)

        return async
    }
    
    public class func main(arguments: A, block: A -> R) -> AsyncIO<A, R> {
        return AsyncIO.async(block, inQueue: GCD.mainQueue(), arguments: arguments)
    }
    
//    public class func main(block:() -> R) -> AsyncIO<(), R> {
//        return AsyncIO.async(block, inQueue: GCD.mainQueue(), arguments: ())
//    }

    
    /* Chaining */
    
    private func chain<T>(block chainingBlock: ReturnType -> T, runInQueue queue: dispatch_queue_t) -> AsyncIO<ReturnType, T> {
        
        let async = AsyncIO<ReturnType, T>()
        async.boost(block: chainingBlock, chainTo: self)
        // Add block to queue
        dispatch_async(queue, async.block)
        
        return async
    }
    
    public func main<T>(chainingBlock: ReturnType -> T) -> AsyncIO<ReturnType, T> {
        return chain(block: chainingBlock, runInQueue: GCD.mainQueue())
    }
}


public class AsyncO<R> {
    
    private var block: dispatch_block_t?
    
    private typealias ReturnType = R
    
    private var _return: ReturnType?
    
    private func boost(block inBlock: () -> R) {
        
        let voidInOutBlock: () -> () = {
            self._return = inBlock()
        }
        // Create a new block (Qos Class) from block to allow adding a notification to it later (see matching regular Async methods)
        // Create block with the "inherit" type
        let cancellableVoidInOutBlock = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, voidInOutBlock)
        
        self.block = cancellableVoidInOutBlock
    }
    
    private func boost(block inBlock: () -> R, chainTo: Async) {
        
        let voidInOutBlock: () -> () = {
            
            self._return = inBlock()
        }
        // Create a new block (Qos Class) from block to allow adding a notification to it later (see matching regular Async methods)
        // Create block with the "inherit" type
        let cancellableVoidInOutBlock = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, voidInOutBlock)
        
        self.block = cancellableVoidInOutBlock
    }
    
    /* dispatch_async() */
    
    private class func async<R>(block: () -> R, inQueue queue: dispatch_queue_t) -> AsyncO<R> {
        
        let async = AsyncO<R>()
        async.boost(block: block)
        // Add block to queue
        dispatch_async(queue, async.block)
        
        return async
    }
    
    public class func main(block: () -> R) -> AsyncO<R> {
        return AsyncO.async(block, inQueue: GCD.mainQueue())
    }
    
    
    /* Chaining */
    
    private func chain<T>(block chainingBlock: ReturnType -> T, runInQueue queue: dispatch_queue_t) -> AsyncIO<ReturnType, T> {
        
        let async = AsyncIO<ReturnType, T>()
        async.boost(block: chainingBlock, chainTo: self)
        // Add block to queue
        dispatch_async(queue, async.block)
        
        return async
    }
    
    public func main<T>(chainingBlock: ReturnType -> T) -> AsyncIO<ReturnType, T> {
        return chain(block: chainingBlock, runInQueue: GCD.mainQueue())
    }
}




// Convenience
extension qos_class_t {

	// Calculated property
	var description: String {
		get {
			switch self.id {
				case qos_class_main().id: return "Main"
				case QOS_CLASS_USER_INTERACTIVE.id: return "User Interactive"
				case QOS_CLASS_USER_INITIATED.id: return "User Initiated"
				case QOS_CLASS_DEFAULT.id: return "Default"
				case QOS_CLASS_UTILITY.id: return "Utility"
				case QOS_CLASS_BACKGROUND.id: return "Background"
				case QOS_CLASS_UNSPECIFIED.id: return "Unspecified"
				default: return "Unknown"
			}
		}
	}
}