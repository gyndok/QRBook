import SwiftUI
import SwiftData

struct ManageFoldersView: View {
    @Query(sort: \Folder.sortOrder) private var folders: [Folder]
    @Environment(\.modelContext) private var modelContext
    @State private var newFolderName = ""

    var body: some View {
        List {
            Section("Create Folder") {
                HStack {
                    TextField("Folder name...", text: $newFolderName)
                    Button {
                        createFolder()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(newFolderName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            Section("Folders") {
                if folders.isEmpty {
                    Text("No folders yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(folders) { folder in
                        HStack {
                            Image(systemName: folder.iconName)
                                .foregroundStyle(Color(hex: folder.colorHex))
                            Text(folder.name)
                            Spacer()
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            modelContext.delete(folders[index])
                        }
                    }
                }
            }
        }
        .navigationTitle("Manage Folders")
    }

    private func createFolder() {
        let name = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        guard !folders.contains(where: { $0.name == name }) else { return }
        let folder = Folder(name: name, sortOrder: folders.count)
        modelContext.insert(folder)
        newFolderName = ""
    }
}
