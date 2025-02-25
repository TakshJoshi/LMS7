//
//  HomeView.swift
//  LinrarianSide
//
//  Created by Taksh Joshi on 20/02/25.
//

import SwiftUI
import FirebaseFirestore

struct PreBookItem: Identifiable {
    let id: String
    let userEmail: String
    let isbn13: String
    let status: String
}

struct libHomeView: View {
    @State private var books: [Book] = []
    @State private var activeUsers = 0
    @State private var showProfile = false
    @State private var showNotification = false
    @State private var preBookItems: [PreBookItem] = []
    @State private var recentActivities: [LibraryActivity] = [
        
        LibraryActivity(
            icon: "book.fill",
            title: "Book Checkout",
            userName: "Emma Wilson",
            timeAgo: "2m ago",
            status: .completed
        ),
        LibraryActivity(
            icon: "book.fill",
            title: "Book Return",
            userName: "James Chen",
            timeAgo: "15m ago",
            status: .completed
        ),
        LibraryActivity(
            icon: "dollarsign.circle.fill",
            title: "Fine Payment",
            userName: "Sarah Miller",
            timeAgo: "1h ago",
            status: .completed
        ),
        LibraryActivity(
            icon: "person.fill",
            title: "New Registration",
            userName: "Alex Johnson",
            timeAgo: "2h ago",
            status: .pending
        )
    ]
    
    var body: some View {
        NavigationStack{
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Text("Library Admin")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        
                        
                        // Profile Image
                        //                        NavigationLink(destination: ProfileView()) {
                            .toolbar {
                                HStack(spacing: 4) { // Adjust spacing as needed
                                    Image(systemName: "bell")
                                        .font(.title3)
                                        .foregroundStyle(.black)
                                        .onTapGesture {
                                            showNotification = true
                                        }.sheet(isPresented: $showNotification) {
                                            NavigationStack {
                                                NotificationsView()
                                            }
                                        }
                                    
                                    Image(systemName: "person.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.black)
                                        .onTapGesture {
                                            showProfile = true
                                        }.sheet(isPresented: $showProfile) {
                                            NavigationStack {
                                                Setting()
                                            }
                                        }
                                }
                            }
                        //                    }
                    }
                    .padding(.horizontal)
                    
                    // Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        // Total Books
                        StatCard2(
                            icon: "book.fill",
                            iconColor: .blue,
                            title: "\(books.count)",
                            subtitle: "Total Books"
                        )
                        
                        // Active Users
                        StatCard2(
                            icon: "person.2.fill",
                            iconColor: .blue,
                            title: "\(activeUsers)",
                            subtitle: "Active Users"
                        )
                        
                        // Total Fine
                        StatCard2(
                            icon: "dollarsign.circle.fill",
                            iconColor: .blue,
                            title: "$123",
                            subtitle: "Total Fine"
                        )
                        
                        // Issue Book
                        IssueBookCard()
                    }
                    .padding(.horizontal)
                    
                    // Library Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Library")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        // Library Card
                        homeLibraryCard(
                            name: "Central Library",
                            location: "Downtown",
                            image: "library.background"
                        )
                        .padding(.horizontal)
                    }
                    
                    // Recent Activities
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Pre-Book Requests")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                                            
                    VStack(spacing: 12) {
                        ForEach(preBookItems) { preBook in
                            PreBookRequestRow(preBook: preBook)
                        }
                    }
                    .padding(.horizontal)
                }
                }
                .padding(.vertical)
            }
            .onAppear {
                fetchLibraryData()
                fetchPreBookRequests()
            }
        }
    }
    private func fetchPreBookRequests() {
            let db = Firestore.firestore()
            
            db.collection("PreBook").whereField("status", isEqualTo: "Pending").getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching pre-book requests: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.preBookItems = documents.map { document in
                    PreBookItem(
                        id: document.documentID,
                        userEmail: document.data()["userEmail"] as? String ?? "",
                        isbn13: document.data()["isbn13"] as? String ?? "",
                        status: document.data()["status"] as? String ?? ""
                    )
                }
            }
        }
    private func fetchLibraryData() {
            let db = Firestore.firestore()
            
            // Fetch books count
            db.collection("books").getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching books: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                self.books = documents.compactMap { document -> Book? in
                    let data = document.data()
                                
                    return Book(
                        id: document.documentID,
                        title: data["title"] as? String ?? "",
                        authors: data["authors"] as? [String] ?? [],
                        publisher: data["publisher"] as? String,
                        publishedDate: data["publishedDate"] as? String,
                        description: data["description"] as? String,
                        pageCount: data["pageCount"] as? Int,
                        categories: data["categories"] as? [String],
                        coverImageUrl: data["coverImageUrl"] as? String,
                        isbn13: data["isbn13"] as? String,
                        language: data["language"] as? String,
                        quantity: data["quantity"] as? Int ?? 0,
                        availableQuantity: data["availableQuantity"] as? Int ?? 0,
                        location: data["location"] as? String ?? "",
                        status: data["status"] as? String ?? "available",
                        totalCheckouts: data["totalCheckouts"] as? Int ?? 0,
                        currentlyBorrowed: data["currentlyBorrowed"] as? Int ?? 0,
                        isAvailable: data["isAvailable"] as? Bool ?? true,
                        libraryId: data["libraryId"] as? String
                    )
                }
            }
            
            // Fetch active users count
            db.collection("users").whereField("isActive", isEqualTo: true).getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching users: \(error.localizedDescription)")
                    return
                }
                
                if let documents = snapshot?.documents {
                    self.activeUsers = documents.count
                }
            }
        }
    func confirmPreBooking(preBookId: String) {
            let db = Firestore.firestore()
            let preBookRef = db.collection("PreBook").document(preBookId)
            
            preBookRef.updateData([
                "status": "Confirmed"
            ]) { error in
                if let error = error {
                    print("Error confirming pre-booking: \(error.localizedDescription)")
                } else {
                    print("Pre-booking confirmed successfully!")
                    // Refresh pre-book requests after confirmation
                    fetchPreBookRequests()
                }
            }
        }
}

struct StatCard2: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
struct PreBookRequestRow: View {
    let preBook: PreBookItem
    @State private var isConfirmed = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(preBook.userEmail)
                    .font(.headline)
                
                Text("ISBN: \(preBook.isbn13)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                // Confirm pre-booking
                confirmPreBooking(preBookId: preBook.id)
                isConfirmed = true
            }) {
                Image(systemName: isConfirmed ? "checkmark.circle.fill" : "checkmark.circle")
                    .foregroundColor(isConfirmed ? .green : .blue)
                    .imageScale(.large)
            }
            .disabled(isConfirmed)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func confirmPreBooking(preBookId: String) {
        let db = Firestore.firestore()
        let preBookRef = db.collection("PreBook").document(preBookId)
        
        preBookRef.updateData([
            "status": "Confirmed"
        ]) { error in
            if let error = error {
                print("Error confirming pre-booking: \(error.localizedDescription)")
            } else {
                print("Pre-booking confirmed successfully!")
            }
        }
    }
}
struct homeLibraryCard: View {
    let name: String
    let location: String
    let image: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 150)
                .clipped()
                .cornerRadius(12)
                .background(Color(.systemGray6))
            
            Text(name)
                .font(.title3)
                .fontWeight(.bold)
            
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.gray)
                Text(location)
                    .foregroundColor(.gray)
            }
            .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
}

struct ActivityRow: View {
    let activity: LibraryActivity
    
    var body: some View {
        HStack {
            // Activity Icon
            Image(systemName: activity.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            
            // Activity Details
            VStack(alignment: .leading) {
                Text(activity.title)
                    .fontWeight(.medium)
                Text(activity.userName)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Time and Status
            VStack(alignment: .trailing) {
                Text(activity.timeAgo)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Image(systemName: activity.status == .completed ? "checkmark.circle.fill" : "clock.fill")
                    .foregroundColor(activity.status == .completed ? .green : .orange)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct LibraryActivity: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let userName: String
    let timeAgo: String
    let status: ActivityStatus
    
    enum ActivityStatus {
        case completed, pending
    }
}

struct IssueBookCard: View {
    var body: some View {
        NavigationLink(destination: AddIssueBookView()) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "plus")
                    .foregroundColor(.blue)
                
                Text("Issued Book")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}
#Preview {
    libHomeView()
}
struct ProfileView2: View {
    var body: some View {
        VStack {
            Text("Profile Page")
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .navigationTitle("Profile")
    }
}
