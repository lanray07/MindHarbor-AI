import Combine
import Foundation
import StoreKit

@MainActor
final class SubscriptionStore: ObservableObject {
    static let monthlyProductID = "com.MindHarborAI.app.plus.monthly"
    static let annualProductID = "com.MindHarborAI.app.plus.annual"
    static let productIDs = [monthlyProductID, annualProductID]

    @Published private(set) var products: [Product] = []
    @Published private(set) var hasActiveSubscription = false
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = observeTransactionUpdates()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: Self.productIDs).sorted {
                $0.id == Self.annualProductID && $1.id != Self.annualProductID
            }
        } catch {
            errorMessage = "Subscriptions are temporarily unavailable. Please try again."
        }
    }

    func purchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verified(verification)
                await transaction.finish()
                await refreshEntitlements()
            case .pending:
                errorMessage = "Your purchase is pending approval."
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = "We couldn't complete the purchase. Please try again."
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !hasActiveSubscription {
                errorMessage = "No active MindHarbor Plus subscription was found."
            }
        } catch {
            errorMessage = "We couldn't restore purchases. Please try again."
        }
    }

    private func refreshEntitlements() async {
        var isSubscribed = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? verified(result) else { continue }
            if Self.productIDs.contains(transaction.productID), transaction.revocationDate == nil {
                isSubscribed = true
            }
        }
        hasActiveSubscription = isSubscribed
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self, let transaction = try? self.verified(result) else { continue }
                await transaction.finish()
                await self.refreshEntitlements()
            }
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw SubscriptionError.failedVerification
        }
    }
}

private enum SubscriptionError: Error {
    case failedVerification
}
