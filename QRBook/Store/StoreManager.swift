import Foundation
import StoreKit
import SwiftUI

enum PurchaseState {
    case idle
    case purchasing
    case purchased
    case failed(String)
}

@Observable
final class StoreManager {
    private(set) var products: [Product] = []
    private(set) var purchaseState: PurchaseState = .idle
    private(set) var hasStoreKitEntitlement = false
    private var transactionListener: Task<Void, Never>?

    @ObservationIgnored
    @AppStorage("devUnlock") var devUnlock = false

    var isProUnlocked: Bool {
        hasStoreKitEntitlement || devUnlock
    }

    static let productID = "com.gyndok.qrbook.pro"
    static let freeCodeLimit = 15

    init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts() }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    @MainActor
    func loadProducts() async {
        do {
            products = try await Product.products(for: [Self.productID])
        } catch {
            print("StoreManager: Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    @MainActor
    func purchase() async {
        guard let product = products.first else {
            purchaseState = .failed("Product not available. Please try again later.")
            return
        }

        purchaseState = .purchasing

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                hasStoreKitEntitlement = true
                purchaseState = .purchased
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                purchaseState = .idle
            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    // MARK: - Restore Purchases

    @MainActor
    func restorePurchases() async {
        hasStoreKitEntitlement = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == Self.productID {
                hasStoreKitEntitlement = true
                return
            }
        }
    }

    // MARK: - Check Entitlement on Launch

    @MainActor
    func checkEntitlement() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == Self.productID {
                hasStoreKitEntitlement = true
                return
            }
        }
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if let transaction = try? self?.checkVerified(result),
                   transaction.productID == Self.productID {
                    if transaction.revocationDate != nil {
                        await MainActor.run {
                            self?.hasStoreKitEntitlement = false
                        }
                    } else {
                        await MainActor.run {
                            self?.hasStoreKitEntitlement = true
                            self?.purchaseState = .purchased
                        }
                    }
                    await transaction.finish()
                }
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
