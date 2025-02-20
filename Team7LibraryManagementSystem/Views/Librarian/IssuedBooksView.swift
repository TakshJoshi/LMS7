//
//  IssueBookView.swift
//  librarian
//
//  Created by Devanshu Singh(chitkara)     on 19/02/25.
//

import Foundation
import SwiftUI

struct IssuedBooksView: View {
    @Environment(\.dismiss) var dismiss
    
    let userProfile = UserProfile(
        name: "Sarah Johnson",
        profileImage: "profile_image",
        libraryId: "LIB-2024-0123",
        totalBooks: 5,
        dueSoonBooks: 2
    )
    
    let issuedBooks = [
        IssuedBook(
            title: "The Midnight Library",
            author: "Matt Haig",
            coverImage: "book1",
            dueDate: "Feb 15, 2024",
            daysLeft: 7,
            isOverdue: false
        ),
        IssuedBook(
            title: "Project Half Mary",
            author: "Andy Weir",
            coverImage: "book2",
            dueDate: "Feb 10, 2024",
            daysLeft: 2,
            isOverdue: false
        ),
        IssuedBook(
            title: "The Psychology of Money",
            author: "Morgan Housel",
            coverImage: "book3",
            dueDate: "Feb 5, 2024",
            daysLeft: 0,
            isOverdue: true
        ),
        IssuedBook(
            title: "Atomic Habits",
            author: "James Clear",
            coverImage: "book4",
            dueDate: "Feb 25, 2024",
            daysLeft: 12,
            isOverdue: false
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView()
                ScrollView {
                    VStack(spacing: 24) {
                        // User Profile Section
                        UserProfileSection(profile: userProfile)
                        
                        // Books List
                        IssuedBooksList(books: issuedBooks)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Issued Books")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}

struct headerView: View {
    var body: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.black)
            }
            
            Text("Issued Books")
                .font(.title3)
                .fontWeight(.bold)
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

struct UserProfileSection: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Info
            HStack(spacing: 12) {
                Image(profile.profileImage)
                    .resizable()
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .font(.headline)
                    
                    Text(profile.libraryId)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            // Stats
            HStack(spacing: 24) {
                StatItem(value: "\(profile.totalBooks)", label: "Total Books")
                StatItem(value: "\(profile.dueSoonBooks)", label: "Due Soon", icon: "exclamationmark.triangle.fill", iconColor: .yellow)
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
        HStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
            }
        }
        VStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct IssuedBooksList: View {
    let books: [IssuedBook]
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(books) { book in
                IssuedBookRow(book: book)
            }
        }
    }
}

struct IssuedBookRow: View {
    let book: IssuedBook
    
    var body: some View {
        HStack(spacing: 16) {
            // Book Cover
            Image(book.coverImage)
                .resizable()
                .frame(width: 60, height: 80)
                .cornerRadius(8)
            
            // Book Details
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.system(size: 16, weight: .medium))
                
                Text(book.author)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                    Text("Due: \(book.dueDate)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text(book.isOverdue ? "Overdue" : "\(book.daysLeft) days left")
                    .font(.caption)
                    .foregroundColor(book.isOverdue ? .red : .gray)
            }
            
            Spacer()
            
            // Return Button
            Button(action: {}) {
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


