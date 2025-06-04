import Foundation

protocol SubscriptionServiceDelegate: AnyObject {
    func subscriptionService(_ service: SubscriptionService, didUpdateStatus status: SubscriptionStatus)
    func subscriptionService(_ service: SubscriptionService, didFailWithError error: Error)
}

class SubscriptionService {
    weak var delegate: SubscriptionServiceDelegate?
    private let preferences = UserPreferences.shared
    private var urlSession: URLSession
    
    // Usage tracking
    private var monthlyUsage: Int = 0
    private var lastUsageReset: Date?
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15.0
        self.urlSession = URLSession(configuration: config)
        
        loadUsageData()
        setupUsageResetTimer()
    }
    
    // MARK: - Public API
    func checkSubscriptionStatus() async throws -> SubscriptionStatus {
        // TODO: Call backend API to verify subscription status
        return preferences.subscriptionStatus
    }
    
    func validateLicense(_ licenseKey: String) async throws -> Bool {
        // TODO: Validate license key with backend
        return false
    }
    
    func purchaseSubscription(plan: SubscriptionPlan) async throws -> Bool {
        // TODO: Initiate purchase flow
        return false
    }
    
    func restorePurchases() async throws -> Bool {
        // TODO: Restore previous purchases
        return false
    }
    
    func cancelSubscription() async throws -> Bool {
        // TODO: Cancel subscription
        return false
    }
    
    // MARK: - Usage Tracking
    func canMakeRequest() -> Bool {
        resetUsageIfNeeded()
        
        let limit = preferences.subscriptionStatus.monthlyLimit
        return limit == -1 || monthlyUsage < limit
    }
    
    func recordRequest() {
        guard canMakeRequest() else { return }
        
        monthlyUsage += 1
        saveUsageData()
        
        // Notify if approaching limit
        let limit = preferences.subscriptionStatus.monthlyLimit
        if limit > 0 && monthlyUsage >= Int(Double(limit) * 0.8) {
            notifyApproachingLimit()
        }
    }
    
    func getRemainingRequests() -> Int {
        let limit = preferences.subscriptionStatus.monthlyLimit
        return limit == -1 ? -1 : max(0, limit - monthlyUsage)
    }
    
    func getUsagePercentage() -> Double {
        let limit = preferences.subscriptionStatus.monthlyLimit
        if limit == -1 { return 0 }
        return Double(monthlyUsage) / Double(limit)
    }
    
    // MARK: - Subscription Plans
    func getAvailablePlans() -> [SubscriptionPlan] {
        return [
            SubscriptionPlan(
                id: "free",
                name: "Free",
                price: 0,
                currency: "USD",
                interval: .monthly,
                features: ["50 AI commands per month", "Basic window management"],
                monthlyLimit: 50
            ),
            SubscriptionPlan(
                id: "pro",
                name: "Pro",
                price: 9.99,
                currency: "USD",
                interval: .monthly,
                features: ["Unlimited AI commands", "Advanced arrangements", "Priority support"],
                monthlyLimit: -1
            ),
            SubscriptionPlan(
                id: "enterprise",
                name: "Enterprise",
                price: 29.99,
                currency: "USD",
                interval: .monthly,
                features: ["Unlimited AI commands", "Team management", "Custom integrations", "Priority support"],
                monthlyLimit: -1
            )
        ]
    }
    
    // MARK: - License Management
    func activateLicense(_ licenseKey: String) async throws {
        // TODO: Activate license with backend
        preferences.subscriptionStatus = .pro // Temporary
        preferences.savePreferences()
    }
    
    func deactivateLicense() {
        preferences.subscriptionStatus = .free
        preferences.subscriptionExpiryDate = nil
        preferences.savePreferences()
    }
    
    // MARK: - Private Methods
    private func resetUsageIfNeeded() {
        let calendar = Calendar.current
        let now = Date()
        
        guard let lastReset = lastUsageReset else {
            // First time, reset usage
            monthlyUsage = 0
            lastUsageReset = now
            saveUsageData()
            return
        }
        
        // Check if it's a new month
        if !calendar.isDate(lastReset, equalTo: now, toGranularity: .month) {
            monthlyUsage = 0
            lastUsageReset = now
            saveUsageData()
        }
    }
    
    private func setupUsageResetTimer() {
        // TODO: Set up timer to reset usage at beginning of each month
    }
    
    private func saveUsageData() {
        UserDefaults.standard.set(monthlyUsage, forKey: "WindowAI.monthlyUsage")
        UserDefaults.standard.set(lastUsageReset, forKey: "WindowAI.lastUsageReset")
    }
    
    private func loadUsageData() {
        monthlyUsage = UserDefaults.standard.integer(forKey: "WindowAI.monthlyUsage")
        lastUsageReset = UserDefaults.standard.object(forKey: "WindowAI.lastUsageReset") as? Date
    }
    
    private func notifyApproachingLimit() {
        // TODO: Show notification that user is approaching their limit
    }
    
    private func makeAPIRequest(endpoint: String, method: String, body: Data?) async throws -> Data {
        // TODO: Generic API request method
        throw SubscriptionServiceError.notImplemented
    }
}

// MARK: - Supporting Types
struct SubscriptionPlan: Codable, Identifiable {
    let id: String
    let name: String
    let price: Double
    let currency: String
    let interval: SubscriptionInterval
    let features: [String]
    let monthlyLimit: Int
}

enum SubscriptionInterval: String, Codable {
    case monthly = "monthly"
    case yearly = "yearly"
    
    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
}

// MARK: - Error Types
enum SubscriptionServiceError: Error, LocalizedError {
    case notImplemented
    case invalidLicenseKey
    case networkError(Error)
    case subscriptionExpired
    case usageLimitExceeded
    case paymentFailed
    
    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "This feature is not yet implemented"
        case .invalidLicenseKey:
            return "Invalid license key"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .subscriptionExpired:
            return "Your subscription has expired"
        case .usageLimitExceeded:
            return "You have exceeded your monthly usage limit"
        case .paymentFailed:
            return "Payment processing failed"
        }
    }
}