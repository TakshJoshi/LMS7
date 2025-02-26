
import SwiftUI
import Firebase
import FirebaseFirestore

// MARK: - Models

// User Model
struct LibraryUser: Identifiable {
    let id: String
    let userId: String
    let firstName: String
    let lastName: String
    let email: String
    
    // Computed property for full name
    var fullName: String {
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// Stats Model
struct UserStats {
    let totalUsers: Int
    let activeUsers: Int
    let newToday: Int
}

// Book Model - Renamed to avoid conflicts
struct UserIssuedBook: Identifiable {
    let id: String
    let isbn13: String
    let issueDate: Date
    let dueDate: Date
    let status: String
    let fine: Double
    var bookTitle: String = "Unknown"
    var bookAuthor: String = "Unknown"
    var bookCoverURL: String?
    
    var isOverdue: Bool {
        Date() > dueDate
    }
    
    var daysLeft: Int {
        if isOverdue {
            return -Calendar.current.dateComponents([.day], from: dueDate, to: Date()).day!
        } else {
            return Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day!
        }
    }
}

// MARK: - User Manager

class UserManager: ObservableObject {
    @Published var users: [LibraryUser] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let db = Firestore.firestore()
    
    func fetchUsers() {
        isLoading = true
        
        db.collection("users").getDocuments() { (snapshot, error) in
            DispatchQueue.main.async {
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
                
                self.users = documents.compactMap { document in
                    let data = document.data()
                    
                    guard let userId = data["userId"] as? String,
                          let firstName = data["firstName"] as? String,
                          let lastName = data["lastName"] as? String,
                          let email = data["email"] as? String else {
                        return nil
                    }
                    
                    return LibraryUser(
                        id: document.documentID,
                        userId: userId,
                        firstName: firstName,
                        lastName: lastName,
                        email: email
                    )
                }
            }
        }
    }
}

// MARK: - UI Components

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
                
                Text(user.email)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct IssuedBookCard: View {
    let book: UserIssuedBook // Updated type name
    
    var body: some View {
        HStack(spacing: 12) {
            // Book Cover
            if let coverURL = book.bookCoverURL, let url = URL(string: coverURL) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle().fill(Color.gray.opacity(0.2))
                }
                .frame(width: 70, height: 100)
                .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 70, height: 100)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "book.closed")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.bookTitle)
                    .font(.headline)
                
                Text(book.bookAuthor)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("ISBN: \(book.isbn13)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("Status: \(book.status)")
                    .font(.caption)
                    .foregroundColor(book.status == "Borrowed" ? .blue : .green)
                
                HStack {
                    Text("Due: \(formatDate(book.dueDate))")
                        .font(.caption)
                    
                    if book.isOverdue {
                        Text("Overdue: \(book.daysLeft) days")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                    } else {
                        Text("\(book.daysLeft) days left")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                if book.fine > 0 {
                    Text("Fine: $\(String(format: "%.2f", book.fine))")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Views

// User Books View
struct UserBooksView: View {
    let user: LibraryUser
    @State private var issuedBooks: [UserIssuedBook] = [] // Updated type name
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            // User info section
            VStack(alignment: .leading, spacing: 8) {
                Text(user.fullName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(user.email)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.white)
            
            if isLoading {
                Spacer()
                ProgressView("Loading books...")
                Spacer()
            } else if issuedBooks.isEmpty {
                Spacer()
                VStack(spacing: 20) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No books issued to this user")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                Spacer()
            } else {
                // Show issued books
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(issuedBooks) { book in
                            IssuedBookCard(book: book)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Issued Books")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchIssuedBooks()
        }
    }
    
    private func fetchIssuedBooks() {
        let db = Firestore.firestore()
        
        // Get books issued to this user
        db.collection("issued_books")
            .whereField("email", isEqualTo: user.email)
            .getDocuments() { (snapshot, error) in
                if let error = error {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    // No books found
                    isLoading = false
                    return
                }
                
                let group = DispatchGroup()
                var tempBooks: [UserIssuedBook] = [] // Updated type name
                
                // Process each issued book
                for document in documents {
                    let data = document.data()
                    
                    guard let isbn13 = data["isbn13"] as? String,
                          let issueDate = (data["issue_date"] as? Timestamp)?.dateValue(),
                          let dueDate = (data["due_date"] as? Timestamp)?.dateValue(),
                          let status = data["status"] as? String else {
                        continue
                    }
                    
                    var issuedBook = UserIssuedBook( // Updated type name
                        id: document.documentID,
                        isbn13: isbn13,
                        issueDate: issueDate,
                        dueDate: dueDate,
                        status: status,
                        fine: data["fine"] as? Double ?? 0.0
                    )
                    
                    // Fetch book details
                    group.enter()
                    db.collection("books")
                        .whereField("isbn13", isEqualTo: isbn13)
                        .getDocuments() { (snapshot, error) in
                            if let bookDoc = snapshot?.documents.first {
                                let bookData = bookDoc.data()
                                issuedBook.bookTitle = bookData["title"] as? String ?? "Unknown"
                                issuedBook.bookAuthor = (bookData["authors"] as? [String])?.first ?? "Unknown"
                                issuedBook.bookCoverURL = bookData["coverImageUrl"] as? String
                            }
                            tempBooks.append(issuedBook)
                            group.leave()
                        }
                }
                
                group.notify(queue: .main) {
                    // Sort books by due date (overdue first)
                    self.issuedBooks = tempBooks.sorted {
                        if $0.isOverdue && !$1.isOverdue {
                            return true
                        } else if !$0.isOverdue && $1.isOverdue {
                            return false
                        } else {
                            return $0.dueDate < $1.dueDate
                        }
                    }
                    isLoading = false
                }
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
            user.email.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var userStats: UserStats {
        UserStats(
            totalUsers: userManager.users.count,
            activeUsers: userManager.users.count,
            newToday: 12 // Hardcoded for demo
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
                                
                                ForEach(filteredUsers) { user in
                                    NavigationLink(destination: UserBooksView(user: user)) {
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

struct libUsersView_Previews: PreviewProvider {
    static var previews: some View {
        libUsersView()
    }
}
