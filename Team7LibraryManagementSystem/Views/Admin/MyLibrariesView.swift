import SwiftUI
import FirebaseFirestore

struct Library: Identifiable {
    var id: String
    var name: String
    var location: String
    var assignedLibrarian: String
    var totalBooks: Int
    var category: String
    var phone: String
}

struct MyLibrariesView: View {
    @State private var libraries: [Library] = []
    @State private var isAddLibraryPresented = false
    @State private var searchText = ""

    var filteredLibraries: [Library] {
        if searchText.isEmpty {
            return libraries
        }
        return libraries.filter { library in
            library.name.localizedCaseInsensitiveContains(searchText) ||
            library.location.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Title
            SectionView(title: "My Libraries")

            // Search Bar
            TextFieldView(
                icon: "magnifyingglass",
                placeholder: "Search libraries...",
                text: $searchText
            )

            // List of Libraries
            VStack(alignment: .leading, spacing: 8) {
                SectionView(title: "Libraries")

                List(filteredLibraries) { library in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(library.name)
                                .font(.headline)
                            Text(library.location)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()

                        // Three-dot Menu
                        Menu {
                            Button("Edit") {
                                // Handle edit action
                            }
                            Button("Delete", role: .destructive) {
                                deleteLibrary(library)
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }

            Spacer()

            // Add New Library Button
            Button(action: {
                isAddLibraryPresented.toggle()
            }) {
                Text("+ Add New Library")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .sheet(isPresented: $isAddLibraryPresented) {
                AddLibrariesForm()
            }
        }
        .padding(.top, 16)
        .onAppear {
            fetchLibraries()
        }
    }

    private func fetchLibraries() {
        let db = Firestore.firestore()
        
        print("Fetching libraries...")
        
        db.collection("libraries").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching libraries: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No documents found")
                return
            }
            
            print("Found \(documents.count) libraries")
            
            documents.forEach { doc in
                print("Library document: \(doc.documentID)")
                print("Data: \(doc.data())")
            }
            
            libraries = documents.map { doc in
                let data = doc.data()
                let library = Library(
                    id: doc.documentID,
                    name: data["name"] as? String ?? "",
                    location: data["address"] as? String ?? "",
                    assignedLibrarian: data["assignedLibrarian"] as? String ?? "",
                    totalBooks: data["totalBooks"] as? Int ?? 0,
                    category: data["category"] as? String ?? "",
                    phone: data["phone"] as? String ?? ""
                )
                print("Mapped library: \(library.name)")
                return library
            }
            
            print("Final libraries array count: \(libraries.count)")
        }
    }
    
    private func deleteLibrary(_ library: Library) {
        let db = Firestore.firestore()
        db.collection("libraries").document(library.id).delete { error in
            if let error = error {
                print("Error deleting library: \(error.localizedDescription)")
            } else {
                fetchLibraries()
            }
        }
    }
}

// MARK: - Preview
struct MyLibrariesView_Previews: PreviewProvider {
    static var previews: some View {
        MyLibrariesView()
    }
}
