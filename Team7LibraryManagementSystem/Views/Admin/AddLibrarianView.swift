import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AddLibrarianView: View {
    @Environment(\.dismiss) var dismiss
    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var selectedLibrary = "Library1"
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAlert = false
    
    let libraries = ["Library1", "Library2", "Library3"]
    
    var isFormValid: Bool {
        !fullName.isEmpty &&
        !email.isEmpty &&
        !phone.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                SectionView(title: "Librarian Details")
                
                InputField2(
                    title: "Full Name",
                    placeholder: "Enter Full Name",
                    text: $fullName
                )
                
                InputField2(
                    title: "Email",
                    placeholder: "Enter Email",
                    text: $email,
                    keyboardType: .emailAddress
                )
                
                InputField2(
                    title: "Phone",
                    placeholder: "Enter Phone Number",
                    text: $phone,
                    keyboardType: .phonePad
                )
                
                DropdownField2(
                    title: "Assign Library",
                    selection: $selectedLibrary,
                    options: libraries
                )
                
                SecureFieldView2(
                    title: "Password",
                    placeholder: "Enter Password",
                    text: $password,
                    isVisible: $isPasswordVisible
                )
                
                SecureFieldView2(
                    title: "Confirm Password",
                    placeholder: "Confirm Password",
                    text: $confirmPassword,
                    isVisible: $isConfirmPasswordVisible
                )
                
                Spacer()
                
                HStack {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                    
                    Button(action: addLibrarian) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(!isFormValid || isLoading)
                }
            }
            .padding()
            .navigationTitle("Add Librarian")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "Unknown error"),
                    dismissButton: .default(Text("OK"))
                )
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
struct DropdownField2: View {
    var title: String
    @Binding var selection: String
    var options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote)
                .foregroundColor(.secondary)
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) { selection = option }
                }
            } label: {
                HStack {
                    Text(selection)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(10)
            }
        }
    }
}

struct SecureFieldView2: View {
    var title: String
    let placeholder: String
    @Binding var text: String
    @Binding var isVisible: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote)
                .foregroundColor(.secondary)
            HStack {
                if isVisible {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
                
                Button(action: {
                    isVisible.toggle()
                }) {
                    Image(systemName: isVisible ? "eye.fill" : "eye.slash.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}
