import SwiftUI

struct PaymentFormView: View {
    let label: String
    let placeholder: String
    let hint: String
    @Binding var text: String

    var body: some View {
        Section(label) {
            TextField(placeholder, text: $text)
                .autocapitalization(.none)
            Text(hint)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
