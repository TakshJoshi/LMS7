import SwiftUI
import FirebaseFirestore

struct LibrariansView: View {
    @State private var librarians: [Librarian] = []
    @State private var isAddLibrarianPresented = false
    @State private var searchText = ""

    var filteredLibrarians: [Librarian] {
        if searchText.isEmpty {
            return librarians
        }
        return librarians.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Title
            SectionView(title: "Librarians")

            // Search Bar
            TextFieldView(
                icon: "magnifyingglass",
                placeholder: "Search librarians...",
                text: $searchText
            )

            // Stats Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2)) {
                LibrarianStatCard(title: "Total Librarians", value: "\(librarians.count)", icon: "person.3")
                LibrarianStatCard(title: "Active Librarians", value: "\(librarians.filter { !$0.isSuspended }.count)", icon: "person.fill.checkmark")
                LibrarianStatCard(title: "Suspended", value: "\(librarians.filter { $0.isSuspended }.count)", icon: "nosign")
                LibrarianStatCard(title: "Fines Collected", value: "$2,456", icon: "dollarsign.circle")
            }
            .padding(.horizontal)

            // List of Librarians
            VStack(alignment: .leading, spacing: 8) {
                SectionView(title: "Librarian List")

                if librarians.isEmpty {
                    VStack {
                        ProgressView()
                        Text("Loading Librarians...")
                            .foregroundColor(.gray)
                    }
                } else {
                    List(filteredLibrarians) { librarian in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(librarian.fullName)
                                    .font(.headline)
                                Text(librarian.email)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()

                            // Three-dot Menu
                            Menu {
                                Button("Active", action: { /* Update status to Active */ })
                                Button("Suspend", role: .destructive, action: { /* Update status to Suspended */ })
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 8)
                    }
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
            .sheet(isPresented: $isAddLibrarianPresented) {
                AddLibrarianView()
            }
        }
        .padding(.top, 16)
        .onAppear {
            fetchLibrarians()
        }
    }
    
    private func fetchLibrarians() {
        let db = Firestore.firestore()
        db.collection("librarians").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching librarians: \(error.localizedDescription)")
                return
            }
            
            if let documents = snapshot?.documents {
                self.librarians = documents.map { doc in
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
            }
        }
    }
}

// Existing LibrarianStatCard can remain the same
struct LibrarianStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .center) {
                Image(systemName: icon)
                    .resizable()
                    .frame(width: 34, height: 30)
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.blue)
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.gray.opacity(0.2), lineWidth: 1.4)
        )
    }
}

struct LibrariansView_Previews: PreviewProvider {
    static var previews: some View {
        LibrariansView()
    }
}
