import SwiftUI

struct WiFiFormView: View {
    @Binding var data: WiFiData

    var body: some View {
        Section("WiFi Network") {
            TextField("Network Name (SSID)", text: $data.ssid)
            SecureField("Password", text: $data.password)
            Picker("Security", selection: $data.security) {
                ForEach(WiFiData.Security.allCases) { sec in
                    Text(sec.label).tag(sec)
                }
            }
            Toggle("Hidden Network", isOn: $data.hidden)
        }
    }
}
