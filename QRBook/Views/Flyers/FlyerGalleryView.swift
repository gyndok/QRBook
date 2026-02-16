import SwiftUI

struct FlyerGalleryView: View {
    @State private var selectedTemplate: FlyerTemplate?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(FlyerTemplate.allCases) { template in
                        Button {
                            selectedTemplate = template
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: template.icon)
                                    .font(.largeTitle)
                                    .frame(height: 80)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.electricViolet.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))

                                Text(template.label)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(template.description)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .padding()
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
        }
        .tint(Color.electricViolet)
    }
}
