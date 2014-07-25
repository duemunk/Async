Async
=====

Syntactic sugar in Swift for asynchronous dispatches in Grand Central Dispatch (GCD)

The familiar syntax for GCD is:
```swift
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
			println("This is run on the background queue")
			
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
				println("This is run on the main queue, after the previous block")
			})
		})
```

**Async** adds syntactic suger to this
```swift
Async.background {
  println("This is run on the background queue")
}.main {
  println("This is run on the main queue, after the previous block")
}
```

### Benefits
1. Less verbose code
2. Less code indentation

### Support
OS X 10.10+ and iOS 8.0+

### Examples
Support the modern queue classes
```swift
Async.main {}
Async.userInteractive {}
Async.userInitiated {}
Async.default_ {}
Async.utility {}
Async.background {}
```

Chain as many block as you want
```swift
Async.userInitiated {
  // 1
}.main {
  // 2
}.background {
  // 3
}.main {
  // 4
}
```

### How
The way it work is by using the new notifaction API for GCD introduced in OS X 10.10 and iOS 8. Each chaining block is called when the previous queue has finished.
```swift
let previousBlock = {}
let chainingBlock = {}
let dispatchQueueForChainingBlock = ...
// Use the GCD API to extend the blocks
let _previousBlock = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, previousBlock)
let _chainingBlock = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, chainingBlock)
// Use the GCD API to call back when finishing the "previous" block
dispatch_block_notify(_previousBlock, dispatchQueueForChainingBlock, _chainingBlock)
```

### Known improvements
```swift default``` is a keyword. Workaround used: ```swift default_```
The ```swift dispatch_block_t``` can't be extended. Workaround used: Wrap ```swift dispatch_block_t``` in a struct that takes the block as a property.
