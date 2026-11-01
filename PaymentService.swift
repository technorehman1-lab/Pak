import Foundation

struct PaymentResult {
    let reference: String
    let fee: Double
}

enum PaymentError: LocalizedError {
    case notLoggedIn
    case invalidAmount
    case invalidNumber
    case selfTransfer
    case insufficientBalance
    case limitExceeded(Double)
    case balanceLimit(Double)
    case notConfigured
    case network(String)

    var errorDescription: String? {
        switch self {
        case .notLoggedIn: return "Pehle login karein."
        case .invalidAmount: return "Sahi amount likhein."
        case .invalidNumber: return "Number 03XXXXXXXXX format mein likhein."
        case .selfTransfer: return "Apne aap ko paisay nahi bhej sakte."
        case .insufficientBalance: return "Aapke wallet mein balance kam hai."
        case .limitExceeded(let limit): return "Ek transaction ki limit \(limit.rs) hai."
        case .balanceLimit(let limit): return "Wallet mein \(limit.rs) se zyada balance nahi ho sakta."
        case .notConfigured: return "Payment API abhi connect nahi hui."
        case .network(let message): return message
        }
    }
}

/// App ke saare payment kaam isi protocol se guzarte hain.
/// Demo mein MockPaymentService chalti hai; asli API jorne ke liye
/// sirf RealPaymentService bharni hai aur PakTransferApp mein badalni hai.
protocol PaymentService {
    func sendMoney(from: String, to: String, wallet: Wallet, amount: Double, note: String) async throws -> PaymentResult
    func mobileLoad(from: String, network: Telco, number: String, amount: Double) async throws -> PaymentResult
    func payBill(from: String, company: String, consumerNumber: String, amount: Double) async throws -> PaymentResult
    func addMoney(to: String, method: FundingMethod, amount: Double) async throws -> PaymentResult
}

// MARK: - Demo (koi asli paisa nahi hilta)

struct MockPaymentService: PaymentService {
    func sendMoney(from: String, to: String, wallet: Wallet, amount: Double, note: String) async throws -> PaymentResult {
        try await simulateNetwork()
        return PaymentResult(reference: Reference.make(), fee: FeePolicy.fee(for: wallet))
    }

    func mobileLoad(from: String, network: Telco, number: String, amount: Double) async throws -> PaymentResult {
        try await simulateNetwork()
        return PaymentResult(reference: Reference.make(), fee: 0)
    }

    func payBill(from: String, company: String, consumerNumber: String, amount: Double) async throws -> PaymentResult {
        try await simulateNetwork()
        return PaymentResult(reference: Reference.make(), fee: 0)
    }

    func addMoney(to: String, method: FundingMethod, amount: Double) async throws -> PaymentResult {
        try await simulateNetwork()
        return PaymentResult(reference: Reference.make(), fee: 0)
    }

    private func simulateNetwork() async throws {
        try await Task.sleep(nanoseconds: 900_000_000)
    }
}

// MARK: - Asli API ke liye jagah

/// Yahan apni asli payment API ke calls likhni hain.
///
/// Zaroori baatein:
/// - Merchant key / secret kabhi app ke andar na rakhein. App apne backend server
///   se baat kare, aur server payment provider (JazzCash/Easypaisa merchant API) se.
/// - Balance, fee aur limits ka final faisla server karey, app sirf dikhaye.
/// - Har request ke saath user ka auth token bhejein.
struct RealPaymentService: PaymentService {
    let baseURL: URL
    let authToken: () -> String?

    func sendMoney(from: String, to: String, wallet: Wallet, amount: Double, note: String) async throws -> PaymentResult {
        // TODO: POST \(baseURL)/transfer  { from, to, wallet, amount, note }
        // Response se reference aur fee le kar PaymentResult return karein.
        throw PaymentError.notConfigured
    }

    func mobileLoad(from: String, network: Telco, number: String, amount: Double) async throws -> PaymentResult {
        // TODO: POST \(baseURL)/mobile-load
        throw PaymentError.notConfigured
    }

    func payBill(from: String, company: String, consumerNumber: String, amount: Double) async throws -> PaymentResult {
        // TODO: POST \(baseURL)/bill-payment
        throw PaymentError.notConfigured
    }

    func addMoney(to: String, method: FundingMethod, amount: Double) async throws -> PaymentResult {
        // TODO: POST \(baseURL)/top-up
        throw PaymentError.notConfigured
    }
}
