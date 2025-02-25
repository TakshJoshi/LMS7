
import SwiftUI
import FirebaseFirestore

struct AddIssueBookView: View {
    @Environment(\ .dismiss) var dismiss
    @State private var email = ""
    @State private var isbn13 = ""
    // @State private var bookTitle = ""
    @State private var dueDate = Date()
    @State private var selectedUser: UserProfile?
    @State private var message = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // User ID Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email").font(.subheadline).foregroundColor(.gray)
                        HStack {
                            TextField("Enter email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    // Display User Details if found
                    if let user = selectedUser {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name: \(user.firstName) \(user.lastName)").bold()
                            Text("Email: \(user.email)")
                            Text("Date of Birth: \(user.dob)")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
                    // Book Details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ISBN-13").font(.subheadline).foregroundColor(.gray)
                        TextField("Enter ISBN-13", text: $isbn13)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    //                    VStack(alignment: .leading, spacing: 8) {
                    //                        Text("Book Title").font(.subheadline).foregroundColor(.gray)
                    //                        TextField("Enter book title", text: $bookTitle)
                    //                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    //                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select due date").font(.subheadline).foregroundColor(.gray)
                        DatePicker("", selection: $dueDate, displayedComponents: [.date])
                            .labelsHidden()
                            .datePickerStyle(GraphicalDatePickerStyle())
                    }
                    
                    Button(action: issueBook) {
                        Text("Issue Book")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Text(message).foregroundColor(.red)
                }
                .padding()
            }
            .navigationTitle("Issue Book")
            .toolbar {
                //
            }
        }
    }

    
    func isRegisteredUser(email: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let lowercaseEmail = email.lowercased()
        
        db.collection("users").whereField("email", isEqualTo: lowercaseEmail).getDocuments { snapshot, error in
            if let error = error {
                print("Error checking user: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            let isRegistered = !(snapshot?.documents.isEmpty ?? true)
            completion(isRegistered)
        }
    }
    
    
    func issueBook() {
        guard !isbn13.isEmpty, !email.isEmpty else {
            message = "ISBN-13 and Email are required!"
            return
        }
        
        let lowercaseEmail = email.lowercased()
        let currentDate = Date()
        
        guard dueDate > currentDate else {
            message = "Due date must be after the issue date!"
            return
        }
        
        let db = Firestore.firestore()
        
        // Step 1: Fetch the book details
        db.collection("books").whereField("isbn13", isEqualTo: isbn13).getDocuments { snapshot, error in
            if let error = error {
                message = "Error fetching book details: \(error.localizedDescription)"
                return
            }
            
            guard let document = snapshot?.documents.first, var bookData = document.data() as? [String: Any] else {
                message = "Book not found!"
                return
            }
            
            let totalCheckouts = bookData["totalCheckouts"] as? Int ?? 0
            let quantity = bookData["quantity"] as? Int ?? 0
            
            // Step 2: Check if the book is available
            if totalCheckouts >= quantity {
                message = "Book is out of stock!"
                return
            }
            
            // Step 3: Proceed with issuing the book
            let issuedBook = [
                "email": lowercaseEmail,
                "isbn13": isbn13,
                "issue_date": Timestamp(date: currentDate),
                "due_date": Timestamp(date: dueDate),
                "fine": 0
            ] as [String: Any]
            
            isRegisteredUser(email: email) { isRegistered in
                DispatchQueue.main.async {
                    if isRegistered {
                        db.collection("issued_books").addDocument(data: issuedBook) { error in
                            if let error = error {
                                message = "Error: \(error.localizedDescription)"
                            } else {
                                // Step 4: Update totalCheckouts in books collection
                                db.collection("books").document(document.documentID).updateData([
                                    "totalCheckouts": totalCheckouts + 1
                                ]) { error in
                                    if let error = error {
                                        message = "Error updating total checkouts: \(error.localizedDescription)"
                                    } else {
                                        message = "Book Issued Successfully!"
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            dismiss()
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        message = "User not found."
                    }
                }
            }
        }
    }
}


struct UserProfile {
    let userId: String
    let firstName: String
    let lastName: String
    let email: String
    let dob: String
    let role: String
    let isDeleted: Bool
}
