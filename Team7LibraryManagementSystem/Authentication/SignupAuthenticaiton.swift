import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import SwiftSMTP

struct SignupAuthentication: View {
    @State private var fullName = ""
    @State private var username = ""
    @State private var mobileNumber = ""
    @State private var selectedGender = "Male"
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isAgreed = false
    @State private var errorMessage = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    
    @State private var isSignupSuccessful = false
    @State private var navigateTo2FA = false
    
    let genders = ["Male", "Female", "Others"]
    
    var isEmailValid: Bool { email.range(of: "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$", options: .regularExpression) != nil }
    var isPasswordValid: Bool { password.range(of: "^(?=.*[A-Za-z])(?=.*\\d)(?=.*[@$!%*?&#])[A-Za-z\\d@$!%*?&#]{6,}$", options: .regularExpression) != nil }
    var isUsernameValid: Bool { username.count >= 4 } // 4-char limit for username
    var isMobileValid: Bool { mobileNumber.range(of: "^[0-9]{10}$", options: .regularExpression) != nil }
    var isConfirmPasswordValid: Bool { !confirmPassword.isEmpty && password == confirmPassword }
    var canSignUp: Bool { isEmailValid && isPasswordValid && isUsernameValid && isMobileValid && isConfirmPasswordValid && isAgreed }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) { // Adjusted spacing here
                InputFields(placeholder: "Username", text: $username)
                    .onChange(of: username) { newValue in
                        if newValue.count > 20 { // Set an upper limit if needed
                            username = String(newValue.prefix(20))
                        }
                    }
                ValidationMessage(text: "Username must be at least 4 characters", isValid: isUsernameValid, isVisible: !username.isEmpty)
                
                // Last name is now optional
                InputFields(placeholder: "Lastname", text: $fullName)
                
                InputFields(placeholder: "(000) 000-0000", text: $mobileNumber, keyboardType: .numberPad)
                ValidationMessage(text: "Enter a valid 10-digit mobile number", isValid: isMobileValid, isVisible: !mobileNumber.isEmpty)
                
                Picker("", selection: $selectedGender) {
                    ForEach(genders, id: \.self) { gender in
                        Text(gender).tag(gender)
                    }
                }
                .padding(.horizontal,10)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4), lineWidth: 1))
                .tint(.primary)
                
                InputFields(placeholder: "your@email.com", text: $email, keyboardType: .emailAddress)
                ValidationMessage(text: "Enter a valid email address", isValid: isEmailValid, isVisible: !email.isEmpty)
                
                PasswordInputField(placeholder: "Password", text: $password, isVisible: $isPasswordVisible)
                PasswordStrengthMessage(password: password)
                
                PasswordInputField(placeholder: "Confirm Password", text: $confirmPassword, isVisible: $isConfirmPasswordVisible)
                ValidationMessage(text: "Passwords do not match", isValid: isConfirmPasswordValid, isVisible: !confirmPassword.isEmpty)
                
                Toggle("I agree to the Terms and Privacy Policy", isOn: $isAgreed).padding(.top, 8)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage).foregroundColor(.red).padding(.top, 8)
                }
                Spacer()
                Spacer()
                
                Button(action: signUp) {
                    Text("Create Account").frame(maxWidth: .infinity).padding().background(canSignUp ? Color.blue : Color.gray).foregroundColor(.white).cornerRadius(10)
                }.disabled(!canSignUp)
            }
            .padding()
        }
        .fullScreenCover(isPresented: $navigateTo2FA) {
            TwoFactorAuthenticationView(role: "user", email: email)
        }
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.large)
    }


    
    func signUp() {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }

            // Ensure user exists
            guard let user = authResult?.user else { return }
            
            let db = Firestore.firestore()
            let userData: [String: Any] = [
                "userId": user.uid,  // ✅ Store userId explicitly
                "fullName": fullName,
                "username": username,
                "mobileNumber": mobileNumber,
                "gender": selectedGender,
                "email": email,
                "genre":  "NA",
                "language": "NA"
            ]
            
            // Save user data to Firestore
            db.collection("users").document(user.uid).setData(userData) { error in
                if let error = error {
                    errorMessage = "Failed to save user data: \(error.localizedDescription)"
                    return
                }

                // ✅ Generate and Send OTP
                FirebaseManager.shared.generateAndSendOTP(email: email) { success, message in
                    if success {
                        print("✅ OTP Sent Successfully: \(message)")
                        navigateTo2FA = true
                        UserDefaults.standard.set(user.uid, forKey: "userId")
                        
                        sendWelcomeEmail(to: email) { success, message in
                            if success {
                                print("✅ \(message)")
                            } else {
                                print("❌ \(message)")
                            }
                        }
                        
                        // ✅ Navigate to OTP Verification Screen
                       
                        
                    } else {
                        print("❌ Failed to Send OTP: \(message)")
                        errorMessage = message
                    }
                }
            }
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

    }


struct PasswordInputField: View {
    var placeholder: String
    @Binding var text: String
    @Binding var isVisible: Bool
    var body: some View {
        ZStack(alignment: .trailing) {
            if isVisible {
                TextField(placeholder, text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.vertical, 8) // Adjusted padding
            } else {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.vertical, 8) // Adjusted padding
            }
            Button(action: { isVisible.toggle() }) {
                Image(systemName: isVisible ? "eye.fill" : "eye.slash.fill")
                    .foregroundColor(.gray)
                    .padding(.trailing, 10)
            }
        }
    }
}

struct InputFields: View {
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(keyboardType)
            .padding(.vertical, 8) // Adjusted padding
    }
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
//        if isVisible && !isValid {
//           Text("❌ \(text)")
//               .foregroundColor(.red)
//               .font(.footnote)
//               .transition(.opacity)
//       }
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
//        VStack(alignment: .leading, spacing: 2) {
//            ValidationMessage(text: "At least 6 characters", isValid: password.count >= 6, isVisible: !password.isEmpty)
//            ValidationMessage(text: "Contains a letter", isValid: password.range(of: "[A-Za-z]", options: .regularExpression) != nil, isVisible: !password.isEmpty)
//            ValidationMessage(text: "Contains a number", isValid: password.range(of: "\\d", options: .regularExpression) != nil, isVisible: !password.isEmpty)
//            ValidationMessage(text: "Contains a special character", isValid: password.range(of: "[@$!%*?&#]", options: .regularExpression) != nil, isVisible: !password.isEmpty)
//        }
    }
}

struct SignupAuthentication_Previews: PreviewProvider {
    static var previews: some View {
        SignupAuthentication()
    }
}
