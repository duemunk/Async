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


// MARK: - DSL for GCD queues

/**
 `GCD` is an empty struct with convenience static functions to get `dispatch_queue_t` of different quality of service classes, as provided by `dispatch_get_global_queue`.
 
 let utilityQueue = GCD.utilityQueue()
 
 - SeeAlso: Grand Central Dispatch
 */
private struct GCD {
    
    /**
     Convenience function for `dispatch_get_main_queue()`.
     Returns the default queue that is bound to the main thread.
     
     - Returns: The main queue. This queue is created automatically on behalf of the main thread before main() is called.
     
     - SeeAlso: dispatch_get_main_queue
     */
    static func mainQueue() -> dispatch_queue_t {
        return dispatch_get_main_queue()
        // Don't ever use dispatch_get_global_queue(qos_class_main(), 0) re https://gist.github.com/duemunk/34babc7ca8150ff81844
    }
    
    /**
     Convenience function for dispatch_get_global_queue, with the parameter QOS_CLASS_USER_INTERACTIVE
     Returns a system-defined global concurrent queue with the specified quality of service class.
     
     - Returns: The global concurrent queue with quality of service class QOS_CLASS_USER_INTERACTIVE.
     
     - SeeAlso: dispatch_get_global_queue
     */
    static func userInteractiveQueue() -> dispatch_queue_t {
        return dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)
    }
    
    /**
     Convenience function for dispatch_get_global_queue, with the parameter QOS_CLASS_USER_INITIATED
     Returns a system-defined global concurrent queue with the specified quality of service class.
     
     - Returns: The global concurrent queue with quality of service class QOS_CLASS_USER_INITIATED.
     
     - SeeAlso: dispatch_get_global_queue
     */
    static func userInitiatedQueue() -> dispatch_queue_t {
        return dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
    }
    
    /**
     Convenience function for dispatch_get_global_queue, with the parameter QOS_CLASS_UTILITY
     Returns a system-defined global concurrent queue with the specified quality of service class.
     
     - Returns: The global concurrent queue with quality of service class QOS_CLASS_UTILITY.
     
     - SeeAlso: dispatch_get_global_queue
     */
    static func utilityQueue() -> dispatch_queue_t {
        return dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
    }
    
    /**
     Convenience function for dispatch_get_global_queue, with the parameter QOS_CLASS_BACKGROUND
     Returns a system-defined global concurrent queue with the specified quality of service class.
     
     - Returns: The global concurrent queue with quality of service class QOS_CLASS_BACKGROUND.
     
     - SeeAlso: dispatch_get_global_queue
     */
    static func backgroundQueue() -> dispatch_queue_t {
        return dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
    }
}


//MARK: Reference - Class

/**
 The **Reference** class is used to enable returns values from blocks
 */
private class Reference<T> {
    var value: T?
}

// MARK: - Async – Struct

/**
 The **Async** struct is the main part of the Async.framework. Handles a internally `dispatch_block_t`.
 
 Chainable dispatch blocks with GCD:
 
 Async.background {
 // Run on background queue
 }.main {
 // Run on main queue, after the previous block
 }
 
 All moderns queue classes:
 
 Async.main {}
 Async.userInteractive {}
 Async.userInitiated {}
 Async.utility {}
 Async.background {}
 
 Custom queues:
 
 let customQueue = dispatch_queue_create("Label", DISPATCH_QUEUE_CONCURRENT)
 Async.customQueue(customQueue) {}
 
 Dispatch block after delay:
 
 let seconds = 0.5
 Async.main(after: seconds) {}
 
 Cancel blocks not yet dispatched
 
 let block1 = Async.background {
 // Some work
 }
 let block2 = block1.background {
 // Some other work
 }
 Async.main {
 // Cancel async to allow block1 to begin
 block1.cancel() // First block is NOT cancelled
 block2.cancel() // Second block IS cancelled
 }
 
 Wait for block to finish:
 
 let block = Async.background {
 // Do stuff
 }
 // Do other stuff
 // Wait for "Do stuff" to finish
 block.wait()
 // Do rest of stuff
 
 - SeeAlso: Grand Central Dispatch
 */
public typealias Async = Async2<Void, Void>

public struct Async2<In, Out> {
    
    typealias EmptyType = Void
    
    // MARK: - Private properties and init
    
    /**
     Private property to hold internally on to a `dispatch_block_t`
     */
    private let block: dispatch_block_t
    
    /**
     Private init that takes a `dispatch_block_t`
     */
    private init(_ block: dispatch_block_t, parameter: Reference<In>? = nil, result: Reference<Out> = Reference()) {
        self.block = block
        self.parameter = parameter
        self.result = result
    }
    
    /**
     Private parameter is the reference to the previous result of the previous block
     */
    private let parameter: Reference<In>?
    
    /**
     Private result is the reference of the result of this block. It can be used to pass the result of this block to the next block on the chain
     */
    private let result: Reference<Out>
    
    
    // MARK: - Static methods
    
    /**
     Sends the a block to be run asynchronously on the main thread.
     
     - parameters:
     - after: After how many seconds the block should be run.
     - block: The block that is to be passed to be run on the main queue
     
     - returns: An `Async` struct
     
     - SeeAlso: Has parity with non-static method
     */
    public static func main<R>(after after: Double? = nil, block: ()->R) -> Async2<Void, R> {
        return Async2.async(after, block: block, queue: GCD.mainQueue())
    }
    
    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_USER_INTERACTIVE.
     
     - parameters:
     - after: After how many seconds the block should be run.
     - block: The block that is to be passed to be run on the queue
     
     - returns: An `Async` struct
     
     - SeeAlso: Has parity with non-static method
     */
    public static func userInteractive<R>(after after: Double? = nil, block: () -> R) -> Async2<Void, R> {
        return Async2.async(after, block: block, queue: GCD.userInteractiveQueue())
    }
    
    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_USER_INITIATED.
     
     - parameters:
     - after: After how many seconds the block should be run.
     - block: The block that is to be passed to be run on the queue
     
     - returns: An `Async` struct
     
     - SeeAlso: Has parity with non-static method
     */
    public static func userInitiated<R>(after after: Double? = nil, block: () -> R) -> Async2<Void, R> {
        return Async2.async(after, block: block, queue: GCD.userInitiatedQueue())
    }
    
    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_UTILITY.
     
     - parameters:
     - after: After how many seconds the block should be run.
     - block: The block that is to be passed to be run on queue
     
     - returns: An `Async` struct
     
     - SeeAlso: Has parity with non-static method
     */
    public static func utility<R>(after after: Double? = nil, block: () -> R) -> Async2<Void, R> {
        return Async2.async(after, block: block, queue: GCD.utilityQueue())
    }

    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_BACKGROUND.
     
     - parameters:
     - after: After how many seconds the block should be run.
     - block: The block that is to be passed to be run on the queue
     
     - returns: An `Async` struct
     
     - SeeAlso: Has parity with non-static method
     */
    public static func background<R>(after after: Double? = nil, block: () -> R) -> Async2<Void, R> {
        return Async2.async(after, block: block, queue: GCD.backgroundQueue())
    }
    
    /**
     Sends the a block to be run asynchronously on a custom queue.
     
     - parameters:
     - after: After how many seconds the block should be run.
     - block: The block that is to be passed to be run on the queue
     
     - returns: An `Async` struct
     
     - SeeAlso: Has parity with non-static method
     */
    public static func customQueue<R>(queue: dispatch_queue_t, after: Double? = nil, block: () -> R) -> Async2<Void, R> {
        return Async2.async(after, block: block, queue: queue)
    }
    
    // MARK: - Private static methods
    
    /**
     Convenience for `asyncNow()` or `asyncAfter()` depending on if the parameter `seconds` is passed or nil.
     
     - parameters:
     - seconds: After how many seconds the block should be run.
     - block: The block that is to be passed to be run on the `queue`
     - queue: The queue on which the `block` is run.
     
     - returns: An `Async` struct which encapsulates the `dispatch_block_t`
     */
    private static func async<R>(seconds: Double? = nil, block chainingBlock: () -> R, queue: dispatch_queue_t) -> Async2<Void, R> {
        if let seconds = seconds {
            return asyncAfter(seconds, block: chainingBlock, queue: queue)
        }
        return asyncNow(chainingBlock, queue: queue)
    }

    /**
     Convenience for dispatch_async(). Encapsulates the block in a "true" GCD block using DISPATCH_BLOCK_INHERIT_QOS_CLASS.
     
     - parameters:
     - block: The block that is to be passed to be run on the `queue`
     - queue: The queue on which the `block` is run.
     
     - returns: An `Async` struct which encapsulates the `dispatch_block_t`
     */
    private static func asyncNow<R>(block: () -> R, queue: dispatch_queue_t) -> Async2<Void, R> {
        // Create a new block (Qos Class) from block to allow adding a notification to it later (see matching regular Async methods)
        // Create block with the "inherit" type
        
        let resultReference = Reference<R>()
        
        let executionBlock = {
            let result = block()
            resultReference.value = result
        }
        
        let _block = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, executionBlock)
        // Add block to queue
        dispatch_async(queue, _block)
        // Wrap block in a struct since dispatch_block_t can't be extended
        return Async2<Void, R>(_block, parameter: nil, result: resultReference)
    }
    
    /**
     Convenience for dispatch_after(). Encapsulates the block in a "true" GCD block using DISPATCH_BLOCK_INHERIT_QOS_CLASS.
     
     - parameters:
     - seconds: After how many seconds the block should be run.
     - block: The block that is to be passed to be run on the `queue`
     - queue: The queue on which the `block` is run.
     
     - returns: An `Async` struct which encapsulates the `dispatch_block_t`
     */
    private static func asyncAfter<R>(seconds: Double, block: () -> R, queue: dispatch_queue_t) -> Async2<Void, R> {
        let nanoSeconds = Int64(seconds * Double(NSEC_PER_SEC))
        let time = dispatch_time(DISPATCH_TIME_NOW, nanoSeconds)
        return at(time, block: block, queue: queue)
    }
    
    /**
     Convenience for dispatch_after(). Encapsulates the block in a "true" GCD block using DISPATCH_BLOCK_INHERIT_QOS_CLASS.
     
     - parameters:
     - time: The specific time (`dispatch_time_t`) the block should be run.
     - block: The block that is to be passed to be run on the `queue`
     - queue: The queue on which the `block` is run.
     
     - returns: An `Async` struct which encapsulates the `dispatch_block_t`
     */
    private static func at<R>(time: dispatch_time_t, block: () -> R, queue: dispatch_queue_t) -> Async2<Void, R> {
        let resultReference = Reference<R>()
        
        let executionBlock = {
            let result = block()
            resultReference.value = result
        }
        
        // See Async.async() for comments
        let _block = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, executionBlock)
        dispatch_after(time, queue, _block)
        return Async2<Void, R>(_block, parameter: nil, result: resultReference)
    }
    
    // MARK: - Instance methods (matches static ones)
    
    /**
     Sends the a block to be run asynchronously on the main thread, after the current block has finished.
     
     - parameters:
     - after: After how many seconds the block should be run.
     - block: The block that is to be passed to be run on the main queue
     
     - returns: An `Async` struct
     
     - SeeAlso: Has parity with static method
     */
    public func main<R>(after after: Double? = nil, chainingBlock: (Out)->(R)) -> Async2<Out, R> {
        return chain(after, block: chainingBlock, queue: GCD.mainQueue())
    }
    
    
    
    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_USER_INTERACTIVE, after the current block has finished.
     
     - parameters:
     - after: After how many seconds the block should be run.
     - block: The block that is to be passed to be run on the queue
     
     - returns: An `Async` struct
     
     - SeeAlso: Has parity with static method
     */
    public func userInteractive<R>(after after: Double? = nil, chainingBlock: (Out)->(R)) -> Async2<Out, R> {
        return chain(after, block: chainingBlock, queue: GCD.userInteractiveQueue())
    }
    
    
    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_USER_INITIATED, after the current block has finished.
     
     - parameters:
     - after: After how many seconds the block should be run.
     - block: The block that is to be passed to be run on the queue
     
     - returns: An `Async` struct
     
     - SeeAlso: Has parity with static method
     */
    public func userInitiated<R>(after after: Double? = nil, chainingBlock: (Out)->(R)) -> Async2<Out, R> {
        return chain(after, block: chainingBlock, queue: GCD.userInitiatedQueue())
    }
    
    
    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_UTILITY, after the current block has finished.
     
     - parameters:
     - after: After how many seconds the block should be run.
     - block: The block that is to be passed to be run on the queue
     
     - returns: An `Async` struct
     
     - SeeAlso: Has parity with static method
     */
    public func utility<R>(after after: Double? = nil, chainingBlock: (Out)->(R)) -> Async2<Out, R> {
        return chain(after, block: chainingBlock, queue: GCD.utilityQueue())
    }
    
    
    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_BACKGROUND, after the current block has finished.
     
     - parameters:
     - after: After how many seconds the block should be run.
     - block: The block that is to be passed to be run on the queue
     
     - returns: An `Async` struct
     
     - SeeAlso: Has parity with static method
     */
    public func background<R>(after after: Double? = nil, chainingBlock: (Out)->(R)) -> Async2<Out, R> {
        return chain(after, block: chainingBlock, queue: GCD.backgroundQueue())
    }
    
    
    /**
     Sends the a block to be run asynchronously on a custom queue, after the current block has finished.
     
     - parameters:
     - after: After how many seconds the block should be run.
     - block: The block that is to be passed to be run on the queue
     
     - returns: An `Async` struct
     
     - SeeAlso: Has parity with static method
     */
    public func customQueue<R>(queue: dispatch_queue_t, after: Double? = nil, chainingBlock: (Out)->(R)) -> Async2<Out, R> {
        return chain(after, block: chainingBlock, queue: queue)
    }
    
    // MARK: - Instance methods
    
    /**
     Convenience function to call `dispatch_block_cancel()` on the encapsulated block.
     Cancels the current block, if it hasn't already begun running to GCD.
     
     Usage:
     
     let block1 = Async.background {
     // Some work
     }
     let block2 = block1.background {
     // Some other work
     }
     Async.main {
     // Cancel async to allow block1 to begin
     block1.cancel() // First block is NOT cancelled
     block2.cancel() // Second block IS cancelled
     }
     
     */
    public func cancel() {
        dispatch_block_cancel(block)
    }
    
    
    /**
     Convenience function to call `dispatch_block_wait()` on the encapsulated block.
     Waits for the current block to finish, on any given thread.
     
     - parameters:
     - seconds: Max seconds to wait for block to finish. If value is 0.0, it uses DISPATCH_TIME_FOREVER. Default value is 0.
     
     - SeeAlso: dispatch_block_wait, DISPATCH_TIME_FOREVER
     */
    public func wait(seconds seconds: Double! = nil) {
        if seconds != nil {
            let nanoSeconds = Int64(seconds * Double(NSEC_PER_SEC))
            let time = dispatch_time(DISPATCH_TIME_NOW, nanoSeconds)
            dispatch_block_wait(block, time)
        } else {
            dispatch_block_wait(block, DISPATCH_TIME_FOREVER)
        }
    }
    
    // MARK: Private instance methods
    
    /**
     Convenience for `chainNow()` or `chainAfter()` depending on if the parameter `seconds` is passed or nil.
     
     - parameters:
     - seconds: After how many seconds the block should be run.
     - block: The block that is to be passed to be run on the `queue`
     - queue: The queue on which the `block` is run.
     
     - returns: An `Async` struct which encapsulates the `dispatch_block_t`, which is called when the current block has finished + any given amount of seconds.
     */
    private func chain<R>(seconds: Double? = nil, block chainingBlock: (Out)->(R), queue: dispatch_queue_t) -> Async2<Out, R>  {
        if let seconds = seconds {
            return chainAfter(seconds, block: chainingBlock, queue: queue)
        }
        return chainNow(block: chainingBlock, queue: queue)
    }
    
    
    /**
     Convenience for `dispatch_block_notify()` to
     
     - parameters:
     - block: The block that is to be passed to be run on the `queue`
     - queue: The queue on which the `block` is run.
     
     - returns: An `Async` struct which encapsulates the `dispatch_block_t`, which is called when the current block has finished.
     
     - SeeAlso: dispatch_block_notify, dispatch_block_create
     */
    private func chainNow<R>(block chainingBlock: (Out)->(R), queue: dispatch_queue_t) -> Async2<Out, R> {
        // See Async.async() for comments
        
        let resultReference = Reference<R>()
        
        let executionBlock = {
            let result = chainingBlock(self.result.value!)
            resultReference.value = result
        }
        
        let _chainingBlock = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, executionBlock)
        dispatch_block_notify(block, queue, _chainingBlock)
        return Async2<Out, R>(_chainingBlock, parameter: self.result, result: resultReference)
    }
    
    
    /**
     Convenience for dispatch_after(). Encapsulates the block in a "true" GCD block using DISPATCH_BLOCK_INHERIT_QOS_CLASS.
     
     - parameters:
     - seconds: After how many seconds the block should be run.
     - block: The block that is to be passed to be run on the `queue`
     - queue: The queue on which the `block` is run.
     
     - returns: An `Async` struct which encapsulates the `dispatch_block_t`, which is called when the current block has finished + the given amount of seconds.
     */
    private func chainAfter<R>(seconds: Double, block chainingBlock: (Out)->(R), queue: dispatch_queue_t) -> Async2<Out, R>  {
        let resultReference = Reference<R>()
        
        let executionBlock = {
            let result = chainingBlock(self.result.value!)
            resultReference.value = result
        }
        
        // Create a new block (Qos Class) from block to allow adding a notification to it later (see Async)
        // Create block with the "inherit" type
        let _chainingBlock = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, executionBlock)
        
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
        return Async2<Out, R>(_chainingBlock, parameter: self.result, result: resultReference)
    }
}


// MARK: - Apply - DSL for `dispatch_apply`

/**
 `Apply` is an empty struct with convenience static functions to parallelize a for-loop, as provided by `dispatch_apply`.
 
 Apply.background(100) { i in
 // Calls blocks in parallel
 }
 
 `Apply` runs a block multiple times, before returning. If you want run the block asynchronously from the current thread, wrap it in an `Async` block:
 
 Async.background {
 Apply.background(100) { i in
 // Calls blocks in parallel asynchronously
 }
 }
 
 - SeeAlso: Grand Central Dispatch, dispatch_apply
 */
public struct Apply {
    
    /**
     Block is run any given amount of times on a queue with a quality of service of QOS_CLASS_USER_INTERACTIVE. The block is being passed an index parameter.
     
     - parameters:
     - iterations: How many times the block should be run. Index provided to block goes from `0..<iterations`
     - block: The block that is to be passed to be run on a .
     */
    public static func userInteractive(iterations: Int, block: Int -> ()) {
        dispatch_apply(iterations, GCD.userInteractiveQueue(), block)
    }
    
    /**
     Block is run any given amount of times on a queue with a quality of service of QOS_CLASS_USER_INITIATED. The block is being passed an index parameter.
     
     - parameters:
     - iterations: How many times the block should be run. Index provided to block goes from `0..<iterations`
     - block: The block that is to be passed to be run on a .
     */
    public static func userInitiated(iterations: Int, block: Int -> ()) {
        dispatch_apply(iterations, GCD.userInitiatedQueue(), block)
    }
    
    /**
     Block is run any given amount of times on a queue with a quality of service of QOS_CLASS_UTILITY. The block is being passed an index parameter.
     
     - parameters:
     - iterations: How many times the block should be run. Index provided to block goes from `0..<iterations`
     - block: The block that is to be passed to be run on a .
     */
    public static func utility(iterations: Int, block: Int -> ()) {
        dispatch_apply(iterations, GCD.utilityQueue(), block)
    }
    
    /**
     Block is run any given amount of times on a queue with a quality of service of QOS_CLASS_BACKGROUND. The block is being passed an index parameter.
     
     - parameters:
     - iterations: How many times the block should be run. Index provided to block goes from `0..<iterations`
     - block: The block that is to be passed to be run on a .
     */
    public static func background(iterations: Int, block: Int -> ()) {
        dispatch_apply(iterations, GCD.backgroundQueue(), block)
    }
    
    /**
     Block is run any given amount of times on a custom queue. The block is being passed an index parameter.
     
     - parameters:
     - iterations: How many times the block should be run. Index provided to block goes from `0..<iterations`
     - block: The block that is to be passed to be run on a .
     */
    public static func customQueue(iterations: Int, queue: dispatch_queue_t, block: Int -> ()) {
        dispatch_apply(iterations, queue, block)
    }
}


// MARK: - AsyncGroup – Struct

/**
 The **AsyncGroup** struct facilitates working with groups of asynchronous blocks. Handles a internally `dispatch_group_t`.
 
 Multiple dispatch blocks with GCD:
 
 let group = AsyncGroup()
 group.background {
 // Run on background queue
 }
 group.utility {
 // Run on untility queue, after the previous block
 }
 group.wait()
 
 All moderns queue classes:
 
 group.main {}
 group.userInteractive {}
 group.userInitiated {}
 group.utility {}
 group.background {}
 
 Custom queues:
 
 let customQueue = dispatch_queue_create("Label", DISPATCH_QUEUE_CONCURRENT)
 group.customQueue(customQueue) {}
 
 Wait for group to finish:
 
 let group = AsyncGroup()
 group.background {
 // Do stuff
 }
 group.background {
 // Do other stuff in parallel
 }
 // Wait for both to finish
 group.wait()
 // Do rest of stuff
 
 - SeeAlso: Grand Central Dispatch
 */
public struct AsyncGroup {
    
    // MARK: - Private properties and init
    
    /**
     Private property to hold internally on to a `dispatch_group_t`
     */
    var group: dispatch_group_t
    
    /**
     Private init that takes a `dispatch_group_t`
     */
    public init() {
        group = dispatch_group_create()
    }
    
    
    /**
     Convenience for `dispatch_group_async()`
     
     - parameters:
     - block: The block that is to be passed to be run on the `queue`
     - queue: The queue on which the `block` is run.
     
     - SeeAlso: dispatch_group_async, dispatch_group_create
     */
    private func async(block block: dispatch_block_t, queue: dispatch_queue_t) {
        dispatch_group_async(group, queue, block)
    }
    
    /**
     Convenience for `dispatch_group_enter()`. Used to add custom blocks to the current group.
     
     - SeeAlso: dispatch_group_enter, dispatch_group_leave
     */
    public func enter() {
        dispatch_group_enter(group)
    }
    
    /**
     Convenience for `dispatch_group_leave()`. Used to flag a custom added block is complete.
     
     - SeeAlso: dispatch_group_enter, dispatch_group_leave
     */
    public func leave() {
        dispatch_group_leave(group)
    }
    
    
    // MARK: - Instance methods
    
    /**
     Sends the a block to be run asynchronously on the main thread, in the current group.
     
     - parameters:
     - block: The block that is to be passed to be run on the main queue
     */
    public func main(block: dispatch_block_t) {
        async(block: block, queue: GCD.mainQueue())
    }
    
    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_USER_INTERACTIVE, in the current group.
     
     - parameters:
     - block: The block that is to be passed to be run on the queue
     */
    public func userInteractive(block: dispatch_block_t) {
        async(block: block, queue: GCD.userInteractiveQueue())
    }
    
    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_USER_INITIATED, in the current group.
     
     - parameters:
     - block: The block that is to be passed to be run on the queue
     */
    public func userInitiated(block: dispatch_block_t) {
        async(block: block, queue: GCD.userInitiatedQueue())
    }
    
    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of
     QOS_CLASS_UTILITY, in the current block.
     
     - parameters:
     - block: The block that is to be passed to be run on the queue
     */
    public func utility(block: dispatch_block_t) {
        async(block: block, queue: GCD.utilityQueue())
    }
    
    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_BACKGROUND, in the current block.
     
     - parameters:
     - block: The block that is to be passed to be run on the queue
     */
    public func background(block: dispatch_block_t) {
        async(block: block, queue: GCD.backgroundQueue())
    }
    
    /**
     Sends the a block to be run asynchronously on a custom queue, in the current group.
     
     - parameters:
     - queue: Custom queue where the block will be run.
     - block: The block that is to be passed to be run on the queue
     */
    public func customQueue(queue: dispatch_queue_t, block: dispatch_block_t) {
        async(block: block, queue: queue)
    }
    
    /**
     Convenience function to call `dispatch_group_wait()` on the encapsulated block.
     Waits for the current group to finish, on any given thread.
     
     - parameters:
     - seconds: Max seconds to wait for block to finish. If value is nil, it uses DISPATCH_TIME_FOREVER. Default value is nil.
     
     - SeeAlso: dispatch_group_wait, DISPATCH_TIME_FOREVER
     */
    public func wait(seconds seconds: Double! = nil) {
        if seconds != nil {
            let nanoSeconds = Int64(seconds * Double(NSEC_PER_SEC))
            let time = dispatch_time(DISPATCH_TIME_NOW, nanoSeconds)
            dispatch_group_wait(group, time)
        } else {
            dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
        }
    }
    
}

// MARK: - Extension for `qos_class_t`

/**
 Extension to add description string for each quality of service class.
 */
public extension qos_class_t {
    
    /**
     Description of the `qos_class_t`. E.g. "Main", "User Interactive", etc. for the given Quality of Service class.
     */
    var description: String {
        get {
            switch self {
            case qos_class_main(): return "Main"
            case QOS_CLASS_USER_INTERACTIVE: return "User Interactive"
            case QOS_CLASS_USER_INITIATED: return "User Initiated"
            case QOS_CLASS_DEFAULT: return "Default"
            case QOS_CLASS_UTILITY: return "Utility"
            case QOS_CLASS_BACKGROUND: return "Background"
            case QOS_CLASS_UNSPECIFIED: return "Unspecified"
            default: return "Unknown"
            }
        }
    }
}
