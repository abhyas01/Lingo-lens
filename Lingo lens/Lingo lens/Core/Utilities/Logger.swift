//
//  Logger.swift
//  Lingo lens
//
//  Created by Claude Code Review on 11/17/25.
//

import Foundation

/// Centralized logging utility with conditional debug-only logging
/// Prevents excessive logging in production builds while maintaining debug capabilities
enum LogLevel: String {
    case debug = "🔍 DEBUG"
    case info = "ℹ️ INFO"
    case warning = "⚠️ WARNING"
    case error = "❌ ERROR"
}

struct Logger {

    /// Logs a message with specified level
    /// - Parameters:
    ///   - message: The message to log
    ///   - level: The severity level of the message
    ///   - file: Source file (auto-captured)
    ///   - function: Source function (auto-captured)
    ///   - line: Source line number (auto-captured)
    static func log(
        _ message: String,
        level: LogLevel = .debug,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        #if DEBUG
        let filename = (file as NSString).lastPathComponent
        let timestamp = DateFormatter.logTimestamp.string(from: Date())
        print("[\(timestamp)] [\(level.rawValue)] [\(filename):\(line)] \(function) - \(message)")
        #else
        // In production, only log warnings and errors
        if level == .error || level == .warning {
            print("[\(level.rawValue)] \(message)")
            // TODO: Send to crash reporting service (e.g., Crashlytics)
        }
        #endif
    }

    /// Convenience method for debug logging
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }

    /// Convenience method for info logging
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }

    /// Convenience method for warning logging
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }

    /// Convenience method for error logging
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
}

// MARK: - DateFormatter Extension

private extension DateFormatter {
    static let logTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}
