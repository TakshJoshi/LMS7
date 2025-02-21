import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AddLibrarianView: View {
    @Environment(\.dismiss) var dismiss
    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var selectedLibrary = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAlert = false
    
    // Libraries fetched from Firestore
    @State private var libraries: [String] = []
    
    var isFormValid: Bool {
        !fullName.isEmpty &&
        !email.isEmpty &&
        !phone.isEmpty &&
        !password.isEmpty &&
        !selectedLibrary.isEmpty &&
        password == confirmPassword
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                            .foregroundStyle(.gray)

                        Text("Add Photo")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                }
                
                Section(header: Text("Personal Information")) {
                    TextField("Enter full name", text: $fullName)
                    TextField("Enter email address", text: $email)
                        .keyboardType(.emailAddress)
                    TextField("Enter phone number", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("Library Assignment")) {
                    if isLoading && libraries.isEmpty {
                        ProgressView()
                    } else {
                        Picker("Select Library", selection: $selectedLibrary) {
                            Text("Select a Library").tag("")
                            ForEach(libraries, id: \.self) { library in
                                Text(library).tag(library)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                Section(header: Text("Access Credentials")) {
                    HStack {
                        if showPassword {
                            TextField("Enter password", text: $password)
                        } else {
                            SecureField("Enter password", text: $password)
                        }
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye" : "eye.slash")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    HStack {
                        if showConfirmPassword {
                            TextField("Confirm password", text: $confirmPassword)
                        } else {
                            SecureField("Confirm password", text: $confirmPassword)
                        }
                        Button(action: { showConfirmPassword.toggle() }) {
                            Image(systemName: showConfirmPassword ? "eye" : "eye.slash")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Add Librarian")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    addLibrarian()
                }
                .disabled(!isFormValid || isLoading)
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "Unknown error"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                fetchLibraries()
            }
        }
    }
    
    private func fetchLibraries() {
        isLoading = true
        let db = Firestore.firestore()
        
        db.collection("libraries").getDocuments { (querySnapshot, error) in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    print("Firestore Error: \(error.localizedDescription)")
                    errorMessage = "Error fetching libraries: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                guard let snapshot = querySnapshot else {
                    print("No snapshot returned")
                    errorMessage = "No library data found"
                    showAlert = true
                    return
                }
                
                print("Total documents found: \(snapshot.documents.count)")
                
                libraries = snapshot.documents.compactMap { document in
                    let data = document.data()
                    print("Document data: \(data)")
                    
                    // Try different ways of extracting the library name
                    let libraryName = data["name"] as? String ??
                                      data["Name"] as? String ??
                                      data["library_name"] as? String ??
                                      data["libraryName"] as? String
                    
                    print("Extracted library name: \(libraryName ?? "nil")")
                    return libraryName
                }
                
                print("Parsed libraries: \(libraries)")
                
                if libraries.isEmpty {
                    print("No libraries could be extracted")
                    errorMessage = "No libraries found"
                    showAlert = true
                }
            }
        }
    }
    
    private func addLibrarian() {
        isLoading = true
        
        // First create Auth user
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                isLoading = false
                errorMessage = "Error creating account: \(error.localizedDescription)"
                showAlert = true
                return
            }
            
            guard let userId = authResult?.user.uid else {
                isLoading = false
                errorMessage = "Failed to get user ID"
                showAlert = true
                return
            }
            
            // Then add to Firestore
            let db = Firestore.firestore()
            let newLibrarian: [String: Any] = [
                "id": userId,
                "fullName": fullName,
                "email": email,
                "phone": phone,
                "assignedLibrary": selectedLibrary,
                "isSuspended": false,
                "isEmployee": true,
                "role": "librarian",
                "createdAt": Timestamp()
            ]
            
            db.collection("librarians").document(userId).setData(newLibrarian) { error in
                isLoading = false
                if let error = error {
                    errorMessage = "Error adding librarian: \(error.localizedDescription)"
                    showAlert = true
                } else {
                    dismiss()
                }
            }
        }
    }
}

struct AddLibrarianView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AddLibrarianView()
        }
    }
}
