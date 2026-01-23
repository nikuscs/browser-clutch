import Foundation
import os.log

enum LogLevel: Int, Comparable {
    case debug = 0
    case info = 1
    case warn = 2
    case error = 3

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var prefix: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warn: return "WARN"
        case .error: return "ERROR"
        }
    }
}

final class Logger {
    static let shared = Logger()

    private let osLog = os.Logger(subsystem: "com.browserclutch.app", category: "main")
    private let dateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        return f
    }()

    private let logFileURL: URL = {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("BrowserClutch")
            .appendingPathComponent("debug.log")
    }()

    var minLevel: LogLevel = .info
    var fileLoggingEnabled = true
    var consoleLoggingEnabled = true

    private init() {}

    func debug(_ message: String) { log(message, level: .debug) }
    func info(_ message: String) { log(message, level: .info) }
    func warn(_ message: String) { log(message, level: .warn) }
    func error(_ message: String) { log(message, level: .error) }

    private func log(_ message: String, level: LogLevel) {
        guard level >= minLevel else { return }

        let timestamp = dateFormatter.string(from: Date())
        let line = "[\(timestamp)] [\(level.prefix)] \(message)"

        if consoleLoggingEnabled {
            print(line)
        }

        // OS log
        switch level {
        case .debug: osLog.debug("\(message)")
        case .info: osLog.info("\(message)")
        case .warn: osLog.warning("\(message)")
        case .error: osLog.error("\(message)")
        }

        // File log
        if fileLoggingEnabled {
            writeToFile(line + "\n")
        }
    }

    private func writeToFile(_ line: String) {
        guard let data = line.data(using: .utf8) else { return }

        if FileManager.default.fileExists(atPath: logFileURL.path) {
            if let handle = try? FileHandle(forWritingTo: logFileURL) {
                defer { try? handle.close() }
                _ = try? handle.seekToEnd()
                _ = try? handle.write(contentsOf: data)
            }
        } else {
            try? data.write(to: logFileURL)
        }
    }

    func clearLog() {
        try? FileManager.default.removeItem(at: logFileURL)
    }
}
