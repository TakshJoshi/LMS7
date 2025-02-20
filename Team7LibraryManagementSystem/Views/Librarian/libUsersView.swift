import SwiftUI
import Firebase
import FirebaseFirestore

// Updated User Model to Match Firebase Structure
struct LibraryUser: Identifiable {
    let id: String
    let userId: String
    let firstName: String
    let lastName: String
    let email: String
    let dob: String
    let role: String
    let isDeleted: Bool
    
    // Computed property for full name
    var fullName: String {
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Computed property for profile image (can be customized)
    var profileImage: String {
        // You can implement custom logic for profile images
        return "default_profile"
    }
    
    // Computed properties to match original implementation
    var name: String { fullName }
    var libraryId: String { userId }
    var booksBorrowed: Int { 0 } // This would come from another collection
    var lastActive: String { "N/A" } // This would come from user activity tracking
    var isActive: Bool { !isDeleted }
}

// User Manager for Firebase Operations
class UserManager: ObservableObject {
    @Published var users: [LibraryUser] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let db = Firestore.firestore()
    
    // Fetch All Users
    func fetchUsers(completion: @escaping (Result<[LibraryUser], Error>) -> Void) {
        isLoading = true
        
        db.collection("users").getDocuments { (snapshot, error) in
            self.isLoading = false
            
            if let error = error {
                self.error = error
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            let fetchedUsers = documents.compactMap { doc -> LibraryUser? in
                let data = doc.data()
                
                guard let userId = data["userId"] as? String,
                      let firstName = data["firstName"] as? String,
                      let lastName = data["lastName"] as? String,
                      let email = data["email"] as? String,
                      let dob = data["dob"] as? String,
                      let role = data["role"] as? String,
                      let isDeleted = data["isDeleted"] as? Bool else {
                    return nil
                }
                
                return LibraryUser(
                    id: doc.documentID,
                    userId: userId,
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    dob: dob,
                    role: role,
                    isDeleted: isDeleted
                )
            }
            
            self.users = fetchedUsers
            completion(.success(fetchedUsers))
        }
    }
    
    // Delete User
    func deleteUser(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        
        // Soft delete by updating isDeleted flag
        db.collection("users").document(userId).updateData([
            "isDeleted": true
        ]) { error in
            self.isLoading = false
            
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // Update User
    func updateUser(
        userId: String,
        firstName: String? = nil,
        lastName: String? = nil,
        email: String? = nil,
        dob: String? = nil,
        role: String? = nil,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        isLoading = true
        
        var updateData: [String: Any] = [:]
        
        if let firstName = firstName { updateData["firstName"] = firstName }
        if let lastName = lastName { updateData["lastName"] = lastName }
        if let email = email { updateData["email"] = email }
        if let dob = dob { updateData["dob"] = dob }
        if let role = role { updateData["role"] = role }
        
        db.collection("users").document(userId).updateData(updateData) { error in
            self.isLoading = false
            
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}

// Users View with Firebase Integration
struct libUsersView: View {
    @StateObject private var userManager = UserManager()
    @State private var searchText = ""
    @State private var selectedUser: LibraryUser?
    @State private var showEditUserSheet = false
    
    var filteredUsers: [LibraryUser] {
        guard !searchText.isEmpty else { return userManager.users }
        return userManager.users.filter { user in
            user.fullName.localizedCaseInsensitiveContains(searchText) ||
            user.email.localizedCaseInsensitiveContains(searchText) ||
            user.userId.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var userStats: UserStats {
        UserStats(
            totalUsers: userManager.users.count,
            activeUsers: userManager.users.filter { !$0.isDeleted }.count,
            newToday: userManager.users.filter { isUserCreatedToday(user: $0) }.count
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            UsersHeaderView()
            
            if userManager.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Search Bar
                        SearchBar(text: $searchText)
                            .padding(.horizontal)
                        
                        // Stats Section
                        UserStatsSection(stats: userStats)
                        
                        // Recent Users Section
                        RecentUsersSection(
                            users: filteredUsers,
                            onUserTap: { user in
                                selectedUser = user
                                showEditUserSheet = true
                            }
                        )
                    }
                    .padding(.vertical)
                }
            }
        }
        .onAppear {
            fetchUsers()
        }
        .sheet(isPresented: $showEditUserSheet) {
            if let user = selectedUser {
                UserDetailView(user: user)
            }
        }
    }
    
    private func fetchUsers() {
        userManager.fetchUsers { result in
            switch result {
            case .success(let users):
                print("Fetched \(users.count) users")
            case .failure(let error):
                print("Error fetching users: \(error.localizedDescription)")
            }
        }
    }
    
    // Helper method to check if user was created today
    private func isUserCreatedToday(user: LibraryUser) -> Bool {
        // Implement logic to check if user was created today
        // This would depend on how you're storing user creation date
        return false
    }
}

// User Detail View for Editing
struct UserDetailView: View {
    @StateObject private var userManager = UserManager()
    @Environment(\.dismiss) private var dismiss
    
    let user: LibraryUser
    @State private var firstName: String
    @State private var lastName: String
    @State private var email: String
    @State private var dob: String
    @State private var role: String
    
    init(user: LibraryUser) {
        self.user = user
        _firstName = State(initialValue: user.firstName)
        _lastName = State(initialValue: user.lastName)
        _email = State(initialValue: user.email)
        _dob = State(initialValue: user.dob)
        _role = State(initialValue: user.role)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email", text: $email)
                    TextField("Date of Birth", text: $dob)
                }
                
                Section(header: Text("Account Details")) {
                    Picker("Role", selection: $role) {
                        Text("User").tag("user")
                        Text("Admin").tag("admin")
                    }
                }
                
                Section {
                    Button("Update User") {
                        updateUser()
                    }
                    
                    Button("Delete User", role: .destructive) {
                        deleteUser()
                    }
                }
            }
            .navigationTitle("User Details")
            .navigationBarItems(trailing: Button("Close") {
                dismiss()
            })
        }
    }
    
    private func updateUser() {
        userManager.updateUser(
            userId: user.userId,
            firstName: firstName,
            lastName: lastName,
            email: email,
            dob: dob,
            role: role
        ) { result in
            switch result {
            case .success:
                print("User updated successfully")
                dismiss()
            case .failure(let error):
                print("Error updating user: \(error.localizedDescription)")
            }
        }
    }
    
    private func deleteUser() {
        userManager.deleteUser(userId: user.userId) { result in
            switch result {
            case .success:
                print("User deleted successfully")
                dismiss()
            case .failure(let error):
                print("Error deleting user: \(error.localizedDescription)")
            }
        }
    }
}

// Retain existing structs from the original view
struct UsersHeaderView: View {
    var body: some View {
        HStack {
            Text("Library Users")
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding()
        .background(Color.white)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search users...", text: $text)
                .font(.system(size: 16))
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct UserStatsSection: View {
    let stats: UserStats
    
    var body: some View {
        HStack(spacing: 16) {
            StatsCard(
                value: "\(stats.totalUsers)",
                label: "Total Users",
                backgroundColor: Color.blue.opacity(0.1)
            )
            StatsCard(
                value: "\(stats.activeUsers)",
                label: "Active Users",
                backgroundColor: Color.green.opacity(0.1)
            )
            StatsCard(
                value: "\(stats.newToday)",
                label: "New Today",
                backgroundColor: Color.purple.opacity(0.1)
            )
        }
        .padding(.horizontal)
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

struct RecentUsersSection: View {
    let users: [LibraryUser]
    let onUserTap: (LibraryUser) -> Void
    
    var body: some View {
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
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                ForEach(users) { user in
                    UserRow(user: user, onTap: onUserTap)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct UserRow: View {
    let user: LibraryUser
    let onTap: (LibraryUser) -> Void
    
    var body: some View {
        Button(action: { onTap(user) }) {
            HStack(spacing: 12) {
                // Profile Image
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
                    .frame(width: 50, height: 50)
                
                // User Details
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(user.fullName)
                            .font(.system(size: 16, weight: .medium))
                        
                        if user.isActive {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Text(user.userId)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("\(user.booksBorrowed) books borrowed")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Time
                Text(user.lastActive)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

// Models
struct UserStats {
    let totalUsers: Int
    let activeUsers: Int
    let newToday: Int
}
