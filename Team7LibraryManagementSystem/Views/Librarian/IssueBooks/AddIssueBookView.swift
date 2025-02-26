import SwiftUI
import FirebaseFirestore
import CodeScanner

struct AddIssueBookView: View {
    @State private var email: String = ""
    @State private var isbn13: String = ""
    @State private var dueDate: Date = Date()
    @State private var isShowingScanner = false
    @State private var isCalendarVisible = false
    @State private var message: String = ""
    var selectedUser: User?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // User Email Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email").font(.subheadline).foregroundColor(.gray)
                        TextField("Enter email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // User Details if found
                    if let user = selectedUser {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name: \(user.firstName) \(user.lastName)").bold()
                            Text("Email: \(user.email)")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
                    // Book Details with Scanner
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ISBN-13").font(.subheadline).foregroundColor(.gray)
                        HStack {
                            TextField("Enter ISBN-13", text: $isbn13)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button(action: {
                                isShowingScanner = true
                            }) {
                                Image(systemName: "barcode.viewfinder")
                                    .font(.title)
                                    .foregroundColor(.blue)
                            }
                        }
                    }

                    // Due Date Picker
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Select Due Date").font(.subheadline).foregroundColor(.gray)
                            Spacer()
                            Text(dueDate, style: .date) // Display selected date on right
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .onTapGesture {
                                    withAnimation {
                                        isCalendarVisible.toggle() // Show calendar on tap
                                    }
                                }
                        }
                        .padding(.vertical, 8)

                        if isCalendarVisible {
                            DatePicker("", selection: $dueDate, in: Date()..., displayedComponents: [.date]) // Prevent past dates
                                .labelsHidden()
                                .datePickerStyle(GraphicalDatePickerStyle())
                        }
                    }

                    // Issue Book Button
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
//            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $isShowingScanner) {
                CodeScannerView(codeTypes: [.ean13, .ean8], simulatedData: "9781234567890") { result in
                    switch result {
                    case .success(let code):
                        isbn13 = code.string
                        isShowingScanner = false
                    case .failure(let error):
                        message = "Scan failed: \(error.localizedDescription)"
                        isShowingScanner = false
                    }
                }
            }
        }
    }

//struct AddIssueBookView: View {
//    @Environment(\.dismiss) var dismiss
//    @State private var email = ""
//    @State private var isbn13 = ""
//    @State private var dueDate = Date()
//    @State private var selectedUser: UserProfile?
//    @State private var message = ""
//    @State private var isShowingScanner = false // Scanner sheet trigger
//
//    var body: some View {
//        NavigationView {
//            ScrollView {
//                VStack(spacing: 24) {
//                    // User Email Input
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Email").font(.subheadline).foregroundColor(.gray)
//                        TextField("Enter email", text: $email)
//                            .textFieldStyle(RoundedBorderTextFieldStyle())
//                    }
//
//                    // User Details if found
//                    if let user = selectedUser {
//                        VStack(alignment: .leading, spacing: 8) {
//                            Text("Name: \(user.firstName) \(user.lastName)").bold()
//                            Text("Email: \(user.email)")
//                        }
//                        .padding()
//                        .background(Color(.systemGray6))
//                        .cornerRadius(10)
//                    }
//
//                    // Book Details with Scanner
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("ISBN-13").font(.subheadline).foregroundColor(.gray)
//                        HStack {
//                            TextField("Enter ISBN-13", text: $isbn13)
//                                .textFieldStyle(RoundedBorderTextFieldStyle())
//                            Button(action: {
//                                isShowingScanner = true
//                            }) {
//                                Image(systemName: "barcode.viewfinder")
//                                    .font(.title)
//                                    .foregroundColor(.blue)
//                            }
//                        }
//                    }
//
//                    // Due Date Picker
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Select due date").font(.subheadline).foregroundColor(.gray)
//                        DatePicker("", selection: $dueDate, displayedComponents: [.date])
//                            .labelsHidden()
//                            .datePickerStyle(GraphicalDatePickerStyle())
//                    }
//
//                    // Issue Book Button
//                    Button(action: issueBook) {
//                        Text("Issue Book")
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color.blue)
//                            .foregroundColor(.white)
//                            .cornerRadius(10)
//                    }
//
//                    Text(message).foregroundColor(.red)
//                }
//                .padding()
//            }
//            .navigationTitle("Issue Book")
//            .sheet(isPresented: $isShowingScanner) {
//                CodeScannerView(codeTypes: [.ean13, .ean8], simulatedData: "9781234567890") { result in
//                    switch result {
//                    case .success(let code):
//                        isbn13 = code.string
//                        isShowingScanner = false
//                    case .failure(let error):
//                        message = "Scan failed: \(error.localizedDescription)"
//                        isShowingScanner = false
//                    }
//                }
//            }
//        }
//    }
    
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
                "fine": 0,
                "status": "Borrowed" // Adding status field
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


#Preview{
    AddIssueBookView()
}
