import Foundation

class AnalyticsService {
    private let preferences = UserPreferences.shared
    private var eventQueue: [AnalyticsEvent] = []
    private let maxQueueSize = 100
    private var flushTimer: Timer?
    
    // Privacy-first analytics
    private let sessionId = UUID().uuidString
    private let installId: String
    
    init() {
        // Generate or load persistent install ID (anonymized)
        if let existingId = UserDefaults.standard.string(forKey: "WindowAI.installId") {
            self.installId = existingId
        } else {
            self.installId = UUID().uuidString
            UserDefaults.standard.set(self.installId, forKey: "WindowAI.installId")
        }
        
        setupFlushTimer()
    }
    
    deinit {
        flushTimer?.invalidate()
        flushEvents()
    }
    
    // MARK: - Event Tracking
    func trackAppLaunched() {
        guard preferences.enableAnalytics else { return }
        
        let event = AnalyticsEvent(
            name: "app_launched",
            properties: [
                "session_id": sessionId,
                "version": getAppVersion(),
                "os_version": getOSVersion(),
                "subscription_status": preferences.subscriptionStatus.rawValue
            ]
        )
        addEvent(event)
    }
    
    func trackCommandExecuted(_ command: WindowCommand, success: Bool, duration: TimeInterval) {
        guard preferences.enableAnalytics else { return }
        
        let event = AnalyticsEvent(
            name: "command_executed",
            properties: [
                "action": command.action.rawValue,
                "target_type": getTargetType(command.target),
                "success": success,
                "duration_ms": Int(duration * 1000),
                "has_position": command.position != nil,
                "has_size": command.size != nil
            ]
        )
        addEvent(event)
    }
    
    func trackLLMRequest(provider: LLMProvider, duration: TimeInterval, success: Bool, tokenCount: Int?) {
        guard preferences.enableAnalytics else { return }
        
        var properties: [String: Any] = [
            "provider": provider.rawValue,
            "duration_ms": Int(duration * 1000),
            "success": success
        ]
        
        if let tokens = tokenCount {
            properties["token_count"] = tokens
        }
        
        let event = AnalyticsEvent(name: "llm_request", properties: properties)
        addEvent(event)
    }
    
    func trackContextArrangement(_ context: String, appsCount: Int, success: Bool) {
        guard preferences.enableAnalytics else { return }
        
        let event = AnalyticsEvent(
            name: "context_arrangement",
            properties: [
                "context": context,
                "apps_count": appsCount,
                "success": success
            ]
        )
        addEvent(event)
    }
    
    func trackError(_ error: Error, context: String) {
        guard preferences.enableCrashReporting else { return }
        
        let event = AnalyticsEvent(
            name: "error_occurred",
            properties: [
                "error_type": String(describing: type(of: error)),
                "error_description": error.localizedDescription,
                "context": context
            ]
        )
        addEvent(event)
    }
    
    func trackSubscriptionEvent(_ eventType: SubscriptionEventType, plan: String?) {
        guard preferences.enableAnalytics else { return }
        
        var properties: [String: Any] = [
            "event_type": eventType.rawValue
        ]
        
        if let plan = plan {
            properties["plan"] = plan
        }
        
        let event = AnalyticsEvent(name: "subscription_event", properties: properties)
        addEvent(event)
    }
    
    func trackFeatureUsed(_ feature: String, context: [String: Any] = [:]) {
        guard preferences.enableAnalytics else { return }
        
        var properties = context
        properties["feature"] = feature
        
        let event = AnalyticsEvent(name: "feature_used", properties: properties)
        addEvent(event)
    }
    
    // MARK: - Performance Tracking
    func trackPerformanceMetric(_ metric: PerformanceMetric, value: Double) {
        guard preferences.enableAnalytics else { return }
        
        let event = AnalyticsEvent(
            name: "performance_metric",
            properties: [
                "metric": metric.rawValue,
                "value": value,
                "unit": metric.unit
            ]
        )
        addEvent(event)
    }
    
    // MARK: - Privacy Controls
    func optOut() {
        preferences.enableAnalytics = false
        preferences.enableCrashReporting = false
        preferences.shareUsageData = false
        clearEventQueue()
    }
    
    func optIn() {
        preferences.enableAnalytics = true
        preferences.enableCrashReporting = true
    }
    
    func clearEventQueue() {
        eventQueue.removeAll()
    }
    
    // MARK: - Private Methods
    private func addEvent(_ event: AnalyticsEvent) {
        eventQueue.append(event)
        
        if eventQueue.count >= maxQueueSize {
            flushEvents()
        }
    }
    
    private func flushEvents() {
        guard !eventQueue.isEmpty else { return }
        guard preferences.enableAnalytics || preferences.enableCrashReporting else {
            clearEventQueue()
            return
        }
        
        // TODO: Send events to analytics backend
        sendEventsToBackend(eventQueue)
        eventQueue.removeAll()
    }
    
    private func setupFlushTimer() {
        flushTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            self.flushEvents()
        }
    }
    
    private func sendEventsToBackend(_ events: [AnalyticsEvent]) {
        // TODO: Implement actual backend communication
        // This should be asynchronous and handle failures gracefully
        
        guard preferences.shareUsageData else { return }
        
        // Example implementation structure:
        // - Batch events into payload
        // - Send to analytics endpoint
        // - Handle retry logic for failed requests
        // - Respect user privacy preferences
    }
    
    private func getTargetType(_ target: String) -> String {
        // Classify target without exposing specific app names
        let commonApps = [
            "browser": ["Safari", "Chrome", "Firefox", "Edge"],
            "code_editor": ["Xcode", "Visual Studio Code", "Sublime Text", "Atom"],
            "terminal": ["Terminal", "iTerm", "iTerm2"],
            "communication": ["Messages", "Slack", "Discord", "Teams"],
            "productivity": ["Notes", "Pages", "Word", "Excel"]
        ]
        
        for (category, apps) in commonApps {
            if apps.contains(target) {
                return category
            }
        }
        
        return "other"
    }
    
    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }
    
    private func getOSVersion() -> String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
}

// MARK: - Supporting Types
struct AnalyticsEvent: Codable {
    let name: String
    let properties: [String: Any]
    let timestamp: Date
    
    init(name: String, properties: [String: Any]) {
        self.name = name
        self.properties = properties
        self.timestamp = Date()
    }
    
    // Custom encoding to handle Any type
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(timestamp, forKey: .timestamp)
        
        // Convert properties to JSON data
        let jsonData = try JSONSerialization.data(withJSONObject: properties)
        try container.encode(jsonData, forKey: .properties)
    }
    
    enum CodingKeys: String, CodingKey {
        case name, properties, timestamp
    }
}

enum SubscriptionEventType: String, CaseIterable {
    case subscribed = "subscribed"
    case cancelled = "cancelled"
    case renewed = "renewed"
    case expired = "expired"
    case upgraded = "upgraded"
    case downgraded = "downgraded"
}

enum PerformanceMetric: String, CaseIterable {
    case commandExecutionTime = "command_execution_time"
    case llmResponseTime = "llm_response_time"
    case windowDiscoveryTime = "window_discovery_time"
    case hotkeyResponseTime = "hotkey_response_time"
    case memoryUsage = "memory_usage"
    
    var unit: String {
        switch self {
        case .commandExecutionTime, .llmResponseTime, .windowDiscoveryTime, .hotkeyResponseTime:
            return "milliseconds"
        case .memoryUsage:
            return "megabytes"
        }
    }
}