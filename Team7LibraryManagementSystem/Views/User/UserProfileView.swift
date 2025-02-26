

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct UserProfileView: View {
    @State private var userProfile: UserProfile?
    @State private var isEditing = false
    @State private var showGenreSheet = false
    @State private var showLanguageSheet = false
    
       @State private var profileImage: UIImage? = nil
       @State private var showImagePicker = false

    private let db = Firestore.firestore()
    private let userId = Auth.auth().currentUser?.uid ?? ""

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Spacer()
                        Button(action: {
                            if isEditing {
                                showImagePicker = true
                            }
                        }) {
                            if let image = profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 100, height: 100)
                            }
                        }
                        .buttonStyle(PlainButtonStyle()) // ✅ Removes any extra button styling
                        .frame(width: 100, height: 100)  // ✅ Ensures the tappable area is the same as the circle
                        .background(Color.clear)          // ✅ Matches the background color
                        .clipShape(Circle())
                        Spacer()
                            
                    }
                }
                
                if let user = userProfile {
                    Section(header: Text("Personal Information")) {
                        ProfileRow(title: "First Name", value: binding(for: \.firstName), isEditing: isEditing)
                        ProfileRow(title: "Last Name", value: binding(for: \.lastName), isEditing: isEditing)
                      //  ProfileRow(title: "Date of Birth", value: binding(for: \.dob), isEditing: isEditing)
                        ProfileRow(title: "Email", value: .constant(user.email), isEditing: false)
//                        ProfileRow(title: "Phone No.", value: .constant(user.mobileNumber), isEditing: false)
                        ProfileRow(title: "Phone No.", value: binding(for: \.mobileNumber), isEditing: isEditing)
                      //  ProfileRow(title: "Email", value: binding(for: \.email), isEditing: isEditing)


                    }

                    Section(header: Text("Preferences")) {
                        PreferenceRow(title: "Preferred Genres", selections: user.genre, showSheet: $showGenreSheet)
                        PreferenceRow(title: "Preferred Languages", selections: user.language, showSheet: $showLanguageSheet)
                    }

                    Section {
                        Button(action: signOut) {
                            Text("Sign Out").foregroundColor(.red)
                        }
                    }
                } else {
                    Text("Loading profile...")
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing:
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing { saveProfile() }
                    isEditing.toggle()
                }
            )
            .onAppear(perform: fetchUserProfile)
        }
    }

    /// **Creates a safe binding for userProfile properties**
    private func binding(for keyPath: WritableKeyPath<UserProfile, String>) -> Binding<String> {
        Binding(
            get: { userProfile?[keyPath: keyPath] ?? "" },
            set: { newValue in
                if userProfile != nil {
                    userProfile![keyPath: keyPath] = newValue
                }
            }
        )
    }

//    private func fetchUserProfile() {
//        print("user id in profile page : \(userId)")
//        db.collection("users").document(userId).getDocument { document, error in
//            if let document = document, document.exists {
//                do {
//                    let data = try document.data(as: UserProfile.self)
//                    DispatchQueue.main.async {
//                        self.userProfile = data
//                    }
//                } catch {
//                    print("Error decoding user data: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
    
    private func fetchUserProfile() {
        print("User ID in profile page: \(userId)")
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error fetching document: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                print("Fetched document data: \(document.data() ?? [:])") // Debugging
                do {
                    let data = try document.data(as: UserProfile.self)
                    DispatchQueue.main.async {
                        self.userProfile = data
                    }
                } catch {
                    print("Error decoding user data: \(error.localizedDescription)")
                }
            } else {
                print("Document does not exist")
            }
        }
    }


    private func saveProfile() {
        
//        guard let user = Auth.auth().currentUser else { return }
//
//         if let newEmail = userProfile?.email, newEmail != user.email {
//             user.updateEmail(to: newEmail) { error in
//                 if let error = error {
//                     print("Error updating email: \(error.localizedDescription)")
//                     return
//                 }
//                 print("Email updated successfully in Firebase Auth")
//             }
//         }
        
        guard let user = userProfile else { return }
        do {
            try db.collection("users").document(userId).setData(from: user)
        } catch {
            print("Error saving profile: \(error.localizedDescription)")
        }
    }

  
        private func signOut() {
                do {
                    try Auth.auth().signOut()
                    // Navigate to login screen
                    // Use a root view reset approach
                    UIApplication.shared.windows.first?.rootViewController = UIHostingController(rootView: LibraryLoginView())
                    UIApplication.shared.windows.first?.makeKeyAndVisible()
                    print("User signed out")
                } catch {
                    print("Error signing out: \(error.localizedDescription)")
                }
            }
        
    
}

//struct ProfileRow: View {
//    let title: String
//    @Binding var value: String
//    var isEditing: Bool
//
//    var body: some View {
//        HStack {
//            Text(title)
//            Spacer()
//            if isEditing {
//                TextField("Enter \(title)", text: $value)
//                    .multilineTextAlignment(.trailing)
//            } else {
//                Text(value)
//            }
//        }
//    }
//}

struct PreferenceRow: View {
    let title: String
    let selections: [String]
    @Binding var showSheet: Bool

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Button(action: { showSheet = true }) {
                Text(selections.isEmpty ? "Select" : selections.joined(separator: ", "))
            }
        }
    }
}

//struct UserProfileView_Previews: PreviewProvider {
//    static var previews: some View {
//        UserProfileView()
//    }
//}
