//
//  UserDefaultsWrapper.swift
//  Lingo lens
//
//  Created by Claude Code Review on 11/17/25.
//

import Foundation
import SwiftUI

/// Type-safe property wrapper for UserDefaults storage
/// Provides compile-time safety and eliminates string-based key errors
@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T
    let container: UserDefaults

    init(key: String, defaultValue: T, container: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.container = container
    }

    var wrappedValue: T {
        get {
            return container.object(forKey: key) as? T ?? defaultValue
        }
        set {
            if let optional = newValue as? AnyOptional, optional.isNil {
                container.removeObject(forKey: key)
            } else {
                container.set(newValue, forKey: key)
            }
            Logger.debug("UserDefaults: Set \(key) = \(newValue)")
        }
    }
}

/// Property wrapper for optional UserDefaults values
@propertyWrapper
struct OptionalUserDefault<T> {
    let key: String
    let container: UserDefaults

    init(key: String, container: UserDefaults = .standard) {
        self.key = key
        self.container = container
    }

    var wrappedValue: T? {
        get {
            return container.object(forKey: key) as? T
        }
        set {
            if let value = newValue {
                container.set(value, forKey: key)
                Logger.debug("UserDefaults: Set \(key) = \(value)")
            } else {
                container.removeObject(forKey: key)
                Logger.debug("UserDefaults: Removed \(key)")
            }
        }
    }
}

// MARK: - Helper Protocol for Optional Detection

private protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    var isNil: Bool { self == nil }
}
