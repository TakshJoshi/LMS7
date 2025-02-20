//
//  AddBooksView.swift
//  Team7LibraryManagementSystem
//
//  Created by Taksh Joshi on 18/02/25.
//

import SwiftUI
import FirebaseFirestore

struct AddBookView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchQuery = ""
    @State private var searchResults: [Book] = []
    @State private var selectedBook: Book?
    @State private var quantity = "1"
    @State private var location = ""
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var showAlert = false
    @State private var showingAddBook = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search Bar
                HStack {
                    TextField("Search by title, author, or ISBN", text: $searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: searchBooks) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .padding()
                
                if isSearching {
                    ProgressView("Searching...")
                        .padding()
                } else if let selectedBook = selectedBook {
                    // Selected Book Details View
                    BookDetailsView(
                        book: selectedBook,
                        quantity: $quantity,
                        location: $location,
                        onSave: addBookToLibrary,
                        onCancel: { self.selectedBook = nil }
                    )
                } else {
                    // Search Results
                    SearchResultsView(
                        searchResults: searchResults,
                        onBookSelect: { book in
                            selectedBook = book
                        }
                    )
                }
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
            .sheet(isPresented: $showingAddBook) {
                AddBookView()
            }
        }
    }
    
    private func searchBooks() {
        guard !searchQuery.isEmpty else { return }
        isSearching = true
        searchResults.removeAll()
        
        let query = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://www.googleapis.com/books/v1/volumes?q=\(query)&key=YOUR_API_KEY"  // Add your API key
        
        guard let url = URL(string: urlString) else {
            isSearching = false
            errorMessage = "Invalid search query"
            showAlert = true
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.isSearching = false
                    self.errorMessage = error.localizedDescription
                    self.showAlert = true
                    return
                }
                
                guard let data = data else {
                    self.isSearching = false
                    self.errorMessage = "No data received"
                    self.showAlert = true
                    return
                }
                
                // Print the raw response for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw API Response:", jsonString)
                }
                
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(GoogleBooksResponse.self, from: data)
                    
                    guard let items = response.items else {
                        self.searchResults = []
                        self.isSearching = false
                        return
                    }
                    
                    self.searchResults = items.compactMap { volume in
                        return Book(
                            id: volume.id,
                            title: volume.volumeInfo.title,
                            authors: volume.volumeInfo.authors ?? [],
                            publisher: volume.volumeInfo.publisher,
                            publishedDate: volume.volumeInfo.publishedDate,
                            description: volume.volumeInfo.description,
                            pageCount: volume.volumeInfo.pageCount,
                            categories: volume.volumeInfo.categories,
                            coverImageUrl: volume.volumeInfo.imageLinks?.thumbnail ?? volume.volumeInfo.imageLinks?.smallThumbnail,
                            isbn13: volume.volumeInfo.industryIdentifiers?.first(where: { $0.type == "ISBN_13" })?.identifier,
                            language: volume.volumeInfo.language,
                            quantity: 0,
                            availableQuantity: 0,
                            location: "",
                            status: "available",
                            totalCheckouts: 0,
                            currentlyBorrowed: 0,
                            isAvailable: true
                        )
                    }
                    self.isSearching = false
                } catch {
                    print("Decoding error:", error)
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, _):
                            print("Missing key:", key)
                        case .valueNotFound(let type, _):
                            print("Missing value of type:", type)
                        case .typeMismatch(let type, _):
                            print("Type mismatch for type:", type)
                        default:
                            print("Other decoding error:", decodingError)
                        }
                    }
                    self.isSearching = false
                    self.errorMessage = "Failed to parse response. Please try again."
                    self.showAlert = true
                }
            }
        }.resume()
    }
    
    private func addBookToLibrary() {
        guard let book = selectedBook else { return }
        guard let quantityInt = Int(quantity), quantityInt > 0 else {
            errorMessage = "Please enter a valid quantity"
            showAlert = true
            return
        }
        
        let db = Firestore.firestore()
        let bookData: [String: Any] = [
            "bookId": book.id,
            "title": book.title,
            "authors": book.authors,
            "publisher": book.publisher ?? "",
            "publishedDate": book.publishedDate ?? "",
            "description": book.description ?? "",
            "pageCount": book.pageCount ?? 0,
            "categories": book.categories ?? [],
            "coverImageUrl": book.coverImageUrl ?? "",
            "isbn13": book.isbn13 ?? "",
            "language": book.language ?? "",
            
            "quantity": quantityInt,
            "availableQuantity": quantityInt,
            "location": location,
            "addedDate": Timestamp(),
            "lastUpdated": Timestamp(),
            "status": "available",
            
            "totalCheckouts": 0,
            "currentlyBorrowed": 0,
            "isAvailable": true
        ]
        
        db.collection("books")
            .whereField("isbn13", isEqualTo: book.isbn13 ?? "")
            .getDocuments { snapshot, error in
                if let error = error {
                    self.errorMessage = "Error checking book: \(error.localizedDescription)"
                    self.showAlert = true
                    return
                }
                
                if let existingBook = snapshot?.documents.first {
                    let currentQuantity = existingBook.data()["quantity"] as? Int ?? 0
                    let currentAvailable = existingBook.data()["availableQuantity"] as? Int ?? 0
                    
                    existingBook.reference.updateData([
                        "quantity": currentQuantity + quantityInt,
                        "availableQuantity": currentAvailable + quantityInt,
                        "lastUpdated": Timestamp()
                    ]) { error in
                        if let error = error {
                            self.errorMessage = "Error updating book: \(error.localizedDescription)"
                            self.showAlert = true
                        } else {
                            self.dismiss()
                        }
                    }
                } else {
                    db.collection("books").addDocument(data: bookData) { error in
                        if let error = error {
                            self.errorMessage = "Error adding book: \(error.localizedDescription)"
                            self.showAlert = true
                        } else {
                            let inventoryData: [String: Any] = [
                                "bookId": book.id,
                                "totalCopies": quantityInt,
                                "availableCopies": quantityInt,
                                "location": location,
                                "lastInventoryDate": Timestamp()
                            ]
                            
                            db.collection("inventory").addDocument(data: inventoryData) { error in
                                if let error = error {
                                    print("Error creating inventory: \(error.localizedDescription)")
                                }
                                self.dismiss()
                            }
                        }
                    }
                }
            }
    }
}

struct SearchResultsView: View {
    let searchResults: [Book]
    let onBookSelect: (Book) -> Void
    
    var body: some View {
        if searchResults.isEmpty {
            Text("No books found")
                .foregroundColor(.gray)
                .padding()
        } else {
            List(searchResults) { book in
                Button(action: { onBookSelect(book) }) {
                    HStack(spacing: 12) {
                        // Book Cover with safe image loading
                        if let imageUrl = book.getImageUrl() {
                            AsyncImage(url: imageUrl) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 60, height: 80)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 60, height: 80)
                            }
                            .cornerRadius(4)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(book.title)
                                .font(.headline)
                            if !book.authors.isEmpty {
                                Text(book.authors.joined(separator: ", "))
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            if let publisher = book.publisher {
                                Text(publisher)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}
struct BookDetailsView: View {
    let book: Book
    @Binding var quantity: String
    @Binding var location: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Book Cover
                BookImageView(
                    url: book.getImageUrl(),
                    width: UIScreen.main.bounds.width - 32,
                    height: 300
                )
                
                // Book Details
                VStack(alignment: .leading, spacing: 10) {
                    Text(book.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("By " + book.authors.joined(separator: ", "))
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if let publisher = book.publisher {
                        Text("Publisher: \(publisher)")
                            .font(.subheadline)
                    }
                    
                    if let publishedDate = book.publishedDate {
                        Text("Published: \(publishedDate)")
                            .font(.subheadline)
                    }
                    
                    if let isbn = book.isbn13 {
                        Text("ISBN: \(isbn)")
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal)
                
                // Quantity and Location Inputs
                VStack(spacing: 15) {
                    TextField("Quantity", text: $quantity)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                    
                    TextField("Shelf Location", text: $location)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                // Action Buttons
                HStack {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("Add to Library") {
                        onSave()
                    }
                    .disabled(quantity.isEmpty || location.isEmpty)
                }
                .padding()
            }
        }
    }
}

// Utility Image View
