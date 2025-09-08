import Foundation

/// Simple file logger that writes debug output to both console and file
class FileLogger {
    static let shared = FileLogger()
    
    private let logFileURL: URL
    private let logQueue = DispatchQueue(label: "file-logger", qos: .utility)
    
    private init() {
        // Create log file in tmp directory
        logFileURL = URL(fileURLWithPath: "/tmp/windowai_debug_output.log")
        
        // Clear existing log on startup
        try? "".write(to: logFileURL, atomically: true, encoding: .utf8)
        
        // Log startup message
        log("🚀 WindowAI File Logging Started - \(Date())")
    }
    
    /// Log message to both console and file
    func log(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] \(message)"
        
        // Print to console (existing behavior)
        print(logMessage)
        
        // Write to file asynchronously
        logQueue.async {
            do {
                let fileHandle = try FileHandle(forWritingTo: self.logFileURL)
                defer { fileHandle.closeFile() }
                
                fileHandle.seekToEndOfFile()
                if let data = (logMessage + "\n").data(using: .utf8) {
                    fileHandle.write(data)
                }
            } catch {
                // If file doesn't exist, create it
                do {
                    try (logMessage + "\n").write(to: self.logFileURL, atomically: true, encoding: .utf8)
                } catch {
                    // Silently fail - don't break app functionality
                    NSLog("FileLogger write failed: \(error)")
                }
            }
        }
    }
    
    /// Log with emoji prefix for better visibility
    func logWithEmoji(_ emoji: String, _ message: String) {
        log("\(emoji) \(message)")
    }
    
    /// Get the log file path for external monitoring
    var logFilePath: String {
        return logFileURL.path
    }
}

private extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}