
import SwiftUI
import Firebase
import FirebaseFirestore

// Define Fine struct
struct Fine: Identifiable {
    var id: String
    var userId: String
    var bookId: String
    var bookTitle: String
    var amount: Double
    var discount: Double
    var totalAmount: Double
    var reason: String
    var dueDate: Date
    var issueDate: Date
    var overdueDays: Int
    var status: String
    var createdAt: Date
}

// Create a view-specific model instead of using the Book type
struct BookItem: Identifiable {
    var id: String
    var title: String
    var author: String
    var coverImageUrl: String?
    var status: String
    var availableQuantity: Int
    var currentlyBorrowed: Int
    var isAvailable: Bool
    var libraryId: String?
    var dueDate: Date?
    var authors: [String]
    
    // Helper computed property to check if book is returned
    var isReturned: Bool {
        return status == "returned"
    }
}

struct FineManagementView: View {
    var userId: String
    @State private var fineAmount: String = "10.00"
    @State private var discountAmount: String = "5.00"
    @State private var selectedReason: String = "Late return"
    @State private var isLoading = false
    @State private var selectedBookId: String? // Just store the ID
    @State private var userBooks: [BookItem] = []
    @State private var userFines: [Fine] = []
    @State private var errorMessage: String?
    @State private var showAlert = false
    @State private var showReturnConfirmation = false
    @State private var isReturningBook = false
    
    // For confirmation dialog
    @State private var bookBeingReturnedId: String?
    @State private var bookBeingReturnedTitle: String?
    @State private var isConfirmingReturn = false
    
    private let reasons = ["Late return", "Damaged book", "Lost book", "Other"]
    
    private var totalFineAmount: Double {
        userFines.reduce(0) { $0 + $1.totalAmount }
    }
    
    // Computed properties for selected book
    private var selectedBook: BookItem? {
        guard let id = selectedBookId else { return nil }
        return userBooks.first { $0.id == id }
    }
    
    private var overdueDays: Int {
        guard let book = selectedBook,
              let dueDate = book.dueDate else { return 0 }
        
        return max(0, Calendar.current.dateComponents([.day], from: dueDate, to: Date()).day ?? 0)
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
                            
                            Text(book.author)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            if let dueDate = book.dueDate {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.gray)
                                    Text("Due: \(formatDate(dueDate))")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .padding(.top, 4)
                            }
                            
                            if overdueDays > 0 {
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
                        }
                        .padding(.horizontal)
                        
                        // Return Book Button
                        Button(action: {
                            showReturnConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.uturn.backward.circle")
                                Text("Return this Book")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                        .disabled(isReturningBook || book.isReturned)
                        .alert("Return Book", isPresented: $showReturnConfirmation) {
                            Button("Cancel", role: .cancel) { }
                            Button("Return", role: .destructive) {
                                returnSelectedBook()
                            }
                        } message: {
                            Text("Do you want to return this book? Any outstanding fines will need to be paid.")
                        }
                        
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
                                    Text(formatDate(Date()))
                                }
                                
                                if overdueDays > 0 {
                                    HStack {
                                        Text("Additional charges (\(overdueDays) days × $0.50)")
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text("$\(String(format: "%.2f", additionalCharges))")
                                    }
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
                                
                                Menu {
                                    ForEach(reasons, id: \.self) { reason in
                                        Button(reason) {
                                            selectedReason = reason
                                        }
                                    }
                                } label: {
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
                // Book selection view with total fine
                VStack {
                    // Total Fine Summary
                    if userFines.count > 0 {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Total Fines")
                                    .font(.headline)
                                
                                Text("\(userFines.count) fine(s) applied")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Text("$\(String(format: "%.2f", totalFineAmount))")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    
                    Text("Select a book to apply fine")
                        .font(.headline)
                        .padding()
                    
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else if userBooks.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("No borrowed books found")
                                .foregroundColor(.gray)
                        }
                        .padding()
                    } else {
                        // Updated List view with Return Book button for each book
                        List(userBooks) { book in
                            VStack(alignment: .leading) {
                                Button(action: {
                                    selectedBookId = book.id
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
                                            
                                            Text(book.author)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                            
                                            HStack {
                                                Text("Status: \(book.status)")
                                                    .font(.caption)
                                                    .foregroundColor(book.status == "Overdue" ? .red : (book.status == "returned" ? .green : .blue))
                                                
                                                // Show fine if exists
                                                let bookFines = userFines.filter { $0.bookId == book.id }
                                                if !bookFines.isEmpty {
                                                    let totalBookFine = bookFines.reduce(0) { $0 + $1.totalAmount }
                                                    Text("Fine: $\(String(format: "%.2f", totalBookFine))")
                                                        .font(.caption)
                                                        .foregroundColor(.red)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color.red.opacity(0.1))
                                                        .cornerRadius(4)
                                                }
                                            }
                                        }
                                        .padding(.leading, 4)
                                    }
                                }
                                
                                // Add Return Book button
                                Button(action: {
                                    // Show confirmation dialog
                                    bookBeingReturnedId = book.id
                                    bookBeingReturnedTitle = book.title
                                    isConfirmingReturn = true
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.uturn.backward.circle")
                                        Text("Return Book")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(8)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                                .padding(.top, 8)
                                .disabled(book.isReturned || isReturningBook)
                            }
                            .padding(.vertical, 4)
                        }
                        .confirmationDialog(
                            "Return Book",
                            isPresented: $isConfirmingReturn,
                            titleVisibility: .visible
                        ) {
                            Button("Return", role: .destructive) {
                                if let bookId = bookBeingReturnedId {
                                    returnBook(bookId: bookId)
                                }
                            }
                            
                            Button("Cancel", role: .cancel) {
                                bookBeingReturnedId = nil
                                bookBeingReturnedTitle = nil
                            }
                        } message: {
                            Text("Do you want to return '\(bookBeingReturnedTitle ?? "")'? Any outstanding fines will need to be paid.")
                        }
                    }
                    
                    // Fine History Section
                    if !userFines.isEmpty {
                        Section(header: Text("Fine History").font(.headline).padding()) {
                            ForEach(userFines) { fine in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(fine.bookTitle)
                                        .font(.headline)
                                    
                                    HStack {
                                        Text(fine.reason)
                                            .font(.subheadline)
                                        
                                        Spacer()
                                        
                                        Text("$\(String(format: "%.2f", fine.totalAmount))")
                                            .font(.subheadline)
                                            .foregroundColor(.red)
                                    }
                                    
                                    Text("Status: \(fine.status.capitalized)")
                                        .font(.caption)
                                        .foregroundColor(fine.status == "paid" ? .green : .orange)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .onAppear {
                    fetchUserBooks()
                    fetchUserFines()
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
                        selectedBookId = nil
                    }) {
                        Image(systemName: "arrow.left")
                    }
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func fetchUserBooks() {
        isLoading = true
        let db = Firestore.firestore()
        
        // Query books borrowed by this user
        db.collection("books")
            .whereField("borrowerId", isEqualTo: userId)
            .whereField("status", isEqualTo: "borrowed")
            .getDocuments { snapshot, error in
                isLoading = false
                
                if let error = error {
                    errorMessage = "Error fetching books: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("No borrowed books found for this user")
                    return
                }
                
                self.userBooks = documents.compactMap { doc in
                    let data = doc.data()
                    
                    // Calculate if the book is overdue
                    let dueDate = (data["dueDate"] as? Timestamp)?.dateValue() ?? Date()
                    let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
                    let status = daysLeft < 0 ? "Overdue" : "Borrowed"
                    
                    // Using our custom BookItem instead of Book
                    return BookItem(
                        id: doc.documentID,
                        title: data["title"] as? String ?? "Unknown Title",
                        author: (data["authors"] as? [String])?.first ?? "Unknown Author",
                        coverImageUrl: data["coverImageUrl"] as? String,
                        status: status,
                        availableQuantity: data["availableQuantity"] as? Int ?? 0,
                        currentlyBorrowed: data["currentlyBorrowed"] as? Int ?? 0,
                        isAvailable: false,
                        libraryId: data["libraryId"] as? String,
                        dueDate: (data["dueDate"] as? Timestamp)?.dateValue(),
                        authors: data["authors"] as? [String] ?? ["Unknown Author"]
                    )
                }
                
                // Sort books by status (overdue first) then by title
                self.userBooks.sort {
                    if $0.status == "Overdue" && $1.status != "Overdue" {
                        return true
                    } else if $0.status != "Overdue" && $1.status == "Overdue" {
                        return false
                    } else {
                        return $0.title < $1.title
                    }
                }
            }
    }
    
    private func fetchUserFines() {
        let db = Firestore.firestore()
        
        db.collection("fines")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching fines: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.userFines = documents.compactMap { doc in
                    let data = doc.data()
                    
                    guard let bookId = data["bookId"] as? String,
                          let bookTitle = data["bookTitle"] as? String,
                          let amount = data["amount"] as? Double,
                          let discount = data["discount"] as? Double,
                          let totalAmount = data["totalAmount"] as? Double,
                          let reason = data["reason"] as? String,
                          let dueDate = (data["dueDate"] as? Timestamp)?.dateValue(),
                          let issueDate = (data["issueDate"] as? Timestamp)?.dateValue(),
                          let overdueDays = data["overdueDays"] as? Int,
                          let status = data["status"] as? String,
                          let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() else {
                        return nil
                    }
                    
                    return Fine(
                        id: doc.documentID,
                        userId: userId,
                        bookId: bookId,
                        bookTitle: bookTitle,
                        amount: amount,
                        discount: discount,
                        totalAmount: totalAmount,
                        reason: reason,
                        dueDate: dueDate,
                        issueDate: issueDate,
                        overdueDays: overdueDays,
                        status: status,
                        createdAt: createdAt
                    )
                }
            }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    // Helper for the detail view return button
    private func returnSelectedBook() {
        if let bookId = selectedBookId {
            returnBook(bookId: bookId)
        }
    }
    
    // Updated returnBook function that works with IDs instead of Book objects
    private func returnBook(bookId: String) {
        guard let bookIndex = userBooks.firstIndex(where: { $0.id == bookId }) else {
            return
        }
        
        let book = userBooks[bookIndex]
        isReturningBook = true
        let db = Firestore.firestore()
        
        db.collection("books").document(bookId).updateData([
            "status": "available",
            "borrowerId": "",
            "dueDate": FieldValue.delete(),
            "availableQuantity": book.availableQuantity + 1,
            "currentlyBorrowed": book.currentlyBorrowed - 1
        ]) { error in
            if let error = error {
                errorMessage = "Error returning book: \(error.localizedDescription)"
                showAlert = true
                isReturningBook = false
            } else {
                // Add return record
                let returnData: [String: Any] = [
                    "bookId": bookId,
                    "userId": userId,
                    "bookTitle": book.title,
                    "returnDate": Timestamp(date: Date()),
                    "hasFine": userFines.contains { $0.bookId == bookId }
                ]
                
                db.collection("book_returns").addDocument(data: returnData) { _ in
                    // Update book status in the local array
                    userBooks[bookIndex].status = "returned"
                    
                    // If the book was selected in detail view, reset to null
                    if selectedBookId == bookId {
                        selectedBookId = nil
                    }
                    
                    isReturningBook = false
                    bookBeingReturnedId = nil
                    bookBeingReturnedTitle = nil
                }
            }
        }
    }
    
    private func applyFine() {
        guard let book = selectedBook else { return }
        guard let fineAmountValue = Double(fineAmount), fineAmountValue > 0 else {
            errorMessage = "Please enter a valid fine amount"
            showAlert = true
            return
        }
        
        isLoading = true
        let db = Firestore.firestore()
        
        let dueDate = book.dueDate ?? Date()
        
        let fineData: [String: Any] = [
            "userId": userId,
            "bookId": book.id,
            "bookTitle": book.title,
            "amount": Double(fineAmount) ?? 0.0,
            "discount": Double(discountAmount) ?? 0.0,
            "totalAmount": totalFine,
            "reason": selectedReason,
            "dueDate": Timestamp(date: dueDate),
            "issueDate": Timestamp(date: Date()),
            "overdueDays": overdueDays,
            "status": "unpaid",
            "createdAt": Timestamp(date: Date())
        ]
        
        db.collection("fines").addDocument(data: fineData) { error in
            isLoading = false
            if let error = error {
                errorMessage = "Error applying fine: \(error.localizedDescription)"
                showAlert = true
            } else {
                // Fine applied successfully, go back to book selection
                selectedBookId = nil
                // Refresh the fine list
                fetchUserFines()
            }
        }
    }
}
