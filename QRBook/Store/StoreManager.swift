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

    // Plain tracked property (not @AppStorage) so Observation sees changes and
    // Pro-gated UI refreshes immediately when it's toggled.
    var devUnlock: Bool = UserDefaults.standard.bool(forKey: "devUnlock") {
        didSet { UserDefaults.standard.set(devUnlock, forKey: "devUnlock") }
    }

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
        // Pull the latest transactions from the App Store first — on a fresh
        // install the local cache is empty and restore would be a no-op.
        try? await AppStore.sync()
        await checkEntitlement()
    }

    // MARK: - Check Entitlement on Launch

    @MainActor
    func checkEntitlement() async {
        // Compute into a local and assign once so a transient verification
        // failure can't downgrade a paying user mid-check.
        var entitled = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == Self.productID {
                entitled = true
                break
            }
        }
        hasStoreKitEntitlement = entitled
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { continue }
                if let transaction = try? self.checkVerified(result),
                   transaction.productID == StoreManager.productID {
                    if transaction.revocationDate != nil {
                        await MainActor.run {
                            self.hasStoreKitEntitlement = false
                        }
                    } else {
                        await MainActor.run {
                            self.hasStoreKitEntitlement = true
                            self.purchaseState = .purchased
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
