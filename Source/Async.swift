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
 `GCD` is a convenience enum with cases to get `DispatchQueue` of different quality of service classes, as provided by `DispatchQueue.global` or `DispatchQueue` for main thread or a specific custom queue.

 let mainQueue = GCD.main
 let utilityQueue = GCD.utility
 let customQueue = GCD.custom(queue: aDispatchQueue)

 - SeeAlso: Grand Central Dispatch
 */
private enum GCD {
    case main, userInteractive, userInitiated, utility, background, custom(queue: DispatchQueue)

    var queue: DispatchQueue {
        switch self {
        case .main: return .main
        case .userInteractive: return .global(attributes: .qosUserInteractive)
        case .userInitiated: return .global(attributes: .qosUserInitiated)
        case .utility: return .global(attributes: .qosUtility)
        case .background: return .global(attributes: .qosBackground)
        case .custom(let queue): return queue
        }
    }
}



// MARK: - Async – Struct

/**
The **Async** struct is the main part of the Async.framework. Handles an internally `@convention(block) () -> Swift.Void`.

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
public struct Async {


    // MARK: - Private properties and init

    /**
     Private property to hold internally on to a `@convention(block) () -> Swift.Void`
    */
    private let block: DispatchWorkItem

    /**
     Private init that takes a `@convention(block) () -> Swift.Void`
     */
    private init(_ block: DispatchWorkItem) {
        self.block = block
    }


    // MARK: - Static methods

    /**
    Sends the a block to be run asynchronously on the main thread.

    - parameters:
        - after: After how many seconds the block should be run.
        - block: The block that is to be passed to be run on the main queue

    - returns: An `Async` struct

    - SeeAlso: Has parity with non-static method
    */
    @discardableResult
    public static func main(after seconds: Double? = nil, block: @convention(block) () -> Swift.Void) -> Async {
        return Async.async(after: seconds, block: block, queue: .main)
    }

    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_USER_INTERACTIVE.

     - parameters:
        - after: After how many seconds the block should be run.
        - block: The block that is to be passed to be run on the queue

     - returns: An `Async` struct

     - SeeAlso: Has parity with non-static method
     */
    @discardableResult
    public static func userInteractive(after seconds: Double? = nil, block: @convention(block) () -> Swift.Void) -> Async {
        return Async.async(after: seconds, block: block, queue: .userInteractive)
    }

    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_USER_INITIATED.

     - parameters:
        - after: After how many seconds the block should be run.
        - block: The block that is to be passed to be run on the queue

     - returns: An `Async` struct

     - SeeAlso: Has parity with non-static method
     */
    @discardableResult
    public static func userInitiated(after seconds: Double? = nil, block: @convention(block) () -> Swift.Void) -> Async {
        return Async.async(after: seconds, block: block, queue: .userInitiated)
    }

    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_UTILITY.

     - parameters:
        - after: After how many seconds the block should be run.
        - block: The block that is to be passed to be run on queue

     - returns: An `Async` struct

     - SeeAlso: Has parity with non-static method
     */
    @discardableResult
    public static func utility(after seconds: Double? = nil, block: @convention(block) () -> Swift.Void) -> Async {
        return Async.async(after: seconds, block: block, queue: .utility)
    }

    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_BACKGROUND.

     - parameters:
        - after: After how many seconds the block should be run.
        - block: The block that is to be passed to be run on the queue

     - returns: An `Async` struct

     - SeeAlso: Has parity with non-static method
     */
    @discardableResult
    public static func background(after seconds: Double? = nil, block: @convention(block) () -> Swift.Void) -> Async {
        return Async.async(after: seconds, block: block, queue: .background)
    }

    /**
     Sends the a block to be run asynchronously on a custom queue.

     - parameters:
        - after: After how many seconds the block should be run.
        - block: The block that is to be passed to be run on the queue

     - returns: An `Async` struct

     - SeeAlso: Has parity with non-static method
     */
    @discardableResult
    public static func custom(queue: DispatchQueue, after seconds: Double? = nil, block: @convention(block) () -> Swift.Void) -> Async {
        return Async.async(after: seconds, block: block, queue: .custom(queue: queue))
    }


    // MARK: - Private static methods

    /**
     Convenience for dispatch_async(). Encapsulates the block in a "true" GCD block using DISPATCH_BLOCK_INHERIT_QOS_CLASS.

     - parameters:
         - block: The block that is to be passed to be run on the `queue`
         - queue: The queue on which the `block` is run.

     - returns: An `Async` struct which encapsulates the `@convention(block) () -> Swift.Void`
     */
    private static func async(after seconds: Double? = nil, block: @convention(block) () -> Swift.Void, queue: GCD) -> Async {
        let dispatchWorkItem = DispatchWorkItem(block: block)

        if let seconds = seconds {
            let time = DispatchTime.now() + seconds
            queue.queue.after(when: time, execute: dispatchWorkItem)
        } else {
            queue.queue.async(execute: dispatchWorkItem)
        }

        // Wrap block in a struct since @convention(block) () -> Swift.Void can't be extended
        return Async(dispatchWorkItem)
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
    @discardableResult
    public func main(after seconds: Double? = nil, chainingBlock: @convention(block) () -> Swift.Void) -> Async {
        return chain(after: seconds, block: chainingBlock, queue: .main)
    }

    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_USER_INTERACTIVE, after the current block has finished.

     - parameters:
         - after: After how many seconds the block should be run.
         - block: The block that is to be passed to be run on the queue

     - returns: An `Async` struct

     - SeeAlso: Has parity with static method
     */
    @discardableResult
    public func userInteractive(after seconds: Double? = nil, chainingBlock: @convention(block) () -> Swift.Void) -> Async {
        return chain(after: seconds, block: chainingBlock, queue: .userInteractive)
    }

    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_USER_INITIATED, after the current block has finished.

     - parameters:
         - after: After how many seconds the block should be run.
         - block: The block that is to be passed to be run on the queue

     - returns: An `Async` struct

     - SeeAlso: Has parity with static method
     */
    @discardableResult
    public func userInitiated(after seconds: Double? = nil, chainingBlock: @convention(block) () -> Swift.Void) -> Async {
        return chain(after: seconds, block: chainingBlock, queue: .userInitiated)
    }

    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_UTILITY, after the current block has finished.

     - parameters:
         - after: After how many seconds the block should be run.
         - block: The block that is to be passed to be run on the queue

     - returns: An `Async` struct

     - SeeAlso: Has parity with static method
     */
    @discardableResult
    public func utility(after seconds: Double? = nil, chainingBlock: @convention(block) () -> Swift.Void) -> Async {
        return chain(after: seconds, block: chainingBlock, queue: .utility)
    }

    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_BACKGROUND, after the current block has finished.

     - parameters:
         - after: After how many seconds the block should be run.
         - block: The block that is to be passed to be run on the queue

     - returns: An `Async` struct

     - SeeAlso: Has parity with static method
     */
    @discardableResult
    public func background(after seconds: Double? = nil, chainingBlock: @convention(block) () -> Swift.Void) -> Async {
        return chain(after: seconds, block: chainingBlock, queue: .background)
    }

    /**
     Sends the a block to be run asynchronously on a custom queue, after the current block has finished.

     - parameters:
         - after: After how many seconds the block should be run.
         - block: The block that is to be passed to be run on the queue

     - returns: An `Async` struct

     - SeeAlso: Has parity with static method
     */
    @discardableResult
    public func custom(queue: DispatchQueue, after seconds: Double? = nil, chainingBlock: @convention(block) () -> Swift.Void) -> Async {
        return chain(after: seconds, block: chainingBlock, queue: .custom(queue: queue))
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
        block.cancel()
    }


    /**
     Convenience function to call `dispatch_block_wait()` on the encapsulated block.
     Waits for the current block to finish, on any given thread.

     - parameters:
        - seconds: Max seconds to wait for block to finish. If value is 0.0, it uses DISPATCH_TIME_FOREVER. Default value is 0.

     - SeeAlso: dispatch_block_wait, DISPATCH_TIME_FOREVER
     */
    @discardableResult
    public func wait(seconds: Double? = nil) -> DispatchTimeoutResult {
        let timeout = seconds
            .flatMap { DispatchTime.now() + $0 }
            ?? .distantFuture
        return block.wait(timeout: timeout)
    }


    // MARK: Private instance methods

    /**
     Convenience for `dispatch_block_notify()` to

     - parameters:
         - block: The block that is to be passed to be run on the `queue`
         - queue: The queue on which the `block` is run.

     - returns: An `Async` struct which encapsulates the `@convention(block) () -> Swift.Void`, which is called when the current block has finished.

     - SeeAlso: dispatch_block_notify, dispatch_block_create
     */
    private func chain(after seconds: Double? = nil, block chainingBlock: @convention(block) () -> Swift.Void, queue: GCD) -> Async {
        let dispatchWorkItem = DispatchWorkItem(block: chainingBlock)

        if let seconds = seconds {
            block.notify(queue: DispatchQueue.main) {
                let time = DispatchTime.now() + seconds
                queue.queue.after(when: time, execute: dispatchWorkItem)
            }
        } else {
            block.notify(queue: DispatchQueue.main) {
                queue.queue.async(execute: dispatchWorkItem)
            }
        }

        // See Async.async() for comments
        return Async(dispatchWorkItem)
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
    public static func userInteractive(_ iterations: Int, block: (Int) -> ()) {
//        let dispatchWorkItem = DispatchWorkItem(qos: .userInteractive, block: block)
//        DispatchQueue.concurrentPerform(iterations: iterations, execute: dispatchWorkItem)
        // TODO: Find workable API for apply on non-main queue
        DispatchQueue.concurrentPerform(iterations: iterations, execute: block)
    }

    /**
     Block is run any given amount of times on a queue with a quality of service of QOS_CLASS_USER_INITIATED. The block is being passed an index parameter.

     - parameters:
         - iterations: How many times the block should be run. Index provided to block goes from `0..<iterations`
         - block: The block that is to be passed to be run on a .
     */
    public static func userInitiated(_ iterations: Int, block: (Int) -> ()) {
        DispatchQueue.concurrentPerform(iterations: iterations, execute: block)
    }

    /**
     Block is run any given amount of times on a queue with a quality of service of QOS_CLASS_UTILITY. The block is being passed an index parameter.

     - parameters:
         - iterations: How many times the block should be run. Index provided to block goes from `0..<iterations`
         - block: The block that is to be passed to be run on a .
     */
    public static func utility(_ iterations: Int, block: (Int) -> ()) {
        DispatchQueue.concurrentPerform(iterations: iterations, execute: block)
    }

    /**
     Block is run any given amount of times on a queue with a quality of service of QOS_CLASS_BACKGROUND. The block is being passed an index parameter.

     - parameters:
         - iterations: How many times the block should be run. Index provided to block goes from `0..<iterations`
         - block: The block that is to be passed to be run on a .
     */
    public static func background(_ iterations: Int, block: (Int) -> ()) {
        DispatchQueue.concurrentPerform(iterations: iterations, execute: block)
    }

    /**
     Block is run any given amount of times on a custom queue. The block is being passed an index parameter.

     - parameters:
         - iterations: How many times the block should be run. Index provided to block goes from `0..<iterations`
         - block: The block that is to be passed to be run on a .
     */
    public static func custom(queue: DispatchQueue, iterations: Int, block: (Int) -> ()) {
        DispatchQueue.concurrentPerform(iterations: iterations, execute: block)
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
     Private property to internally on to a `dispatch_group_t`
    */
    private var group: DispatchGroup

    /**
     Private init that takes a `dispatch_group_t`
     */
    public init() {
        group = DispatchGroup()
    }


    /**
     Convenience for `dispatch_group_async()`

     - parameters:
         - block: The block that is to be passed to be run on the `queue`
         - queue: The queue on which the `block` is run.

     - SeeAlso: dispatch_group_async, dispatch_group_create
     */
    private func async(block: @convention(block) () -> Swift.Void, queue: GCD) {
        queue.queue.async(group: group, execute: block)
    }

    /**
     Convenience for `dispatch_group_enter()`. Used to add custom blocks to the current group.

     - SeeAlso: dispatch_group_enter, dispatch_group_leave
     */
    public func enter() {
        group.enter()
    }

    /**
     Convenience for `dispatch_group_leave()`. Used to flag a custom added block is complete.

     - SeeAlso: dispatch_group_enter, dispatch_group_leave
     */
    public func leave() {
        group.leave()
    }


    // MARK: - Instance methods

    /**
    Sends the a block to be run asynchronously on the main thread, in the current group.

    - parameters:
        - block: The block that is to be passed to be run on the main queue
    */
    public func main(_ block: @convention(block) () -> Swift.Void) {
        async(block: block, queue: .main)
    }

    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_USER_INTERACTIVE, in the current group.

     - parameters:
        - block: The block that is to be passed to be run on the queue
     */
    public func userInteractive(_ block: @convention(block) () -> Swift.Void) {
        async(block: block, queue: .userInteractive)
    }

    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_USER_INITIATED, in the current group.

     - parameters:
        - block: The block that is to be passed to be run on the queue
     */
    public func userInitiated(_ block: @convention(block) () -> Swift.Void) {
        async(block: block, queue: .userInitiated)
    }

    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of 
        QOS_CLASS_UTILITY, in the current block.

     - parameters:
        - block: The block that is to be passed to be run on the queue
     */
    public func utility(_ block: @convention(block) () -> Swift.Void) {
        async(block: block, queue: .utility)
    }

    /**
     Sends the a block to be run asynchronously on a queue with a quality of service of QOS_CLASS_BACKGROUND, in the current block.

     - parameters:
         - block: The block that is to be passed to be run on the queue
     */
    public func background(_ block: @convention(block) () -> Swift.Void) {
        async(block: block, queue: .background)
    }

    /**
     Sends the a block to be run asynchronously on a custom queue, in the current group.

     - parameters:
         - queue: Custom queue where the block will be run.
         - block: The block that is to be passed to be run on the queue
     */
    public func custom(queue: DispatchQueue, block: @convention(block) () -> Swift.Void) {
        async(block: block, queue: .custom(queue: queue))
    }

    /**
     Convenience function to call `dispatch_group_wait()` on the encapsulated block.
     Waits for the current group to finish, on any given thread.

     - parameters:
         - seconds: Max seconds to wait for block to finish. If value is nil, it uses DISPATCH_TIME_FOREVER. Default value is nil.

     - SeeAlso: dispatch_group_wait, DISPATCH_TIME_FOREVER
     */
    @discardableResult
    public func wait(seconds: Double? = nil) -> DispatchTimeoutResult {
        if let seconds = seconds {
            let time = DispatchTime.now() + seconds
            return group.wait(timeout: time)
        } else {
            return group.wait(timeout: DispatchTime.distantFuture)
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


// MARK: - Extension for `DispatchQueue.GlobalAttributes`

/**
 Extension to add description string for each quality of service class.
 */
public extension DispatchQueue.GlobalAttributes {

    var description: String {
        get {
            switch self {
            case DispatchQueue.GlobalAttributes(rawValue: UInt64(qos_class_main().rawValue)): return "Main"
            case DispatchQueue.GlobalAttributes.qosUserInteractive: return "User Interactive"
            case DispatchQueue.GlobalAttributes.qosUserInitiated: return "User Initiated"
            case DispatchQueue.GlobalAttributes.qosDefault: return "Default"
            case DispatchQueue.GlobalAttributes.qosUtility: return "Utility"
            case DispatchQueue.GlobalAttributes.qosBackground: return "Background"
            default: return "Unknown"
            }
        }
    }
}
