import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    header

                    // Feature comparison
                    featureList

                    // Purchase button
                    purchaseButton

                    // Restore
                    Button("Restore Purchases") {
                        Task { await storeManager.restorePurchases() }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    // Error state
                    if case .failed(let message) = storeManager.purchaseState {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color.appBg)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onChange(of: storeManager.isProUnlocked) { _, unlocked in
                if unlocked { dismiss() }
            }
        }
        .presentationBackground(Color.appBg)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppTheme.violetToIndigo)
                    .frame(height: 180)

                VStack(spacing: 8) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 48))
                        .foregroundStyle(.white)
                    Text("QR Snap Vault PRO")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("One-time purchase. Unlock everything.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Feature List

    private var featureList: some View {
        VStack(spacing: 0) {
            featureRow(feature: "QR codes", free: "15 max", pro: "Unlimited", icon: "qrcode")
            Divider().padding(.horizontal)
            featureRow(feature: "QR types", free: "URL & Text", pro: "All 11 types", icon: "square.grid.2x2")
            Divider().padding(.horizontal)
            featureRow(feature: "Custom colors & logo", free: nil, pro: "Yes", icon: "paintbrush")
            Divider().padding(.horizontal)
            featureRow(feature: "Folders", free: nil, pro: "Yes", icon: "folder")
            Divider().padding(.horizontal)
            featureRow(feature: "Batch operations", free: nil, pro: "Yes", icon: "checkmark.circle")
            Divider().padding(.horizontal)
            featureRow(feature: "Flyer export", free: nil, pro: "Yes", icon: "doc.text")
            Divider().padding(.horizontal)
            featureRow(feature: "Bulk import", free: nil, pro: "Yes", icon: "square.and.arrow.down.on.square")
            Divider().padding(.horizontal)
            featureRow(feature: "iCloud sync", free: "Yes", pro: "Yes", icon: "icloud")
        }
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.subtleBorder, lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private func featureRow(feature: String, free: String?, pro: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color.electricViolet)
                .frame(width: 24)

            Text(feature)
                .font(.subheadline)

            Spacer()

            if let free {
                Text(free)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .center)
            } else {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.secondary.opacity(0.5))
                    .frame(width: 60, alignment: .center)
            }

            Image(systemName: "checkmark.circle.fill")
                .font(.subheadline)
                .foregroundStyle(Color.electricViolet)
                .frame(width: 40, alignment: .center)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            Task { await storeManager.purchase() }
        } label: {
            Group {
                if case .purchasing = storeManager.purchaseState {
                    ProgressView()
                        .tint(.white)
                } else {
                    let price = storeManager.products.first?.displayPrice ?? "$6.99"
                    Text("Unlock PRO — \(price)")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(AppTheme.violetToIndigo)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal)
        .disabled({
            if case .purchasing = storeManager.purchaseState { return true }
            return false
        }())
    }
}
