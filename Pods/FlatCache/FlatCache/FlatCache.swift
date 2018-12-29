//
//  FlatCacheKey.swift
//  Freetime
//
//  Created by Ryan Nystrom on 10/20/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import Foundation

public struct FlatCacheKey: Equatable, Hashable {
    let typeName: String
    let id: String
}

public protocol Identifiable {
    var id: String { get }
}

public protocol Cachable: Identifiable { }

private extension Cachable {
    static var typeName: String {
        return String(describing: self)
    }

    var flatCacheKey: FlatCacheKey {
        return FlatCacheKey(typeName: Self.typeName, id: id)
    }
}

public protocol FlatCacheListener: AnyObject {
    func flatCacheDidUpdate(cache: FlatCache, update: FlatCache.Update)
}

public final class FlatCache {

    public enum Update {
        case item(Any)
        case list([Any])
        case clear
    }

    private var storage: [FlatCacheKey: Any] = [:]
    private let queue = DispatchQueue(
        label: "com.freetime.FlatCache.queue",
        qos: .userInitiated,
        attributes: .concurrent
    )

    private var listeners: [FlatCacheKey: NSHashTable<AnyObject>] = [:]

    public init() { }

    public func add<T: Cachable>(listener: FlatCacheListener, value: T) {
        assert(Thread.isMainThread)

        let key = value.flatCacheKey
        let table: NSHashTable<AnyObject>
        if let existing = listeners[key] {
            table = existing
        } else {
            table = NSHashTable.weakObjects()
        }
        table.add(listener)
        listeners[key] = table
    }

    public func set<T: Cachable>(value: T) {
        assert(Thread.isMainThread)

        let key = value.flatCacheKey
        storage[key] = value

        enumerateListeners(key: key) { listener in
            listener.flatCacheDidUpdate(cache: self, update: .item(value))
        }
    }

    private func enumerateListeners(key: FlatCacheKey, block: (FlatCacheListener) -> ()) {
        assert(Thread.isMainThread)

        if let table = listeners[key] {
            for object in table.objectEnumerator() {
                if let listener = object as? FlatCacheListener {
                    block(listener)
                }
            }
        }
    }

    public func set<T: Cachable>(values: [T]) {
        assert(Thread.isMainThread)

        var listenerHashToValuesMap = [Int: [T]]()
        var listenerHashToListenerMap = [Int: FlatCacheListener]()

        for value in values {
            let key = value.flatCacheKey
            storage[key] = value

            enumerateListeners(key: key, block: { listener in
                let hash = ObjectIdentifier(listener).hashValue
                if var arr = listenerHashToValuesMap[hash] {
                    arr.append(value)
                    listenerHashToValuesMap[hash] = arr
                } else {
                    listenerHashToValuesMap[hash] = [value]
                }
                listenerHashToListenerMap[hash] = listener
            })
        }

        for (hash, arr) in listenerHashToValuesMap {
            guard let listener = listenerHashToListenerMap[hash] else { continue }
            if arr.count == 1, let first = arr.first {
                listener.flatCacheDidUpdate(cache: self, update: .item(first))
            } else {
                listener.flatCacheDidUpdate(cache: self, update: .list(arr))
            }
        }
    }

    public func get<T: Cachable>(id: String) -> T? {
        assert(Thread.isMainThread)

        let key = FlatCacheKey(typeName: T.typeName, id: id)
        return storage[key] as? T
    }

    public func clear() {
        assert(Thread.isMainThread)
        
        storage = [:]

        for key in listeners.keys {
            enumerateListeners(key: key) { listener in
                listener.flatCacheDidUpdate(cache: self, update: .clear)
            }
        }
    }

}

