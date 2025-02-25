import SwiftUI
import FirebaseFirestore

struct EachLibraryView: View {
    let library: Library
    @State private var librarians: [Librarian] = []
    @State private var isAddingLibrarian = false  // Controls modal presentation

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Image with Library Name
                ZStack(alignment: .bottomLeading) {
                    // Replace with actual image if available, or use a placeholder
                    Image(systemName: "photo.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                        .foregroundColor(.gray)
                    
                    HStack {
                        Text(library.name)
                            .font(.title2)
                            .bold()
                            .foregroundColor(.black)
                        Spacer()
                        
                        // Rating or additional info could go here
                        HStack {
                            Image(systemName: "building.columns")
                                .foregroundColor(.blue)
                            Text(library.code)
                                .foregroundColor(.black)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.2))
                
                // About Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("About")
                        .font(.headline)
                    
                    Text(library.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    EachInfoRow(icon: "mappin.circle", title: "Location", value: "\(library.address.line1), \(library.address.city)")
                    EachInfoRow(icon: "phone.circle", title: "Contact", value: library.contact.phone)
                    EachInfoRow(icon: "envelope", title: "Email", value: library.contact.email)
                    EachInfoRow(icon: "globe", title: "Website", value: library.contact.website)
                }
                .padding(.horizontal)
                
                // Statistics Grid
                VStack(alignment: .leading, spacing: 10) {
                    Text("Operating Information")
                        .font(.headline)
                        .padding(.leading)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatisticCard(icon: "clock", title: "Weekday Hours", value: "\(library.operationalHours.weekday.opening) - \(library.operationalHours.weekday.closing)", change: nil)
                        StatisticCard(icon: "clock", title: "Weekend Hours", value: "\(library.operationalHours.weekend.opening) - \(library.operationalHours.weekend.closing)", change: nil)
                        StatisticCard(icon: "person.2.fill", title: "Total Staff", value: library.staff.totalStaff, change: nil)
                        StatisticCard(icon: "person.fill.badge.plus", title: "Head Librarian", value: library.staff.headLibrarian, change: nil)
                    }
                }
                .padding(.horizontal)
                
                // Library Staff Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Library Staff")
                        .font(.headline)
                    
                    if librarians.isEmpty {
                        HStack {
                            Spacer()
                            Text("No librarians assigned to this library.")
                                .foregroundColor(.gray)
                                .italic()
                                .padding()
                            Spacer()
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    } else {
                        ForEach(librarians) { librarian in
                            StaffRow(
                                name: librarian.fullName,
                                email: librarian.email,
                                status: librarian.isSuspended ? "Suspended" : "Active",
                                statusColor: librarian.isSuspended ? .red : .green
                            )
                        }
                    }
                }
                .padding(.horizontal)
                
                // Library Features
                VStack(alignment: .leading, spacing: 12) {
                    Text("Features")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        FeatureCard(icon: "wifi", title: "WiFi", available: library.features.wifi)
                        FeatureCard(icon: "desktopcomputer", title: "Computer Lab", available: library.features.computerLab)
                        FeatureCard(icon: "person.3.fill", title: "Meeting Rooms", available: library.features.meetingRooms)
                        FeatureCard(icon: "car.fill", title: "Parking", available: library.features.parking)
                    }
                }
                .padding(.horizontal)
                
                // Library Settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Library Policies")
                        .font(.headline)
                    
                    PerformanceRow(
                        icon: "book.closed",
                        title: "Max Books Per Member",
                        value: library.settings.maxBooksPerMember,
                        subtitle: "Borrowing limit"
                    )
                    
                    PerformanceRow(
                        icon: "dollarsign.circle",
                        title: "Late Fee",
                        value: library.settings.lateFee,
                        subtitle: "Per overdue day"
                    )
                    
                    PerformanceRow(
                        icon: "calendar",
                        title: "Lending Period",
                        value: library.settings.lendingPeriod,
                        subtitle: "Standard borrowing time"
                    )
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Library Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { fetchLibrarians() }
        .sheet(isPresented: $isAddingLibrarian) {
            AddLibrarianView()
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

// Feature Card Component
struct FeatureCard: View {
    let icon: String
    let title: String
    let available: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(available ? .blue : .gray)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(available ? .green : .red)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        
    }
}

// Staff Row Component
struct StaffRow: View {
    let name: String
    let email: String
    let status: String
    let statusColor: Color
    
    var body: some View {
        HStack {
            Image(systemName: "person.crop.circle.fill")
                .font(.title2)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline)
                Text(email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(status)
                .font(.footnote)
                .foregroundColor(statusColor)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// Info Row Component
struct EachInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.body)
            }
            
            Spacer()
        }
    }
}

// Statistic Card Component
struct StatisticCard: View {
    let icon: String
    let title: String
    let value: String
    let change: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Text(value)
                .font(.title3)
                .bold()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// Performance Row Component
struct PerformanceRow: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(value)
                .font(.body)
                .bold()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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

//struct PerformanceRow: View {
//    let title: String
//    let value: String
//
//    var body: some View {
//        HStack {
//            Text(title).font(.subheadline).foregroundColor(.gray)
//            Spacer()
//            Text(value).font(.subheadline).bold()
//        }
//        .padding(.vertical, 5)
//    }
//}

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
