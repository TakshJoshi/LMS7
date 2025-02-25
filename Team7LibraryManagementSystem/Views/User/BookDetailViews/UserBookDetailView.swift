import SwiftUI
import FirebaseFirestore

struct UserBookDetailView: View {
    let isbn13: String
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    @State private var book: Book?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showFullDescription = false

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else if let book = book {
                VStack(alignment: .leading, spacing: 16) {
                    // Book Cover
                    if let imageUrl = book.coverImageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(height: 220)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .padding(.top)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }

                    // Book Title & Author
                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("by \(book.authors.joined(separator: ", "))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    // Tags (Left-Aligned)
                    if let categories = book.categories {
                        HStack {
                            ForEach(categories, id: \.self) { category in
                                Text(category)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }

                    // ISBN
                    if let isbn = book.isbn13 {
                        Text("ISBN: \(isbn)")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Circle()
                            .fill(book.isAvailable ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        Text(book.isAvailable ? "Available" : "Not Available")
                            .foregroundColor(book.isAvailable ? .green : .red)
                    }

                    // Description Section
                    if let description = book.description {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Description")
                                .font(.headline)
                            
                            Text(description)
                                .foregroundColor(.gray)
                                .lineLimit(3)

                            Button(action: {
                                showFullDescription.toggle()
                            }) {
                                Text("More")
                                    .font(.footnote)
                                    .foregroundColor(.blue)
                            }
                        }
                    }

                    // Book Details (Grid Layout)
                    LazyVGrid(columns: columns, spacing: 12) {
                        DetailView(title: "Publisher", value: book.publisher ?? "N/A")
                        DetailView(title: "Language", value: book.language ?? "N/A")
                        DetailView(title: "Pages", value: "\(book.pageCount ?? 0)")
                        DetailView(title: "Published Date", value: book.publishedDate ?? "N/A")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)

                    // Availability Indicator

                    
                    // Buttons
                    HStack(spacing: 16) {
                        // Navigate to Pre-Book View
                        NavigationLink(destination: PreBookView(isbn: book.isbn13 ?? "-1")) {
                            Text("Pre-Book")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        // Navigate to Preview View
                    //    NavigationLink(destination: "") {
                            Text("Preview")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.blue)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue, lineWidth: 2)
                                )
                       // }
                    }

                    .padding(.top, 16)
                }
                .padding()
            } else {
                Text(errorMessage ?? "Book not found")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .navigationTitle("Book Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFullDescription) {
            FullDescriptionView(description: book?.description ?? "")
        }
        .onAppear {
            fetchBookDetails()
        }
    }

    private func fetchBookDetails() {
        let db = Firestore.firestore()
        db.collection("books").whereField("isbn13", isEqualTo: isbn13).getDocuments { snapshot, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                return
            }
            
            guard let document = snapshot?.documents.first else {
                self.errorMessage = "No book found"
                self.isLoading = false
                return
            }
            
            do {
                self.book = try document.data(as: Book.self)
            } catch {
                self.errorMessage = "Failed to parse book data"
            }
            
            self.isLoading = false
        }
    }
}


// MARK: - DetailView Component
struct DetailView: View {
    let title: String
    let value: String

    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.body)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

// MARK: - Full Description Modal View
struct FullDescriptionView: View {
    var description: String
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Description")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(description)
                        .foregroundColor(.gray)
                        .padding(.top, 5)
                }
                .padding()
            }
            .navigationTitle("Full Description")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true)
                    }
                }
            }
        }
    }
}

