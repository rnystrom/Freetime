# FlatCache

Store any object in a flat cache by `String` id and notify listeners when changes occur.

This is an implementation of [Soroush Khanlou](https://twitter.com/khanlou)'s [The Flat Cache](http://khanlou.com/2017/10/the-flat-cache/) blog post used in [GitHawk](http://githawk.com).

## Installation

Just add `FlatCache` to your Podfile and pod install. Done!

```
pod 'FlatCache'
```

## Usage

Add the `Cachable` protocol to models that you want to store in the cache. Conform to the protocol by returning a `String` identifier used for lookup.

```swift
struct User {
  let name: String
}

extension User: Cachable {
  var id: String {
    return name
  }
}
```

> Don't worry about `id` collisions between objects. The cache "namespaces" different models by type.

Now just create a `FlatCache` object and start reading & writing with it.

```swift
let cache = FlatCache()
let user = User(name: "ryan")
cache.set(value: user)
if let cached = cache.get(id: user.id) as User? {
  print(cached.name) // "ryan"
}
```

> `FlatCache` uses the type information with the `get(id:)` function to lookup the appropriate object. You must type the result somehow.

### Listeners

One of the strengths of `FlatCache` is adding "listeners" to the cache to be notified when an object is changed. This powerful tool lets multiple systems respond to object changes.

```swift
let cache = FlatCache()
let user = User(name: "ryan")
let listener = MyUserListener()
cache.add(listener: listener, value: user)
```

Now whenever `user` is set again in the cache, `MyUserListener` will be notified with the following function:

```swift

func flatCacheDidUpdate(cache: FlatCache, update: FlatCache.Update) {
  switch update {
  case .item(let item):
    // just a single object updated
  case .list:
    // a list of subscribed objects updated
  }
}
```

> `FlatCache` coalesces so only a single event is delivered when something changes, no matter if an update has just a single object or hundreds.

## Acknowledgements

- Code used and inspired from [Soroush Khanlou](https://twitter.com/khanlou)'s [The Flat Cache](http://khanlou.com/2017/10/the-flat-cache/)
- Created with ❤️ by [Ryan Nystrom](https://twitter.com/_ryannystrom)
