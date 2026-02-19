import SwiftUI

struct FlyerGalleryView: View {
    @Environment(StoreManager.self) private var storeManager
    @State private var selectedTemplate: FlyerTemplate?
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(FlyerTemplate.allCases) { template in
                        Button {
                            if storeManager.isProUnlocked {
                                selectedTemplate = template
                            } else {
                                showPaywall = true
                            }
                        } label: {
                            VStack(spacing: 8) {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: template.icon)
                                        .font(.largeTitle)
                                        .frame(height: 80)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.electricViolet.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))

                                    if !storeManager.isProUnlocked {
                                        Text("PRO")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.electricViolet)
                                            .foregroundStyle(.white)
                                            .clipShape(Capsule())
                                            .padding(6)
                                    }
                                }

                                Text(template.label)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(template.description)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .padding()
                            .opacity(storeManager.isProUnlocked ? 1.0 : 0.7)
                            .themedCard()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(Color.appBg)
            .navigationTitle("Flyers")
            .sheet(item: $selectedTemplate) { template in
                FlyerEditorView(template: template)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
        .tint(Color.electricViolet)
    }
}
