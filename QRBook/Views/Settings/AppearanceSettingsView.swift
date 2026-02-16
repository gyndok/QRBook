import SwiftUI

struct AppearanceSettingsView: View {
    @AppStorage("accentColorHex") private var accentColorHex = "7C3AED"
    @AppStorage("appearanceMode") private var appearanceMode = "dark"

    var body: some View {
        List {
            Section("Accent Color") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Color.AccentTheme.allCases) { theme in
                            Button {
                                withAnimation { accentColorHex = theme.rawValue }
                            } label: {
                                VStack(spacing: 6) {
                                    Circle()
                                        .fill(theme.color)
                                        .frame(width: 44, height: 44)
                                        .overlay {
                                            if accentColorHex == theme.rawValue {
                                                Image(systemName: "checkmark")
                                                    .font(.headline)
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                        .overlay {
                                            Circle()
                                                .stroke(accentColorHex == theme.rawValue ? theme.color : .clear, lineWidth: 3)
                                                .padding(-4)
                                        }
                                    Text(theme.label)
                                        .font(.caption2)
                                        .foregroundStyle(accentColorHex == theme.rawValue ? theme.color : .secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            }

            Section("Appearance") {
                Picker("Mode", selection: $appearanceMode) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            }
        }
        .navigationTitle("Appearance")
    }
}
