//
//  UserProfileView.swift
//  Team7LibraryManagementSystem
//
//  Created by Hardik Bhardwaj on 27/02/25.
//


import SwiftUI
import FirebaseFirestore
struct UserProfileViewLibrarian: View {
    var userID: String // Passed from previous screen
    @State private var userName: String = "John Doe"
    @State private var userEmail: String = "user@example.com"
    @State private var totalFine: Double = 0.0
    @State private var borrowedBooks: [LibraryBookLibrarian] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                // User Info
                VStack {
                    Text(userName)
                        .font(.title)
                        .fontWeight(.bold)

                    Text(userEmail)
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 10)

                // Fine Card
                VStack(spacing: 5) {
                    Text("Total Imposed Fine")
                        .font(.headline)
                        .foregroundColor(.gray)

                    Text("$\(totalFine, specifier: "%.2f")")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(12)

                // Borrowed Books Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Borrowed Books")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    ForEach(borrowedBooks, id: \.isbn) { book in
                        BookCardLibrarian(book: book, returnAction: {
                                                  returnBook(email: userEmail, isbn: book.isbn)
                                              })
                    }
                }
                .padding(.top, 10)
            }
            .padding()
            .background(Color(.systemGray6))
        }
        .onAppear {
            fetchUserData()
        }
    }
    
    func returnBook(email: String, isbn: String) {
           let db = Firestore.firestore()

           db.collection("issued_books")
               .whereField("email", isEqualTo: email)
               .whereField("isbn13", isEqualTo: isbn)
               .getDocuments { snapshot, error in
                   guard let documents = snapshot?.documents, !documents.isEmpty, error == nil else {
                       print("❌ Error finding issued book: \(error?.localizedDescription ?? "Unknown error")")
                       return
                   }

                   for document in documents {
                       document.reference.updateData(["status": "Returned"]) { error in
                           if let error = error {
                               print("❌ Error updating book status: \(error.localizedDescription)")
                           } else {
                               print("✅ Book marked as Returned!")

                               // Update Available Quantity
                               updateBookAvailability(isbn: isbn, db: db)
                           }
                       }
                   }
               }
       }

       // Update Book Availability
       func updateBookAvailability(isbn: String, db: Firestore) {
           db.collection("books")
               .whereField("isbn13", isEqualTo: isbn)
               .getDocuments { snapshot, error in
                   guard let document = snapshot?.documents.first, error == nil else {
                       print("❌ Error fetching book for quantity update: \(error?.localizedDescription ?? "Unknown error")")
                       return
                   }

                   let currentQuantity = document.data()["availableQuantity"] as? Int ?? 0

                   document.reference.updateData(["availableQuantity": currentQuantity + 1]) { error in
                       if let error = error {
                           print("❌ Error updating available quantity: \(error.localizedDescription)")
                       } else {
                           print("✅ Book quantity updated successfully!")

                           DispatchQueue.main.async {
                               self.borrowedBooks.removeAll { $0.isbn == isbn }
                           }
                       }
                   }
               }
       }

    // Fetch User Email using `userId`
    func fetchUserEmail(userID: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        
        print("Fetching email for user ID: \(userID)")
        
        db.collection("users")
            .whereField("userId", isEqualTo: userID)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching user email: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    print("User document not found")
                    completion(nil)
                    return
                }
                
                let email = document.data()["email"] as? String
                completion(email)
            }
    }

    func fetchUserData() {
        let db = Firestore.firestore()
        
        fetchUserEmail(userID: userID) { email in
            guard let email = email else {
                print("Email not found")
                return
            }
            
            DispatchQueue.main.async {
                self.userEmail = email
            }

            print("Updated User Email: \(email)")
            
            // Now, fetch issued books AFTER the email is updated
            db.collection("issued_books")
                .whereField("email", isEqualTo: email) // Use updated email
                .getDocuments { snapshot, error in
                    guard let documents = snapshot?.documents, error == nil else {
                        print("Error fetching issued books: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    
                    var totalFineAmount: Double = 0
                    var bookISBNs: [String] = []
                    
                    for document in documents {
                        let data = document.data()
                        totalFineAmount += (data["fine"] as? Double ?? 0)
                        if let isbn = data["isbn13"] as? String {
                            bookISBNs.append(isbn)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.totalFine = totalFineAmount
                    }

                    // Fetch book details only if ISBNs exist
                    if !bookISBNs.isEmpty {
                        self.fetchBookDetails(isbns: bookISBNs)
                    } else {
                        print("No books found for user.")
                    }
                }
        }
    }


    // Fetch issued books for a specific email
    func fetchIssuedBooks(for email: String) {
        let db = Firestore.firestore()

        db.collection("issued_books")
            .whereField("email", isEqualTo: email)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents, error == nil else {
                    print("Error fetching issued books: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                var totalFineAmount: Double = 0
                var bookISBNs: [String] = []

                for document in documents {
                    let data = document.data()
                    totalFineAmount += (data["fine"] as? Double ?? 0)

                    if let isbn = data["isbn13"] as? String {
                        bookISBNs.append(isbn)
                    }
                }

                DispatchQueue.main.async {
                    self.totalFine = totalFineAmount
                }

                // Fetch book details
                fetchBookDetails(isbns: bookISBNs)
            }
    }

    // Fetch Book Details from Books Collection and Update UI
    func fetchBookDetails(isbns: [String]) {
        let db = Firestore.firestore()
        var books: [LibraryBookLibrarian] = []

        let group = DispatchGroup()

        for isbn in isbns {
            group.enter()
            db.collection("books")
                 .whereField("isbn13", isEqualTo: isbn)
                .getDocuments { snapshot, error in
                    defer { group.leave() }

                    guard let document = snapshot?.documents.first, error == nil else {
                        print("Book not found for ISBN: \(isbn)")
                        return
                    }

                    let data = document.data()

                    let book = LibraryBookLibrarian(
                        isbn: isbn,
                        title: data["title"] as? String ?? "Unknown Title",
                        author: data["author"] as? String ?? "Unknown Author",
                        image: "book.fill" // Placeholder image
                    )

                    DispatchQueue.main.async {
                        books.append(book)
                    }
                }
        }

        group.notify(queue: .main) {
            DispatchQueue.main.async {
                self.borrowedBooks = books // Ensure books are updated properly
            }
        }
    }
}

// MARK: - LibraryBookLibrarian Model
struct LibraryBookLibrarian: Identifiable {
    var id: String { isbn }
    var isbn: String
    var title: String
    var author: String
    var image: String
}

// MARK: - BookCardLibrarian View
struct BookCardLibrarian: View {
    var book: LibraryBookLibrarian
    var returnAction: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: book.image)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 70)
                .background(Color.white)
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 3) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer()

            Button(action:
                returnAction
                // Handle return book action
            ) {
                Text("Return")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(10)
        .padding(.horizontal, 10)
    }
}




// MARK: - Preview
struct UserProfileViewLibrarian_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileViewLibrarian(userID: "sampleUserID")
    }
}
