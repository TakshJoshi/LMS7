import SwiftUI
import FirebaseFirestore

struct LibrariansView: View {
    @State private var librarians: [Librarian] = []
    @State private var suspendedCount: Int = 0
    @State private var selectedLibrarian: Librarian?
    @State private var isAddLibrarianPresented = false
    @State private var isUpdateLibrarianPresented = false
    @State private var searchText: String = ""

    // Statistics
    @State private var totalFinesCollected: String = "$2,456"
    @State private var pendingFines: String = "$890"

    var body: some View {
        VStack(spacing: 16) {
            // Title
            SectionView(title: "Librarian Management")
            
            // Search Bar
            TextFieldView(
                icon: "magnifyingglass",
                placeholder: "Search librarians...",
                text: $searchText
            )

            // Stats Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                LibrariansStatCard(
                    icon: "person.2",
                    title: "\(librarians.count)",
                    subtitle: "Active Librarians"
                )
                LibrariansStatCard(
                    icon: "wallet.pass",
                    title: totalFinesCollected,
                    subtitle: "Fines Collected",
                    isHighlighted: true
                )
                LibrariansStatCard(
                    icon: "chart.bar",
                    title: pendingFines,
                    subtitle: "Pending Fines"
                )
                LibrariansStatCard(
                    icon: "nosign",
                    title: "\(suspendedCount)",
                    subtitle: "Suspended"
                )
            }
            .padding(.horizontal)

            // Librarians List
            VStack(alignment: .leading, spacing: 8) {
                SectionView(title: "Librarians")
                
                List(librarians) { librarian in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(librarian.fullName)
                                .font(.headline)
                            Text(librarian.email)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        
                        // Status Indicator
                        Text(librarian.isSuspended ? "Suspended" : "Active")
                            .foregroundColor(librarian.isSuspended ? .red : .green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                (librarian.isSuspended ? Color.red : Color.green)
                                    .opacity(0.1)
                            )
                            .cornerRadius(8)
                        
                        // Three-dot Menu
                        Menu {
                            Button("Update") {
                                selectedLibrarian = librarian
                                isUpdateLibrarianPresented.toggle()
                            }
                            Button("Delete", role: .destructive) {
                                deleteLibrarian(librarian)
                            }
                            Button(librarian.isSuspended ? "Reactivate" : "Suspend") {
                                toggleSuspension(for: librarian)
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

            // Add New Librarian Button
            Button(action: {
                isAddLibrarianPresented.toggle()
            }) {
                Text("+ Add New Librarian")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .sheet(isPresented: $isAddLibrarianPresented, onDismiss: fetchLibrarians) {
                AddLibrarianView()
            }
            .sheet(item: $selectedLibrarian, onDismiss: fetchLibrarians) { librarian in
                UpdateLibrarianView(librarian: librarian)
            }
        }
        .padding(.top, 16)
        .onAppear {
            fetchLibrarians()
        }
    }
    
    // MARK: - Fetch Librarians from Firestore
    private func fetchLibrarians() {
        let db = Firestore.firestore()
        db.collection("librarians").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching librarians: \(error.localizedDescription)")
                return
            }
            
            if let documents = snapshot?.documents {
                let fetchedLibrarians = documents.map { doc in
                    let data = doc.data()
                    return Librarian(
                        id: doc.documentID,
                        fullName: data["fullName"] as? String ?? "",
                        email: data["email"] as? String ?? "",
                        phone: data["phone"] as? String ?? "",
                        isEmployee: data["isEmployee"] as? Bool ?? true,
                        role: data["role"] as? String ?? "Librarian",
                        createdAt: data["createdAt"] as? Timestamp ?? Timestamp(),
                        isSuspended: data["isSuspended"] as? Bool ?? false
                    )
                }
                self.librarians = fetchedLibrarians
                self.suspendedCount = fetchedLibrarians.filter { $0.isSuspended }.count
            }
        }
    }

    // MARK: - Delete Librarian
    private func deleteLibrarian(_ librarian: Librarian) {
        let db = Firestore.firestore()
        db.collection("librarians").document(librarian.id).delete { error in
            if let error = error {
                print("Error deleting librarian: \(error.localizedDescription)")
            } else {
                fetchLibrarians()
            }
        }
    }

    // MARK: - Suspend / Reactivate Librarian
    private func toggleSuspension(for librarian: Librarian) {
        let db = Firestore.firestore()
        db.collection("librarians").document(librarian.id).updateData([
            "isSuspended": !librarian.isSuspended
        ]) { error in
            if let error = error {
                print("Error updating suspension: \(error.localizedDescription)")
            } else {
                fetchLibrarians()
            }
        }
    }
}
