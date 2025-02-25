import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MyBooksView: View {
    @State private var issuedBooks: [Book] = []
    let columns = [GridItem(.flexible()), GridItem(.flexible())] // Two-column grid layout
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(issuedBooks, id: \.id) { book in
                            MyBookCardView(
                                imageName: book.coverImageUrl ?? "default_cover",
                                title: book.title,
                                author: book.authors.first ?? "Unknown Author",
                                description: book.description ?? "No description available.",
                                status: book.status,
                                statusColor: getStatusColor(for: book.status),
                                fine: book.status == "Overdue" ? "₹50" : nil
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                //.padding(.top, 10)
            }
            .navigationTitle("My Books")
            .onAppear {
                fetchIssuedBookISBNs()
            }
        }
    }
    
    /// Fetches issued books for the logged-in user
//    private func fetchIssuedBookISBNs() {
//        let db = Firestore.firestore()
//        guard let userEmail = Auth.auth().currentUser?.email else {
//            print("No logged-in user found")
//            return
//        }
//        
//        db.collection("issued_books").whereField("email", isEqualTo: userEmail).getDocuments { snapshot, error in
//            if let error = error {
//                print("Error fetching issued book ISBNs: ", error)
//                return
//            }
//            
//            // Extract ISBNs and statuses from issued_books collection
//            let issuedBooksData = snapshot?.documents.compactMap { doc -> (String, String)? in
//                if let isbn = doc.data()["isbn13"] as? String,
//                   let status = doc.data()["status"] as? String {
//                    return (isbn, status)
//                }
//                return nil
//            } ?? []
//            
//            fetchBookDetails(issuedBooksData)
//        }
//    }
    
    
    /// Fetches both issued and prebooked books for the logged-in user
    private func fetchIssuedBookISBNs() {
        let db = Firestore.firestore()
        guard let userEmail = Auth.auth().currentUser?.email else {
            print("No logged-in user found")
            return
        }
        
        var allBooksData: [(String, String)] = []

        let dispatchGroup = DispatchGroup()
        
        // Fetch issued books
        dispatchGroup.enter()
        db.collection("issued_books").whereField("email", isEqualTo: userEmail).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching issued book ISBNs: ", error)
            } else {
                let issuedBooksData = snapshot?.documents.compactMap { doc -> (String, String)? in
                    if let isbn = doc.data()["isbn13"] as? String,
                       let status = doc.data()["status"] as? String {
                        return (isbn, status)
                    }
                    return nil
                } ?? []
                
                allBooksData.append(contentsOf: issuedBooksData)
            }
            dispatchGroup.leave()
        }
        
        // Fetch prebooked books
        dispatchGroup.enter()
        db.collection("PreBook").whereField("userEmail", isEqualTo: userEmail).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching prebooked books: ", error)
            } else {
                let prebookedBooksData = snapshot?.documents.compactMap { doc -> (String, String)? in
                    if let isbn = doc.data()["isbn13"] as? String,
                       let prebookStatus = doc.data()["status"] as? String {
                        
                        // Determine display status based on prebook status
                        let displayStatus: String
                        switch prebookStatus {
                        case "Pending":
                            displayStatus = "PreBooked"
                        case "Time Over":
                            displayStatus = "Not Collected"
                        case "Confirmed":
                            displayStatus = "PreBook Confirmed"
                        default:
                            displayStatus = "Unknown"
                        }
                        
                        return (isbn, displayStatus)
                    }
                    return nil
                } ?? []
                
                allBooksData.append(contentsOf: prebookedBooksData)
            }
            dispatchGroup.leave()
        }
        
        // Once both issued and prebooked books are fetched, retrieve their details
        dispatchGroup.notify(queue: .main) {
            fetchBookDetails(allBooksData)
        }
    }

//
    /// Fetches book details from the "books" collection using ISBNs
    private func fetchBookDetails(_ issuedBooksData: [(String, String)]) {
        let db = Firestore.firestore()
        let isbnList = issuedBooksData.map { $0.0 } // Extract ISBNs only
        
        guard !isbnList.isEmpty else {
            print("No ISBNs found for issued books")
            return
        }
        
        db.collection("books").whereField("isbn13", in: isbnList).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching book details: ", error)
                return
            }
            
            let bookData = snapshot?.documents.compactMap { doc -> Book? in
                let data = doc.data()
                let isbn = data["isbn13"] as? String ?? ""
                
                // Get status from issuedBooksData
                let status = issuedBooksData.first(where: { $0.0 == isbn })?.1 ?? "Unknown"
                
                return Book(
                    id: data["bookId"] as? String ?? UUID().uuidString,
                    title: data["title"] as? String ?? "Unknown Title",
                    authors: data["authors"] as? [String] ?? ["Unknown Author"],
                    publisher: data["publisher"] as? String,
                    publishedDate: data["publishedDate"] as? String,
                    description: data["description"] as? String,
                    pageCount: data["pageCount"] as? Int,
                    categories: data["categories"] as? [String],
                    coverImageUrl: data["coverImageUrl"] as? String,
                    isbn13: isbn,
                    language: data["language"] as? String,
                    quantity: data["quantity"] as? Int ?? 0,
                    availableQuantity: data["availableQuantity"] as? Int ?? 0,
                    location: data["location"] as? String ?? "Unknown",
                    status: status, // Set independent status
                    totalCheckouts: data["totalCheckouts"] as? Int ?? 0,
                    currentlyBorrowed: data["currentlyBorrowed"] as? Int ?? 0,
                    isAvailable: data["isAvailable"] as? Bool ?? false,
                    libraryId: data["libraryId"] as? String
                )
            } ?? []
            
            issuedBooks = bookData
        }
    }
    
    /// Helper function to return color based on book status
//    private func getStatusColor(for status: String) -> Color {
//        switch status {
//        case "Borrowed":
//            return .green
//        case "Returned":
//            return .gray
//        case "Overdue":
//            return .red
//        default:
//            return .gray
//        }
//    }
    
    private func getStatusColor(for status: String) -> Color {
        switch status {
        case "Borrowed":
            return .green
        case "Returned":
            return .gray
        case "Overdue":
            return .red
        case "PreBooked":
            return .blue
        case "Not Collected":
            return .orange
        case "PreBook Confirmed":
            return .green
        default:
            return .gray
        }
    }

    
    struct MyBookCardView: View {
        var imageName: String
        var title: String
        var author: String
        var description: String
        var status: String
        var statusColor: Color
        var fine: String? = nil
        
        var body: some View {
            VStack(alignment: .leading) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180) // Ensuring equal width
                    .cornerRadius(10)
                    .padding(.horizontal, 10) // Equal left and right padding
                
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
                
                Spacer()
                
                // Status Badge
                HStack(spacing: 8) {
                    Text(status)
                        .font(.footnote)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(8)
                    
                    if let fine = fine {
                        Text("Fine: \(fine)")
                            .font(.footnote)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                    }
                }
            }
            .frame(maxWidth: .infinity) // Ensuring equal width for all cards
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.530), radius: 2, x: 0, y: 1)
        }
    }
}

#Preview{
    MyBooksView()
}
