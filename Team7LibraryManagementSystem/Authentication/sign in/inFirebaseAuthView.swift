////
////  inFirebaseAuthView.swift
////  Team7test
////
////  Created by Hardik Bhardwaj on 13/02/25.
//
import SwiftUI
import FirebaseAuth
import Network
import FirebaseFirestore
struct FirebaseAuthView: View {
    let userRole: String
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var isAuthenticating = false
    @State private var navigateTo2FA = false
    @State private var navigateToMainTab = false
    @State private var navigateToBooksView = false
    @State private var showForgotPassword = false
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var showNetworkAlert = false
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "book.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text("Sign In as \(userRole.capitalized)")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Authentication Required")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            TextField("Email", text: $email)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
            
            SecureField("Password", text: $password)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .padding(.horizontal)
            }
            
            Button(action: loginUser) {
                if isAuthenticating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Sign In")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .disabled(isAuthenticating)
            .padding(.horizontal)
            
            Button("Forgot Password?") {
                showForgotPassword = true
            }
            .font(.footnote)
            .foregroundColor(.blue)
            
            Spacer()
        }
        .padding()
        .fullScreenCover(isPresented: $navigateTo2FA) {
            TwoFactorAuthenticationView(role: userRole, email: email)
        }
        .fullScreenCover(isPresented: $navigateToMainTab) {
            MainTabView()
        }
        .fullScreenCover(isPresented: $navigateToBooksView) {
            BooksView()
        }
        .alert("Reset Password", isPresented: $showForgotPassword) {
            TextField("Enter your email", text: $email)
            Button("Cancel", role: .cancel) { }
            //            Button("Reset") {
            //                resetPassword()
            //            }
        } message: {
            Text("Enter your email to receive password reset instructions")
        }
        .alert("Network Error", isPresented: $showNetworkAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please check your internet connection and try again.")
        }
        .onChange(of: networkMonitor.isConnected) { isConnected in
            if !isConnected {
                showNetworkAlert = true
            }
        }
    }
    
    private func loginUser() {
            guard networkMonitor.isConnected else {
                showNetworkAlert = true
                return
            }
            
            isAuthenticating = true
            errorMessage = nil
            
            FirebaseAuthManager.shared.signIn(email: email, password: password) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let role):
                        let lowercasedRole = role.lowercased()
                        let selectedRole = userRole.lowercased()
                        
                        // Verify email exists in the correct role table
                        verifyUserRole(email: email, role: selectedRole) { isValid, message in
                            if isValid {
                                // Generate OTP for 2FA
                                FirebaseManager.shared.generateAndSendOTP(email: email) { success, otpMessage in
                                    if success {
                                        UserDefaults.standard.set(role, forKey: "userRole")
                                        navigateTo2FA = true
                                    } else {
                                        errorMessage = otpMessage
                                    }
                                    isAuthenticating = false
                                }
                            } else {
                                isAuthenticating = false
                                errorMessage = message
                            }
                        }

                    case .failure(let error):
                        isAuthenticating = false
                        if (error as NSError).code == -1009 {
                            showNetworkAlert = true
                        } else {
                            errorMessage = "Invalid Credentials"
                        }
                    }
                }
            }
        }

        
        func verifyUserRole(email: String, role: String, completion: @escaping (Bool, String) -> Void) {
            let collectionName: String
            
            switch role {
            case "admin":
                collectionName = "admins"
            case "librarian":
                collectionName = "librarians"
            case "user":
                collectionName = "users"
            default:
                completion(false, "Invalid role selection")
                return
            }
            
            let db = Firestore.firestore()
            db.collection(collectionName).whereField("email", isEqualTo: email).getDocuments { snapshot, error in
                if let error = error {
                    completion(false, "Error checking role: \(error.localizedDescription)")
                } else if let snapshot = snapshot, !snapshot.documents.isEmpty {
                    completion(true, "")
                } else {
                    completion(false, "Access denied: Email does not belong to the selected role")
                }
            }
        }
    
    @MainActor
    //    private func resetPassword() {
    //        FirebaseAuthManager.shared.resetPassword(email: email) { result in
    //            DispatchQueue.main.async {
    //                switch result {
    //                case .success:
    //                    self.errorMessage = "Password reset email sent"
    //                case .failure(let error):
    //                    self.errorMessage = error.localizedDescription
    //                }
    //            }
    //        }
    //    }
    //}
    
    struct FirebaseAuthView_Previews: PreviewProvider {
        static var previews: some View {
            FirebaseAuthView(userRole: "admin")
        }
    }
}
