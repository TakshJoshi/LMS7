//
//  IssueBookView.swift
//  librarian
//
//  Created by Devanshu Singh(chitkara)     on 19/02/25.
//

import SwiftUI
import FirebaseFirestore

struct IssuedBooksView: View {
    @Environment(\.dismiss) var dismiss
    @State private var issuedBooks: [IssuedBook] = []
    @State private var isLoading = true
    
    // Simplified Book Model for Issued Books
    struct IssuedBook: Identifiable {
        let id: String
        let title: String
        let authors: [String]
        let coverImageUrl: String?
        let dueDate: Date
        let status: String
        let borrowerId: String
        
        var daysLeft: Int {
            Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
        }
        
        var isOverdue: Bool {
            daysLeft < 0
        }
        
        var formattedDueDate: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: dueDate)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Stats Section
                        UserProfileSection(
                            totalBooks: issuedBooks.count,
                            dueSoonBooks: issuedBooks.filter { $0.daysLeft <= 3 && !$0.isOverdue }.count
                        )
                        
                        // Books List
                        if isLoading {
                            ProgressView()
                                .padding()
                        } else if issuedBooks.isEmpty {
                            Text("No books currently issued")
                                .foregroundColor(.gray)
                                .padding()
                        } else {
                            VStack(spacing: 16) {
                                ForEach(issuedBooks) { book in
                                    IssuedBookRow(book: book, onReturn: { returnBook(book) })
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Issued Books")
            
        }
        .onAppear {
            fetchIssuedBooks()
        }
    }
    
    private func fetchIssuedBooks() {
        let db = Firestore.firestore()
        db.collection("books")
            .whereField("status", isEqualTo: "borrowed")
            .addSnapshotListener { snapshot, error in
                isLoading = false
                
                if let error = error {
                    print("Error fetching books: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.issuedBooks = documents.compactMap { document -> IssuedBook? in
                    let data = document.data()
                    return IssuedBook(
                        id: document.documentID,
                        title: data["title"] as? String ?? "",
                        authors: data["authors"] as? [String] ?? [],
                        coverImageUrl: data["coverImageUrl"] as? String,
                        dueDate: (data["dueDate"] as? Timestamp)?.dateValue() ?? Date(),
                        status: data["status"] as? String ?? "",
                        borrowerId: data["borrowerId"] as? String ?? ""
                    )
                }
            }
    }
    
    private func returnBook(_ book: IssuedBook) {
        let db = Firestore.firestore()
        db.collection("books").document(book.id).updateData([
            "status": "available",
            "borrowerId": "",
            "dueDate": nil
        ]) { error in
            if let error = error {
                print("Error returning book: \(error.localizedDescription)")
            }
        }
    }
}

struct UserProfileSection: View {
    let totalBooks: Int
    let dueSoonBooks: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                StatItem(value: "\(totalBooks)", label: "Total Books")
                StatItem(
                    value: "\(dueSoonBooks)",
                    label: "Due Soon",
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .yellow
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct StatItem: View {
    let value: String
    let label: String
    var icon: String? = nil
    var iconColor: Color = .blue
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                }
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct IssuedBookRow: View {
    let book: IssuedBooksView.IssuedBook
    let onReturn: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Book Cover
            if let coverUrl = book.coverImageUrl,
               let url = URL(string: coverUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 60, height: 80)
                .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 80)
                    .cornerRadius(8)
            }
            
            // Book Details
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.system(size: 16, weight: .medium))
                
                Text(book.authors.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                    Text("Due: \(book.formattedDueDate)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text(book.isOverdue ? "Overdue" : "\(book.daysLeft) days left")
                    .font(.caption)
                    .foregroundColor(book.isOverdue ? .red : .gray)
            }
            
            Spacer()
            
            // Return Button
            Button(action: onReturn) {
                Text("Return")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    IssuedBooksView()
}
