import SwiftUI
import Firebase
import FirebaseFirestore

// User Model
struct LibraryUser: Identifiable {
    let id: String
    let userId: String
    let firstName: String
    let lastName: String
    let email: String
    let dob: String
    let role: String
    let isDeleted: Bool
    let membershipId: String // For displaying as LIB-2024-001 format
    let lastActive: Date?
    let booksBorrowed: Int
    
    // Computed property for full name
    var fullName: String {
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Computed property for last active display text
    var lastActiveText: String {
        guard let lastActive = lastActive else { return "N/A" }
        
        let now = Date()
        let components = Calendar.current.dateComponents([.hour, .day], from: lastActive, to: now)
        
        if let days = components.day, days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            return "Just now"
        }
    }
    
    var isActive: Bool { !isDeleted }
}

// User Manager for Firebase Operations
class UserManager: ObservableObject {
    @Published var users: [LibraryUser] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let db = Firestore.firestore()
    
    // Fetch All Users
    func fetchUsers() {
        isLoading = true
        
        // Get current date for demo
        let now = Date()
        
        db.collection("users").getDocuments { (snapshot, error) in
            self.isLoading = false
            
            if let error = error {
                self.error = error
                print("Error fetching users: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                self.users = []
                return
            }
            
            var fetchedUsers: [LibraryUser] = []
            
            // Create a group to handle asynchronous operations
            let group = DispatchGroup()
            
            for (index, document) in documents.enumerated() {
                group.enter()
                
                let data = document.data()
                
                guard let userId = data["userId"] as? String,
                      let firstName = data["firstName"] as? String,
                      let lastName = data["lastName"] as? String,
                      let email = data["email"] as? String,
                      let dob = data["dob"] as? String,
                      let role = data["role"] as? String,
                      let isDeleted = data["isDeleted"] as? Bool else {
                    group.leave()
                    continue
                }
                
                // Generate a formatted membership ID
                let membershipId = String(format: "LIB-2024-%03d", index + 1)
                
                // Get the number of borrowed books
                self.fetchBorrowedBooksCount(for: email) { count in
                    // Create a mock last active time for display
                    let lastActive: Date?
                    
                    // For demo purposes, create varied last active times
                    switch index % 6 {
                    case 0: lastActive = Calendar.current.date(byAdding: .hour, value: -2, to: now)
                    case 1: lastActive = Calendar.current.date(byAdding: .day, value: -5, to: now)
                    case 2: lastActive = now // Just now
                    case 3: lastActive = Calendar.current.date(byAdding: .hour, value: -1, to: now)
                    case 4: lastActive = Calendar.current.date(byAdding: .hour, value: -3, to: now)
                    case 5: lastActive = Calendar.current.date(byAdding: .day, value: -2, to: now)
                    default: lastActive = now
                    }
                    
                    let user = LibraryUser(
                        id: document.documentID,
                        userId: userId,
                        firstName: firstName,
                        lastName: lastName,
                        email: email,
                        dob: dob,
                        role: role,
                        isDeleted: isDeleted,
                        membershipId: membershipId,
                        lastActive: lastActive,
                        booksBorrowed: count
                    )
                    
                    fetchedUsers.append(user)
                    group.leave()
                }
            }
            
            // When all operations are complete
            group.notify(queue: .main) {
                // Sort users by membershipId for consistent ordering
                self.users = fetchedUsers.sorted(by: { $0.membershipId < $1.membershipId })
                print("Fetched \(self.users.count) users")
            }
        }
    }
    
    // Fetch the count of borrowed books for a user
    private func fetchBorrowedBooksCount(for email: String, completion: @escaping (Int) -> Void) {
        db.collection("issued_books")
            .whereField("email", isEqualTo: email)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching borrowed books: \(error.localizedDescription)")
                    completion(0)
                    return
                }
                
                let count = snapshot?.documents.count ?? 0
                completion(count)
            }
    }
}

// Main Users View
struct libUsersView: View {
    @StateObject private var userManager = UserManager()
    @State private var searchText = ""
    
    var filteredUsers: [LibraryUser] {
        guard !searchText.isEmpty else { return userManager.users }
        return userManager.users.filter { user in
            user.fullName.localizedCaseInsensitiveContains(searchText) ||
            user.email.localizedCaseInsensitiveContains(searchText) ||
            user.membershipId.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var userStats: UserStats {
        UserStats(
            totalUsers: userManager.users.count,
            activeUsers: userManager.users.filter { !$0.isDeleted }.count,
            newToday: 12 // Hardcoded for demo to match image
        )
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                Text("Library Users")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white)
                
                if userManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Search Bar
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                
                                TextField("Search users...", text: $searchText)
                                    .font(.system(size: 16))
                                
                                if !searchText.isEmpty {
                                    Button(action: { searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            
                            // Stats Section
                            HStack(spacing: 16) {
                                StatsCard(
                                    value: "\(userStats.totalUsers)",
                                    label: "Total Users",
                                    backgroundColor: Color.blue.opacity(0.1)
                                )
                                StatsCard(
                                    value: "\(userStats.activeUsers)",
                                    label: "Active Users",
                                    backgroundColor: Color.green.opacity(0.1)
                                )
                                StatsCard(
                                    value: "\(userStats.newToday)",
                                    label: "New Today",
                                    backgroundColor: Color.purple.opacity(0.1)
                                )
                            }
                            .padding(.horizontal)
                            
                            // Users Section
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Recent Users")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    
                                    Spacer()
                                    
                                    Button(action: {}) {
                                        Text("See All")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                // In the libUsersView structure, modify the NavigationLink in the ForEach loop:

                                ForEach(filteredUsers) { user in
                                    NavigationLink(destination: FineManagementView(userId: user.userId)) {
                                        UserRow(user: user)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .onAppear {
                userManager.fetchUsers()
            }
        }
    }
}

struct StatsCard: View {
    let value: String
    let label: String
    let backgroundColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
    }
}

struct UserRow: View {
    let user: LibraryUser
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            Image(systemName: "person.circle.fill")
                .resizable()
                .foregroundColor(.gray)
                .frame(width: 50, height: 50)
            
            // User Details
            VStack(alignment: .leading, spacing: 4) {
                Text(user.fullName)
                    .font(.system(size: 16, weight: .medium))
                
                HStack {
                    Text(user.membershipId)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if user.isActive {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                    }
                }
                
                Text("\(user.booksBorrowed) book\(user.booksBorrowed == 1 ? "" : "s") borrowed")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Last Active Time
            Text(user.lastActiveText)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Models
struct UserStats {
    let totalUsers: Int
    let activeUsers: Int
    let newToday: Int
}
