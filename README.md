Async
=====

Syntactic sugar in Swift for asynchronous dispatches in Grand Central Dispatch ([GCD](https://developer.apple.com/library/prerelease/ios/documentation/Performance/Reference/GCD_libdispatch_Ref/index.html))

The familiar syntax for GCD is:
```swift
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
	println("This is run on the background queue")
	
	dispatch_async(dispatch_get_main_queue(), 0), {
		println("This is run on the main queue, after the previous block")
	})
})
```

**Async** adds syntactic sugar resulting in this:
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

### Examples (actually the entire API)
Supports the modern queue classes:
```swift
Async.main {}
Async.userInteractive {}
Async.userInitiated {}
Async.default_ {}
Async.utility {}
Async.background {}
```

Chain as many blocks as you want:
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

Store reference for later chaining:
```swift
let backgroundBlock = Async.background {
	println("This is run on the background queue")
}

// Run other code here...

// Chain to reference
backgroundBlock.main {
	println("This is run on the \(qos_class_self().description) (expected \(qos_class_main().description)), after the previous block")
}
```

Custom queues:
```swift
let customQueue = dispatch_queue_create("CustomQueueLabel", DISPATCH_QUEUE_CONCURRENT)
let otherCustomQueue = dispatch_queue_create("OtherCustomQueueLabel", DISPATCH_QUEUE_CONCURRENT)
Async.customQueue(customQueue) {
	println("Custom queue")
}.customQueue(otherCustomQueue) {
	println("Other custom queue")
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
```default``` is a keyword. Workaround used: ```default_```
The ```dispatch_block_t``` can't be extended. Workaround used: Wrap ```dispatch_block_t``` in a struct that takes the block as a property.

### License
The MIT License (MIT)

Copyright (c) 2014 Tobias Due Munk

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
