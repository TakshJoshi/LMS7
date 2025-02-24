import SwiftUI
import FirebaseFirestore

struct EachLibraryView: View {
    let library: Library
    @State private var librarians: [Librarian] = []
    @State private var isAddingLibrarian = false  // Controls modal presentation

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        Spacer()
                        Text(library.name)
                            .font(.title2).bold()
                        Spacer()
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal)

                    // Library Image Placeholder
                    Image(systemName: "photo.fill")
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(10)
                        .frame(height: 150)
                        .padding(.horizontal, 120)

                    // Library Details
                    VStack(alignment: .leading, spacing: 8) {
                        Text(library.name)
                            .font(.title2).bold()
                        Text("Location: \(library.address.line1), \(library.address.city), \(library.address.state) \(library.address.zipCode)")
                        Text("Operating Hours: Weekdays: \(library.operationalHours.weekday.opening) - \(library.operationalHours.weekday.closing)\nWeekends: \(library.operationalHours.weekend.opening) - \(library.operationalHours.weekend.closing)")
                        Text("Phone: \(library.contact.phone)\nEmail: \(library.contact.email)")
                        Text("Total Staff: \(library.staff.totalStaff)")
                            .bold()
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground)))
                    .shadow(radius: 2)
                    .padding(.horizontal)

                    // Librarians Section
                    VStack(alignment: .leading) {
                        Text("Current Librarians")
                            .font(.headline)

                        if librarians.isEmpty {
                            Text("No librarians assigned to this library.")
                                .foregroundColor(.gray)
                                .italic()
                        } else {
                            ForEach(librarians) { librarian in
                                LibrarianView(name: librarian.fullName, email: librarian.email, status: "Active", color: .green)
                            }
                        }

                        Button(action: {
                            isAddingLibrarian = true
                        }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                Text("Add New Librarian")
                            }
                        .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground)))
                    .shadow(radius: 2)
                    .padding(.horizontal)

                    // Stats Section
                    VStack(spacing: 10) {
                        HStack {
                            LibStatCard(title: "Active Users", value: "1,245", change: "+5.2%")
                            LibStatCard(title: "New Users", value: "89", change: "+12.3%")
                        }
                        HStack {
                            LibStatCard(title: "Fine Collected", value: "$2,890", change: "+8.1%")
                            LibStatCard(title: "Pending Fines", value: "$750", change: "-2.4%")
                        }
                    }
                    .padding(.horizontal)

                    // Library Performance
                    VStack(alignment: .leading) {
                        Text("Library Performance")
                            .font(.headline)
                        PerformanceRow(title: "Books in Circulation", value: "3,567")
                        PerformanceRow(title: "Most Borrowed Category", value: "Fiction (32%)")
                        PerformanceRow(title: "Peak Hours", value: "2:00 PM - 5:00 PM")
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground)))
                    .shadow(radius: 2)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .onAppear { fetchLibrarians() }
        .sheet(isPresented: $isAddingLibrarian) {
            AddLibrarianView()
            .interactiveDismissDisabled()  // Prevent swipe down to dismiss
        }
    }

    // Fetch librarians assigned to this library
    private func fetchLibrarians() {
        let db = Firestore.firestore()
        db.collection("librarians")
            .whereField("assignedLibrary", isEqualTo: library.name)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching librarians: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                
                self.librarians = documents.compactMap { doc in
                    try? doc.data(as: Librarian.self)
                }
            }
    }
}

struct LibrarianView: View {
    let name: String
    let email: String
    let status: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading) {
                Text(name).bold()
                Text(email).font(.subheadline).foregroundColor(.gray)
            }
            Spacer()
            Text(status)
                .foregroundColor(color)
        }
        .padding(.vertical, 5)
    }
}

struct LibStatCard: View {
    let title: String
    let value: String
    let change: String

    var body: some View {
        VStack {
            Text(title).font(.subheadline).foregroundColor(.gray)
            Text(value).font(.title2).bold()
            Text(change).font(.footnote).foregroundColor(change.contains("-") ? .red : .green)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground)))
        .shadow(radius: 2)
    }
}

struct PerformanceRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title).font(.subheadline).foregroundColor(.gray)
            Spacer()
            Text(value).font(.subheadline).bold()
        }
        .padding(.vertical, 5)
    }
}

struct EachLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        EachLibraryView(library: Library(
            id: "123",
            name: "Central Library",
            code: "CL001",
            description: "Main city library with multiple facilities.",
            address: Address(line1: "123 Library Street", line2: "", city: "City", state: "State", zipCode: "12345", country: "Country"),
            contact: Contact(phone: "(555) 123-4567", email: "central.library@example.com", website: "www.library.com"),
            operationalHours: OperationalHours(
                weekday: OpeningHours(opening: "9:00 AM", closing: "8:00 PM"),
                weekend: OpeningHours(opening: "10:00 AM", closing: "6:00 PM")
            ),
            settings: LibrarySettings(maxBooksPerMember: "5", lateFee: "$1/day", lendingPeriod: "14 days"),
            staff: Staff(headLibrarian: "Sarah Johnson", totalStaff: "15"),
            features: Features(wifi: true, computerLab: true, meetingRooms: true, parking: true),
            createdAt: Timestamp()
        ))
    }
}
