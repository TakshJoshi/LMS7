import SwiftUI
import FirebaseFirestore

struct Librarian: Identifiable {
    var id: String
    var fullName: String
    var email: String
    var phone: String
    var isEmployee: Bool
    var role: String
    var createdAt: Timestamp
    var isSuspended: Bool = false
}

struct InputField2: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct AddLibrariesForm: View {
    @State private var libraryName: String = ""
    @State private var address: String = ""
    @State private var phone: String = ""
    @State private var selectedLibrarian: String = ""
    @State private var totalBooks: String = ""
    @State private var selectedCategory: String = "Science"
    
    @State private var librarians: [Librarian] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showAlert = false
    
    @Environment(\.dismiss) var dismiss
    
    let categories = ["Science", "Arts", "Technology", "History"]
    
    var body: some View {
        NavigationStack {
            Form {
                // Library Name
                InputField2(title: "Library Name", placeholder: "Enter library name", text: $libraryName)
                
                // Address
                InputField2(title: "Address", placeholder: "Enter address", text: $address)

                // Phone Number
                InputField2(title: "Phone", placeholder: "Enter phone number", text: $phone, keyboardType: .phonePad)

                // Librarian Picker
                Section(header: Text("Assign Librarian")) {
                    if isLoading {
                        ProgressView("Loading librarians...")
                    } else {
                        Picker("Librarian", selection: $selectedLibrarian) {
                            ForEach(librarians, id: \.id) { librarian in
                                Text(librarian.fullName).tag(librarian.id)
                            }
                        }
                    }
                }
                
                // Total Books
                InputField2(title: "Total Books", placeholder: "Enter total books", text: $totalBooks, keyboardType: .numberPad)
                
                // Category Picker
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category)
                    }
                }
                .pickerStyle(.menu)
                
                // Save and Cancel Buttons
                Section {
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .tint(.gray)
                        
                        Button("Save") {
                            saveLibrary()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!isFormValid())
                    }
                }
            }
            .navigationTitle("Add New Library")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                fetchLibrarians()
            }
        }
    }
    
    private func isFormValid() -> Bool {
        return !libraryName.isEmpty && !address.isEmpty && !selectedLibrarian.isEmpty && !phone.isEmpty
    }
    
    private func fetchLibrarians() {
        let db = Firestore.firestore()
        db.collection("librarians").addSnapshotListener { snapshot, error in
            if let error = error {
                errorMessage = "Error fetching librarians: \(error.localizedDescription)"
                showAlert = true
                return
            }
            
            if let documents = snapshot?.documents {
                self.librarians = documents.compactMap { doc in
                    let data = doc.data()
                    return Librarian(
                        id: doc.documentID,
                        fullName: data["fullName"] as? String ?? "",
                        email: data["email"] as? String ?? "",
                        phone: data["phone"] as? String ?? "",
                        isEmployee: data["isEmployee"] as? Bool ?? true,
                        role: data["role"] as? String ?? "Librarian",
                        createdAt: data["createdAt"] as? Timestamp ?? Timestamp()
                    )
                }
            }
            isLoading = false
        }
    }
    
    private func saveLibrary() {
        guard isFormValid() else {
            errorMessage = "Please fill all fields correctly."
            showAlert = true
            return
        }
        
        let db = Firestore.firestore()
        let newLibrary: [String: Any] = [
            "name": libraryName,
            "address": address,
            "phone": phone,
            "totalBooks": Int(totalBooks) ?? 0,
            "category": selectedCategory,
            "assignedLibrarian": selectedLibrarian,
            "createdAt": Timestamp()
        ]
        
        db.collection("libraries").addDocument(data: newLibrary) { error in
            if let error = error {
                errorMessage = "Error saving library: \(error.localizedDescription)"
                showAlert = true
            } else {
                dismiss()
            }
        }
    }
}

struct AddLibrariesForm_Previews: PreviewProvider {
    static var previews: some View {
        AddLibrariesForm()
    }
}
