# Async
[![](http://img.shields.io/badge/OS%20X-10.10%2B-blue.svg)]() [![](http://img.shields.io/badge/iOS-8.0%2B-blue.svg)]() [![](http://img.shields.io/badge/tvOS-9.0%2B-blue.svg)]() [![](http://img.shields.io/badge/watchOS-2.0%2B-blue.svg)]() [![](http://img.shields.io/badge/Swift-4.0-blue.svg)]() [![](https://travis-ci.org/duemunk/Async.svg)](https://travis-ci.org/duemunk/Async) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg)](https://github.com/Carthage/Carthage) [![CocoaPods compatible](https://img.shields.io/badge/CocoaPods-compatible-4BC51D.svg)](https://github.com/CocoaPods/CocoaPods) [![](http://img.shields.io/badge/operator_overload-nope-green.svg)](https://gist.github.com/duemunk/61e45932dbb1a2ca0954)



Now more than syntactic sugar for asynchronous dispatches in Grand Central Dispatch ([GCD](https://developer.apple.com/library/prerelease/ios/documentation/Performance/Reference/GCD_libdispatch_Ref/index.html)) in Swift

**Async** sugar looks like this:
```swift
Async.userInitiated {
	return 10
}.background {
	return "Score: \($0)"
}.main {
	label.text = $0
}
```

So even though GCD has nice-ish syntax as of Swift 3.0, compare the above with:
```swift
DispatchQueue.global(qos: .userInitiated).async {
	let value = 10
	DispatchQueue.global(qos: .background).async {
		let text = "Score: \(value)"
		DispatchQueue.main.async {
			label.text = text
		}
	}
}
```

**AsyncGroup** sugar looks like this:
```swift
let group = AsyncGroup()
group.background {
    print("This is run on the background queue")
}
group.background {
    print("This is also run on the background queue in parallel")
}
group.wait()
print("Both asynchronous blocks are complete")
```

### Install
#### CocoaPods
```ruby
use_frameworks!
pod "AsyncSwift"
```
#### Carthage
```ruby
github "duemunk/Async"
```

### Benefits
1. Avoid code indentation by chaining
2. Arguments and return types reduce polluted scopes

### Things you can do
Supports the modern queue classes:
```swift
Async.main {}
Async.userInteractive {}
Async.userInitiated {}
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
	print("This is run on the background queue")
}

// Run other code here...

// Chain to reference
backgroundBlock.main {
	print("This is run on the \(qos_class_self().description) (expected \(qos_class_main().description)), after the previous block")
}
```

Custom queues:
```swift
let customQueue = DispatchQueue(label: "CustomQueueLabel", attributes: [.concurrent])
let otherCustomQueue = DispatchQueue(label: "OtherCustomQueueLabel")
Async.custom(queue: customQueue) {
	print("Custom queue")
}.custom(queue: otherCustomQueue) {
	print("Other custom queue")
}
```

Dispatch block after delay:
```swift
let seconds = 0.5
Async.main(after: seconds) {
	print("Is called after 0.5 seconds")
}.background(after: 0.4) {
	print("At least 0.4 seconds after previous block, and 0.9 after Async code is called")
}
```

Cancel blocks that aren't already dispatched:
```swift
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
	// Cancel async to allow block1 to begin
	block1.cancel() // First block is _not_ cancelled
	block2.cancel() // Second block _is_ cancelled
}
```

Wait for block to finish – an ease way to continue on current queue after background task:
```swift
let block = Async.background {
	// Do stuff
}

// Do other stuff

block.wait()
```

### How does it work
The way it work is by using the new notification API for GCD introduced in OS X 10.10 and iOS 8. Each chaining block is called when the previous queue has finished.
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

The syntax part of the chaining works by having class methods on the `Async` object e.g. `Async.main {}` which returns a struct. The struct has matching methods e.g. `theStruct.main {}`.

### Known bugs
Modern GCD queues don't work as expected in the iOS Simulator. See issues [13](https://github.com/duemunk/Async/issues/13), [22](https://github.com/duemunk/Async/issues/22).

### Known improvements
The ```dispatch_block_t``` can't be extended. Workaround used: Wrap ```dispatch_block_t``` in a struct that takes the block as a property.

### Apply
There is also a wrapper for [`dispatch_apply()`](https://developer.apple.com/library/mac/documentation/Performance/Reference/GCD_libdispatch_Ref/index.html#//apple_ref/c/func/dispatch_apply)  for quick parallelisation of a `for` loop.
```swift
Apply.background(100) { i in
	// Do stuff e.g. print(i)
}
```
Note that this function returns after the block has been run all 100 times i.e. it is not asynchronous. For asynchronous behaviour, wrap it in a an `Async` block like `Async.background { Apply.background(100) { ... } }`.

### AsyncGroup
**AsyncGroup** facilitates working with groups of asynchronous blocks.

Multiple dispatch blocks with GCD:
```swift
let group = AsyncGroup()
group.background {
    // Run on background queue
}
group.utility {
    // Run on utility queue, in parallel to the previous block
}
group.wait()
```
All modern queue classes:
```swift
group.main {}
group.userInteractive {}
group.userInitiated {}
group.utility {}
group.background {}
```
Custom queues:
```swift
let customQueue = dispatch_queue_create("Label", DISPATCH_QUEUE_CONCURRENT)
group.custom(queue: customQueue) {}
```
Wait for group to finish:
```swift
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
```
Custom asynchronous operations:
```swift
let group = AsyncGroup()
group.enter()
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
    // Do stuff
    group.leave()
}
group.enter()
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
    // Do other stuff in parallel
    group.leave()
}
// Wait for both to finish
group.wait()
// Do rest of stuff
```

### License
The MIT License (MIT)

Copyright (c) 2016 Tobias Due Munk

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
