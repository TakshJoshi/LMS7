////
////  WishlistView.swift
////  new
////
////  Created by Divya Arora on 19/02/25.
////

import SwiftUI

struct WishlistView: View {
    var body: some View {
//      UserMainTabView()
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Wishlist Items
                    WishlistItemView(
                        imageName: "midnight library",
                        title: "The Midnight Library",
                        author: "Matt Haig",
                        description: "Between life and death there is a library, and within that library, the...",
                        genre: "Fiction, Fantasy"
                    )
                    
                    WishlistItemView(
                        imageName: "atomic habbits",
                        title: "Atomic Habits",
                        author: "James Clear",
                        description: "Transform your life with tiny changes in behavior, starting now.",
                        genre: "Self-Help, Personal Development"
                    )
                    
                    WishlistItemView(
                        imageName: "project hail mary",
                        title: "Project Hail Mary",
                        author: "Andy Weir",
                        description: "A lone astronaut must save humanity from a catastrophic...",
                        genre: "Science Fiction, Adventure"
                    )
                }
                .padding(.top, 10)
            }
            .navigationTitle("Wishlist") // Navigation title when scrolled up
           // .navigationBarTitleDisplayMode(.inline) // Keeps it compact in the navbar
        }
    }
}



// Wishlist Item View (Updated)
struct WishlistItemView: View {
    var imageName: String
    var title: String
    var author: String
    var description: String
    var genre: String
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading) {
                HStack(spacing: 12) {
                    // Book Image
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 120)
                        .cornerRadius(10)
                        .clipped()
                    
                    // Book Details
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        Text(author)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text(description)
                            .font(.footnote)
                            .foregroundColor(.black)
                            .lineLimit(2)
                        
                        // Preview Button
                        Button(action: {
                            // Preview action
                        }) {
                            HStack {
                                Image(systemName: "book.fill")
                                Text("Preview")
                            }
                            .font(.footnote)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                
                // Genre Section
                HStack {
                    VStack(alignment: .leading) {
                        Text("Genre")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        Text(genre)
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
                
                Divider()
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            .padding(.horizontal)
            
            // Cross Button at Top Right Corner
            Button(action: {
                // Action to remove item from wishlist
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .padding(19)
            }
        }
    }
}

#Preview {
    WishlistView()
}


//
//  WishlistView.swift
//  new
//
//  Created by Divya Arora on 19/02/25.
//


//i
