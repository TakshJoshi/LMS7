import SwiftUI
import FirebaseFirestore



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
            library.address.city.localizedCaseInsensitiveContains(searchText) ||
            library.address.state.localizedCaseInsensitiveContains(searchText)
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
                            Text("\(library.address.city), \(library.address.state)")
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
        
        db.collection("libraries").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching libraries: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No documents found")
                return
            }
            
            self.libraries = documents.compactMap { doc in
                let data = doc.data()
                
                guard let name = data["name"] as? String,
                      let code = data["code"] as? String,
                      let description = data["description"] as? String,
                      let addressData = data["address"] as? [String: Any],
                      let contactData = data["contact"] as? [String: Any],
                      let operationalHoursData = data["operationalHours"] as? [String: Any],
                      let settingsData = data["settings"] as? [String: Any],
                      let staffData = data["staff"] as? [String: Any],
                      let featuresData = data["features"] as? [String: Bool],
                      let createdAt = data["createdAt"] as? Timestamp else {
                    print("Error parsing library data for document: \(doc.documentID)")
                    return nil
                }
                
                let address = Address(
                    line1: addressData["line1"] as? String ?? "",
                    line2: addressData["line2"] as? String ?? "",
                    city: addressData["city"] as? String ?? "",
                    state: addressData["state"] as? String ?? "",
                    zipCode: addressData["zipCode"] as? String ?? "",
                    country: addressData["country"] as? String ?? ""
                )
                
                let contact = Contact(
                    phone: contactData["phone"] as? String ?? "",
                    email: contactData["email"] as? String ?? "",
                    website: contactData["website"] as? String ?? ""
                )
                
                let weekdayHours = (operationalHoursData["weekday"] as? [String: String]) ?? [:]
                let weekendHours = (operationalHoursData["weekend"] as? [String: String]) ?? [:]
                
                let operationalHours = OperationalHours(
                    weekday: OpeningHours(
                        opening: weekdayHours["opening"] ?? "",
                        closing: weekdayHours["closing"] ?? ""
                    ),
                    weekend: OpeningHours(
                        opening: weekendHours["opening"] ?? "",
                        closing: weekendHours["closing"] ?? ""
                    )
                )
                
                let settings = LibrarySettings(
                    maxBooksPerMember: settingsData["maxBooksPerMember"] as? String ?? "",
                    lateFee: settingsData["lateFee"] as? String ?? "",
                    lendingPeriod: settingsData["lendingPeriod"] as? String ?? ""
                )
                
                let staff = Staff(
                    headLibrarian: staffData["headLibrarian"] as? String ?? "",
                    totalStaff: staffData["totalStaff"] as? String ?? ""
                )
                
                let features = Features(
                    wifi: featuresData["wifi"] ?? false,
                    computerLab: featuresData["computerLab"] ?? false,
                    meetingRooms: featuresData["meetingRooms"] ?? false,
                    parking: featuresData["parking"] ?? false
                )
                
                return Library(
                    id: doc.documentID,
                    name: name,
                    code: code,
                    description: description,
                    address: address,
                    contact: contact,
                    operationalHours: operationalHours,
                    settings: settings,
                    staff: staff,
                    features: features,
                    createdAt: createdAt
                )
            }
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
