//
//  SwiftUIView.swift
//  Team7LibraryManagementSystem
//
//  Created by Taksh Joshi on 19/02/25.
//

import SwiftUI
import FirebaseFirestore

struct BookDetailView: View {
    let book: Book
    @Environment(\.dismiss) var dismiss
    @State private var showMoreDescription = false
    @State private var availableBooks: Int
    @State private var currentlyBorrowed: Int
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAlert = false
    
    init(book: Book) {
        self.book = book
        _availableBooks = State(initialValue: book.availableQuantity)
        _currentlyBorrowed = State(initialValue: book.currentlyBorrowed)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Book Cover
                //print("Book Image URL: \(book.getImageUrl())")
                
                BookImageView(
                    url: book.getImageUrl(),
                    width: UIScreen.main.bounds.width - 32,
                    height: 300
                )
//                .onAppear {
//                    print("Book Image URL: \(book.getImageUrl())")
//                }
                
                
                // Book Title and Author
                Text(book.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("By " + (book.authors.joined(separator: ", ")))
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                // Book Details
                Group {
                    if let publisher = book.publisher {
                        Text("Publisher: \(publisher)")
                    }
                    if let publishedDate = book.publishedDate {
                        Text("Published: \(publishedDate)")
                    }
                    if let isbn = book.isbn13 {
                        Text("ISBN: \(isbn)")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                // Available Books
                Text("Available Books: \(availableBooks)")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .padding(.vertical, 10)
                
                // Borrow and Return Buttons
                HStack(spacing: 20) {
                    Button(action: borrowBook) {
                        Text("Borrow Book")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(availableBooks > 0 ? Color.blue : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(availableBooks == 0 || isLoading)
                    
                    Button(action: returnBook) {
                        Text("Return Book")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(currentlyBorrowed > 0 ? Color.green : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(currentlyBorrowed == 0 || isLoading)
                }
                .padding(.vertical, 10)
                
                // Description Section
                if let description = book.description {
                    descriptionSection(description)
                }
                
                // Delete Book Button
                Button(action: deleteBook) {
                    Text("Delete Book")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding(.vertical, 10)
            }
            .padding()
        }
        .navigationTitle("Book Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    @ViewBuilder
    private func descriptionSection(_ description: String) -> some View {
        Button(action: {
            withAnimation {
                showMoreDescription.toggle()
            }
        }) {
            HStack {
                Text(showMoreDescription ? "Hide Description" : "Show More")
                    .font(.headline)
                    .foregroundColor(.blue)
                Spacer()
                Image(systemName: showMoreDescription ? "chevron.up" : "chevron.down")
                    .foregroundColor(.blue)
            }
            .padding()
        }
        
        if showMoreDescription {
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
    }
    
    private func borrowBook() {
        guard availableBooks > 0 else { return }
        
        isLoading = true
        let db = Firestore.firestore()
        
        let bookRef = db.collection("books").document(book.id)
        
        bookRef.updateData([
            "availableQuantity": FieldValue.increment(Int64(-1)),
            "currentlyBorrowed": FieldValue.increment(Int64(1)),
            "lastUpdated": Timestamp()
        ]) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Failed to borrow book: \(error.localizedDescription)"
                showAlert = true
            } else {
                availableBooks -= 1
                currentlyBorrowed += 1
            }
        }
    }
    
    private func returnBook() {
        guard currentlyBorrowed > 0 else { return }
        
        isLoading = true
        let db = Firestore.firestore()
        
        let bookRef = db.collection("books").document(book.id)
        
        bookRef.updateData([
            "availableQuantity": FieldValue.increment(Int64(1)),
            "currentlyBorrowed": FieldValue.increment(Int64(-1)),
            "lastUpdated": Timestamp()
        ]) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Failed to return book: \(error.localizedDescription)"
                showAlert = true
            } else {
                availableBooks += 1
                currentlyBorrowed -= 1
            }
        }
    }
    
    private func deleteBook() {
        isLoading = true
        let db = Firestore.firestore()
        
        db.collection("books").document(book.id).delete { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Failed to delete book: \(error.localizedDescription)"
                showAlert = true
            } else {
                dismiss()
            }
        }
    }
}
