import SwiftUI
import Firebase

struct WishlistView: View {
    @State private var books: [Book] = []
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    if books.isEmpty {
                        Text("Your wishlist is empty.")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ForEach(books, id: \.id) { book in
                            
                            NavigationLink(destination: BookDetailView(book: book)) {
                                WishlistItemView(book: book)
                                    .padding(.horizontal)
                                    .padding(.vertical, 6) // Adds space between cards
                            } // Adds space between cards
                        }
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Wishlist")
            .onAppear {
                fetchBooksFromWishlist()
            }
        }
    }
    
    private func fetchBooksFromWishlist() {
      //  let userId = "3vdPNzYHz3T7k6fqbmGrkLondNz2" // Hardcoded for now
        var userId: String {
            UserDefaults.standard.string(forKey: "userId") ?? ""
        }
        db.collection("wishlist")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching wishlist: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("❌ No wishlist items found for userId: \(userId)")
                    return
                }
                
                let bookIds = documents.compactMap { $0.data()["bookId"] as? String }
                
                DispatchQueue.main.async {
                    self.books.removeAll()
                }
                
                let dispatchGroup = DispatchGroup()
                
                for bookId in bookIds {
                    dispatchGroup.enter()
                    
                    db.collection("books").whereField("bookId", isEqualTo: bookId).getDocuments { snapshot, error in
                        defer { dispatchGroup.leave() }
                        
                        if let error = error {
                            print("❌ Error fetching book \(bookId): \(error.localizedDescription)")
                            return
                        }
                        
                        guard let document = snapshot?.documents.first else {
                            print("❌ No book found for bookId: \(bookId)")
                            return
                        }
                        
                        do {
                            let book = try document.data(as: Book.self)
                            DispatchQueue.main.async {
                                self.books.append(book)
                            }
                        } catch {
                            print("❌ Error decoding book \(bookId): \(error)")
                        }
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    print("✅ All books fetched and updated!")
                }
            }
    }
}

struct WishlistItemView: View {
    var book: Book
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 8) {
                // Placeholder Image (Replace with AsyncImage if fetching from URL)
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 110)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(book.title)
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Text(book.authors.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(book.description ?? "")
                        .font(.footnote)
                        .foregroundColor(.black)
                        .lineLimit(2)
                    
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
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Genre")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Text("Fiction")
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
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.vertical, 6) // Space between cards
    }
}

struct Wishlist_Previews: PreviewProvider {
    static var previews: some View {
        WishlistView()
    }
}
