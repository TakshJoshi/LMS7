


import SwiftUI
import FirebaseFirestore

struct UserHomeView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeScreen()
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }

            NavigationStack {
                MyBooksScreen()
            }
            .tabItem {
                Image(systemName: "book.fill")
                Text("My Books")
            }

            NavigationStack {
                WishlistView()
            }
            .tabItem {
                Image(systemName: "heart.fill")
                Text("Wishlist")
            }

            NavigationStack {
                UserEventsView()
            }
            .tabItem {
                Image(systemName: "calendar")
                Text("Events")
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

import SwiftUI
import FirebaseFirestore

struct HomeScreen: View {
    @StateObject private var booksViewModel = BooksViewModel()
    @State private var searchText = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .padding(.leading, 10)

                    TextField("Search", text: $searchText)
                        .padding(5)
                }
                .padding(1)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)

                // Books You May Like Section
                if booksViewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    BooksSection(
                        title: "Books You May Like",
                        books: recommendedBooks
                    )

                    QuoteCard(
                        text: "A reader lives a thousand lives before he dies.",
                        author: "George R.R. Martin"
                    )
                    .padding(.horizontal)

                    // Trending Books Section
                    BooksSection(
                        title: "Trending Books",
                        books: trendingBooks
                    )
                }
            }
            .padding(.top)
            .onAppear {
                booksViewModel.fetchBooks()
            }
            .navigationTitle("HOME")
        }
    }
    
    // Computed property for recommended books
    private var recommendedBooks: [Book] {
        // You can implement more sophisticated recommendation logic
        return booksViewModel.books.shuffled().prefix(5).map { $0 }
    }
    
    // Computed property for trending books
    private var trendingBooks: [Book] {
        // Sort by total checkouts or implement more complex trending logic
        return booksViewModel.books
            .sorted { $0.totalCheckouts > $1.totalCheckouts }
            .prefix(5)
            .map { $0 }
    }
}

// Books Section View
struct BooksSection: View {
    let title: String
    let books: [Book]
    @StateObject private var wishlistManager = WishlistManager()
    
    var body: some View {
        VStack(alignment: .leading) {
            SectionHeader(title: title)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(books) { book in
                        NavigationLink(destination: UserBookDetailView(book: book,wishlistManager: wishlistManager)) {
                            UserBookCard(book: book,wishlistManager: wishlistManager)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// Books View Model
class BooksViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchBooks() {
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        db.collection("books").getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Error fetching books: \(error.localizedDescription)"
                return
            }
            
            guard let documents = snapshot?.documents else {
                self.errorMessage = "No books found"
                return
            }
            
            self.books = documents.compactMap { document -> Book? in
                let data = document.data()
                
                return Book(
                    id: (data["bookId"] as? String)!,
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
                    isAvailable: data["isAvailable"] as? Bool ?? true
                )
            }
        }
    }
}




struct UserBookDetailView: View {
    let book: Book
    @State private var isLiked = false
    @ObservedObject var wishlistManager: WishlistManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Book Cover
                if let coverImageUrl = book.coverImageUrl,
                   let url = URL(string: coverImageUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(height: 300)
                    .cornerRadius(10)
                }

                // Book Title and Author
                VStack(alignment: .leading, spacing: 8) {
                    Text(book.title)
                        .font(.title)
                        .fontWeight(.bold)

                    Text(book.authors.joined(separator: ", "))
                        .foregroundColor(.secondary)
                }

                // Action Buttons
                HStack {
                    Button(action: {
                        if isLiked {
                            wishlistManager.removeFromWishlist(bookId: book.id)
                        } else {
                            wishlistManager.addToWishlist(bookId: book.id)
                        }
                        isLiked.toggle()
                    }) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .gray)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Text("Borrow")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            wishlistManager.checkIfBookIsInWishlist(bookId: book.id) { isInWishlist in
                self.isLiked = isInWishlist
            }
        }
    }
}

// Helper Detail Row View
struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 25)
            
            Text("\(label):")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
        }
    }
}
struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.headline)
            .padding(.horizontal)
    }
}

struct UserBookCard: View {
    let book: Book
    @State private var isBookInWishlist = false
    @ObservedObject var wishlistManager: WishlistManager

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: book.coverImageUrl ?? "")) { image in
                    image.resizable()
                } placeholder: {
                    Image(systemName: "book.closed")
                        .resizable()
                        .foregroundColor(.gray)
                }
                .scaledToFit()
                .frame(width: 140, height: 110)
                .cornerRadius(10)

                // Like Button
                Button(action: {
                    if isBookInWishlist {
                        wishlistManager.removeFromWishlist(bookId: book.id)
                    } else {
                        wishlistManager.addToWishlist(bookId: book.id)
                    }
                    isBookInWishlist.toggle() // UI State Update
                }) {
                    Image(systemName: isBookInWishlist ? "heart.fill" : "heart")
                        .foregroundColor(isBookInWishlist ? .red : .gray)
                        .padding(8)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .offset(x: 18, y: -12)
            }
            .frame(maxWidth: .infinity, alignment: .topTrailing)

            Text(book.title)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
           
            if let author = book.authors.first {
                Text(author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text(book.description ?? "No description available")
                .font(.footnote)
                .foregroundColor(.gray)
                .lineLimit(2)

            Spacer()
        }
        .frame(width: 160, height: 230)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 5)
        .onAppear {
            wishlistManager.checkIfBookIsInWishlist(bookId: book.id) { isInWishlist in
                self.isBookInWishlist = isInWishlist
            }
        }
    }
}


struct MyBooksScreen: View {
    var body: some View {
        VStack {
            Text("My Books")
                .font(.largeTitle)
            
            NavigationLink(destination: UserBookDetailView2(title: "Book 1", author: "Author 1")) {
                Text("Go to Book Detail")
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .navigationTitle("My Books")
    }
}

struct QuoteCard: View {
    let text: String
    let author: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("“")
                .font(.largeTitle)
                .foregroundColor(.blue)

            Text(text)
                .font(.body)
                .foregroundColor(.primary)

            Text("- \(author)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}



struct EventsScreen: View {
    var body: some View {
        VStack {
            Text("Events")
                .font(.largeTitle)
        }
        .navigationTitle("Events")
    }
}

// Book Detail Screen
struct UserBookDetailView2: View {
    let title: String
    let author: String

    var body: some View {
        VStack {
            Text(title)
                .font(.title)
                .fontWeight(.bold)

            Text("By \(author)")
                .font(.subheadline)
                .foregroundColor(.gray)

            Spacer()
        }
        .padding()
        .navigationTitle(title)
    }
}

// Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        UserHomeView()
    }
}
