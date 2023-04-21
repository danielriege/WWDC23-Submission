//
//  RingBuffer.swift
//  WWDC23
//
//  Created by Daniel Riege on 15.04.23.
//

import Foundation

public struct RingBuffer<T> {
    private var array: [T?]
    private var writeIndex = 0
    private var readIndex = 0
    private var capacity: Int
    
    public init(count: Int, withValue: T? = nil) {
        capacity = count
        if withValue != nil {
            array = [T?](repeating: withValue!, count: count)
            writeIndex = capacity-1
        } else {
            array = [T?](repeating: nil, count: count)
        }
    }
    
    public mutating func write(_ element: T) {
        array[wrapped: writeIndex] = element
        writeIndex += 1
        if writeIndex % capacity <= readIndex % capacity {
            readIndex += 1
        }
    }
}

extension RingBuffer: Sequence {
    public func makeIterator() -> AnyIterator<T> {
        var index = readIndex
        return AnyIterator {
            guard index < self.writeIndex else { return nil }
            defer {
                index += 1
            }
            return self.array[wrapped: index]
        }
    }
}

private extension Array {
    subscript (wrapped index: Int) -> Element {
        get {
            return self[index % count]
        }
        set {
            self[index % count] = newValue
        }
    }
}
