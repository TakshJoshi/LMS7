import SwiftUI
import Firebase

struct FineManagementView: View {
    var userId: String
    @State private var fineAmount: String = "10.00"
    @State private var discountAmount: String = "5.00"
    @State private var selectedReason: String = "Late return"
    @State private var isLoading = false
    @State private var selectedBook: Book?
    @State private var userBooks: [Book] = []
    
    private let dueDate = Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date()
    private let issueDate = Date()
    
    private var overdueDays: Int {
        Calendar.current.dateComponents([.day], from: dueDate, to: Date()).day ?? 0
    }
    
    private var additionalCharges: Double {
        Double(overdueDays) * 0.50
    }
    
    private var totalFine: Double {
        (Double(fineAmount) ?? 0) - (Double(discountAmount) ?? 0)
    }
    
    var body: some View {
        VStack {
            if let book = selectedBook {
                // Fine details view
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Book info at top
                        VStack(alignment: .center, spacing: 8) {
                            Text(book.title)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                            
                            Text(book.authors.first ?? "Unknown Author")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.gray)
                                Text("Due: Jan 15, 2024")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 4)
                            
                            HStack {
                                Text("Overdue: \(overdueDays) days")
                                    .foregroundColor(.red)
                                
                                Text("OVERDUE")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.red.opacity(0.2))
                                    .foregroundColor(.red)
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Issue Summary
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Issue Summary")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 15) {
                                HStack {
                                    Text("Issue Date")
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("Feb 15, 2024")
                                }
                                
                                HStack {
                                    Text("Additional charges (\(overdueDays) days × $0.50)")
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("$\(String(format: "%.2f", additionalCharges))")
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                        
                        // Fine
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Fine")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Fine Amount")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                                
                                TextField("0.00", text: $fineAmount)
                                    .keyboardType(.decimalPad)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Reason")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                                
                                HStack {
                                    Text(selectedReason)
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .padding(.horizontal)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Discount")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                                
                                TextField("0.00", text: $discountAmount)
                                    .keyboardType(.decimalPad)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                            }
                        }
                        
                        // Total Fine
                        HStack {
                            Text("Total Fine")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("$\(String(format: "%.2f", totalFine))")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                        .padding()
                    }
                }
                .overlay(
                    VStack {
                        Spacer()
                        Button(action: applyFine) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Apply Fine")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding()
                        .disabled(isLoading)
                    }
                )
            } else {
                // Book selection view
                VStack {
                    Text("Select a book to apply fine")
                        .font(.headline)
                        .padding()
                    
                    if userBooks.isEmpty {
                        ProgressView()
                            .padding()
                    } else {
                        List(userBooks) { book in
                            Button(action: {
                                selectedBook = book
                            }) {
                                HStack {
                                    if let coverUrl = book.coverImageUrl, let url = URL(string: coverUrl) {
                                        AsyncImage(url: url) { image in
                                            image.resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 50, height: 70)
                                        } placeholder: {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: 50, height: 70)
                                        }
                                        .cornerRadius(4)
                                    } else {
                                        Image(systemName: "book.closed")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 50, height: 70)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(book.title)
                                            .font(.headline)
                                        
                                        Text(book.authors.first ?? "Unknown Author")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        
                                        Text("Status: \(book.status)")
                                            .font(.caption)
                                            .foregroundColor(book.status == "Overdue" ? .red : .blue)
                                    }
                                    .padding(.leading, 4)
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    fetchUserBooks()
                }
            }
        }
        .navigationTitle(selectedBook == nil ? "Select Book" : "Apply Fine")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(selectedBook != nil)
        .toolbar {
            if selectedBook != nil {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        selectedBook = nil
                    }) {
                        Image(systemName: "arrow.left")
                    }
                }
            }
        }
    }
    
    private func fetchUserBooks() {
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, let data = document.data(), let email = data["email"] as? String {
                db.collection("issued_books")
                    .whereField("email", isEqualTo: email)
                    .getDocuments { snapshot, error in
                        if let error = error {
                            print("Error fetching books: \(error.localizedDescription)")
                            return
                        }
                        
                        let isbnList = snapshot?.documents.compactMap { $0.data()["isbn13"] as? String } ?? []
                        
                        guard !isbnList.isEmpty else {
                            print("No borrowed books found")
                            return
                        }
                        
                        db.collection("books")
                            .whereField("isbn13", in: isbnList)
                            .getDocuments { snapshot, error in
                                if let error = error {
                                    print("Error fetching book details: \(error)")
                                    return
                                }
                                
                                self.userBooks = snapshot?.documents.compactMap { doc in
                                    let data = doc.data()
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
                                        isbn13: data["isbn13"] as? String,
                                        language: data["language"] as? String,
                                        quantity: data["quantity"] as? Int ?? 0,
                                        availableQuantity: data["availableQuantity"] as? Int ?? 0,
                                        location: data["location"] as? String ?? "Unknown",
                                        status: "Overdue", // Setting as overdue for demo
                                        totalCheckouts: data["totalCheckouts"] as? Int ?? 0,
                                        currentlyBorrowed: data["currentlyBorrowed"] as? Int ?? 0,
                                        isAvailable: data["isAvailable"] as? Bool ?? false,
                                        libraryId: data["libraryId"] as? String
                                    )
                                } ?? []
                            }
                    }
            }
        }
    }
    
    private func applyFine() {
        guard let book = selectedBook else { return }
        
        isLoading = true
        let db = Firestore.firestore()
        
        let fineData: [String: Any] = [
            "userId": userId,
            "bookId": book.id,
            "bookTitle": book.title,
            "amount": Double(fineAmount) ?? 0.0,
            "discount": Double(discountAmount) ?? 0.0,
            "totalAmount": totalFine,
            "reason": selectedReason,
            "dueDate": Timestamp(date: dueDate),
            "issueDate": Timestamp(date: issueDate),
            "overdueDays": overdueDays,
            "status": "unpaid",
            "createdAt": Timestamp(date: Date())
        ]
        
        db.collection("fines").addDocument(data: fineData) { error in
            isLoading = false
            if let error = error {
                print("Error applying fine: \(error.localizedDescription)")
            } else {
                print("Fine applied successfully")
                selectedBook = nil // Go back to book selection
            }
        }
    }
}

// **Fine Model**
struct Fine: Identifiable {
    var id: String
    var email: String
    var overdueDays: Int
    var fineAmount: Double
}

// **Fine Row UI**
struct FineRowView: View {
    var fine: Fine
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Email: \(fine.email)")
                    .font(.headline)
                
                Text("\(fine.overdueDays) days overdue")
                    .foregroundColor(.red)
                    .font(.subheadline)
            }
            
            Spacer()
            
            Text("$\(String(format: "%.2f", fine.fineAmount))")
                .font(.headline)
                .foregroundColor(.blue)
        }
        .padding()
    }
}



