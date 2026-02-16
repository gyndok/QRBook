import SwiftUI

struct ContactFormView: View {
    @Binding var data: ContactData

    var body: some View {
        Section("Contact Information") {
            TextField("Full Name", text: $data.name)
                .textContentType(.name)
            TextField("Phone", text: $data.phone)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
            TextField("Email", text: $data.email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
            TextField("Organization", text: $data.organization)
                .textContentType(.organizationName)
            TextField("Website", text: $data.url)
                .keyboardType(.URL)
                .autocapitalization(.none)
        }
    }
}
