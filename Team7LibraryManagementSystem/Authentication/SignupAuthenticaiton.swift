


import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import SwiftSMTP

struct SignupAuthentication: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var dob = Date()
    @State private var showDatePicker = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isAgreed = false
    @State private var errorMessage = ""
    @State private var isSignedUp = false
    
    var isEmailValid: Bool { email.range(of: "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$", options: .regularExpression) != nil }
    var isPasswordValid: Bool {
        let hasMinLength = password.count >= 6
        let hasLetter = password.range(of: "[A-Za-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "\\d", options: .regularExpression) != nil
        let hasSpecialChar = password.range(of: "[@$!%*?&#]", options: .regularExpression) != nil
        return hasMinLength && hasLetter && hasNumber && hasSpecialChar
    }
    var isConfirmPasswordValid: Bool { !confirmPassword.isEmpty && password == confirmPassword }
    var canSignUp: Bool { isEmailValid && isPasswordValid && isConfirmPasswordValid && isAgreed }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    InputField(placeholder: "First Name", text: $firstName)
                    InputField(placeholder: "Last Name", text: $lastName)
                    
                    VStack(alignment: .leading) {
                        Button(action: {
                            showDatePicker.toggle()
                        }) {
                            Text(formatDate(dob))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .foregroundColor(.black)
                        }
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                        
                        if showDatePicker {
                            DatePicker("", selection: $dob, displayedComponents: .date)
                                .datePickerStyle(WheelDatePickerStyle())
                                .frame(maxWidth: .infinity)
                                .labelsHidden()
                        }
                    }
                    
                    InputField(placeholder: "your@email.com", text: $email, keyboardType: .emailAddress)
                    ValidationMessage(text: "Invalid email format", isValid: isEmailValid, isVisible: !email.isEmpty)
                    
                    SecureInputField(placeholder: "Password", text: $password)
                    PasswordStrengthMessage(password: password)
                    
                    SecureInputField(placeholder: "Confirm Password", text: $confirmPassword)
                    ValidationMessage(text: "Passwords do not match", isValid: isConfirmPasswordValid, isVisible: !confirmPassword.isEmpty)
                    
                    Toggle("I agree to the Terms and Privacy Policy", isOn: $isAgreed).padding(.top, 8)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage).foregroundColor(.red).padding(.top, 8)
                    }
                    
                    Button(action: signUp) {
                        Text("Create Account")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canSignUp ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }.disabled(!canSignUp)
                }
                .padding()
                
                .fullScreenCover(isPresented: $isSignedUp) {
                    UserHomeView()
                }
            }
            .navigationTitle("Create Account")
        }
    }
    
    func signUp() {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        let dobString = formatDate(dob)
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            
            guard let user = authResult?.user else { return }
            let db = Firestore.firestore()
            
            db.collection("users").document(user.uid).setData([
                "userId": user.uid,
                "firstName": firstName,
                "lastName": lastName,
                "dob": dobString,
                "email": email,
                "role": "user",
                "isDeleted": false
            ]) { error in
                if let error = error {
                    errorMessage = "Failed to save user data: \(error.localizedDescription)"
                } else {
                    isSignedUp = true  // ✅ Trigger navigation on success
                    UserDefaults.standard.removeObject(forKey: "userEmail")

                    sendWelcomeEmail(to: email) { success, message in
                        DispatchQueue.main.async {
                            if !success {
                                errorMessage = message
                            } else {
                                print(message) // Log success message
                            }
                    }}
                }
            }
        }
        
        
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    struct ValidationMessage: View {
        var text: String
        var isValid: Bool
        var isVisible: Bool
        
        var body: some View {
            if isVisible {
                Text(isValid ? "✔ Valid" : "❌ \(text)")
                    .foregroundColor(isValid ? .green : .red)
                    .font(.footnote)
                    .transition(.opacity)
            }
        }
    }
    
    struct PasswordStrengthMessage: View {
        var password: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                ValidationMessage(text: "At least 6 characters", isValid: password.count >= 6, isVisible: !password.isEmpty)
                ValidationMessage(text: "Contains a letter", isValid: password.range(of: "[A-Za-z]", options: .regularExpression) != nil, isVisible: !password.isEmpty)
                ValidationMessage(text: "Contains a number", isValid: password.range(of: "\\d", options: .regularExpression) != nil, isVisible: !password.isEmpty)
                ValidationMessage(text: "Contains a special character", isValid: password.range(of: "[@$!%*?&#]", options: .regularExpression) != nil, isVisible: !password.isEmpty)
            }
        }
    }
    
    struct InputField: View {
        var placeholder: String
        @Binding var text: String
        var keyboardType: UIKeyboardType = .default
        var body: some View {
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(keyboardType)
        }
    }
    
    struct SecureInputField: View {
        var placeholder: String
        @Binding var text: String
        var body: some View {
            SecureField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    private func sendWelcomeEmail(to email: String, completion: @escaping (Bool, String) -> Void) {
        let smtp = SMTP(
            hostname: "smtp.gmail.com",
            email: "rakshitpanjeta23@gmail.com",
            password: "figyutdbxwtkzjun", // Use an App Password
            port: 465,
            tlsMode: .requireTLS
        )
        
        let from = Mail.User(name: "Team 7", email: "rakshitpanjeta23@gmail.com")
        let to = Mail.User(name: "User", email: email)
        
        let mail = Mail(
            from: from,
            to: [to],
            subject: "Welcome to Our Platform!",
            text: """
        Hello!
        
        Welcome to our platform. We are thrilled to have you on board. If you have any questions, feel free to reach out.
        
        Best Regards,
        Team 7
        """
        )
        
        smtp.send(mail) { error in
            if let error = error {
                completion(false, "Error sending email: \(error.localizedDescription)")
            } else {
                completion(true, "Welcome email sent successfully to \(email)")
            }
        }
    }
    
    
    
    struct SignupAuthentication_Previews: PreviewProvider {
        static var previews: some View {
            SignupAuthentication()
        }
    }
}
