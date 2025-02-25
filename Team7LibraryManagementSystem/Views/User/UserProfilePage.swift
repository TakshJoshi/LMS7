import SwiftUI
import FirebaseAuth

struct UserProfileView: View {
    @State private var isEditing = false
    @State private var name = "Ish"
    @State private var phoneNumber = "3245445643"
    @State private var username = "Sidhd"
    @State private var email = "Fgusi@gmail.com"
    @State private var password = "********"
    @State private var profileImage: UIImage? = nil
    @State private var showImagePicker = false
    
    // Genre and Language
    @State private var selectedGenres: [String] = ["Science Fiction"]
    @State private var selectedLanguages: [String] = ["Spanish"]
    @State private var showGenreSheet = false
    @State private var showLanguageSheet = false
    
    // Predefined lists
    private let allGenres = [
        "Fiction", "Science Fiction", "Mystery",
        "Fantasy", "Romance", "Thriller",
        "Historical Fiction", "Horror", "Non-Fiction"
    ]
    
    private let allLanguages = [
        "English", "Spanish", "French", "German",
        "Chinese", "Hindi", "Arabic", "Russian",
        "Portuguese", "Japanese"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                // Profile Picture Section
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
                                    .overlay(
                                        Text(name.prefix(2).uppercased())
                                            .font(.title)
//                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        Spacer()
                    }
                }
                
                // Personal Information Section
                Section(header: Text("Personal Information")) {
                    ProfileRow(title: "Name", value: $name, isEditing: isEditing)
                    ProfileRow(title: "Username", value: $username, isEditing: isEditing)
                    ProfileRow(title: "Phone Number", value: $phoneNumber, isEditing: isEditing, keyboardType: .phonePad)
                    
                    // Email Row (typically not editable)
                    HStack {
                        Text("Email")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(email)
                            .foregroundColor(.black)
                    }
                    .padding(.vertical, 8)
                }
                
                // Reading Preferences Section
                Section(header: Text("Reading Preferences")) {
                    // Genres Dropdown
                    HStack {
                        Text("Preferred Genres")
                        Spacer()
                        Button(action: {
                            if isEditing {
                                showGenreSheet = true
                            }
                        }) {
                            Text(selectedGenres.isEmpty ? "Select Genres" : selectedGenres.joined(separator: ", "))
                                .foregroundColor(selectedGenres.isEmpty ? .gray : .primary)
                        }
                    }
                    
                    // Languages Dropdown
                    HStack {
                        Text("Preferred Languages")
                        Spacer()
                        Button(action: {
                            if isEditing {
                                showLanguageSheet = true
                            }
                        }) {
                            Text(selectedLanguages.isEmpty ? "Select Languages" : selectedLanguages.joined(separator: ", "))
                                .foregroundColor(selectedLanguages.isEmpty ? .gray : .primary)
                        }
                    }
                }
                
                // Security Section
                Section(header: Text("Security")) {
                    ProfileRow(title: "Password", value: $password, isEditing: isEditing, isSecure: true)
                }
                
                // Sign Out Section
                Section {
                    Button(action: signOut) {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing:
                Button(isEditing ? "Done" : "Edit") {
                    isEditing.toggle()
                    if !isEditing {
                        saveProfile()
                    }
                }
            )
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $profileImage)
            }
            .sheet(isPresented: $showGenreSheet) {
                MultiSelectSheet(
                    title: "Preferred Genres",
                    items: allGenres,
                    selectedItems: $selectedGenres
                )
            }
            .sheet(isPresented: $showLanguageSheet) {
                MultiSelectSheet(
                    title: "Preferred Languages",
                    items: allLanguages,
                    selectedItems: $selectedLanguages
                )
            }
        }
    }
    
    private func saveProfile() {
        // Implement profile saving logic
        print("Saving profile...")
        // You would typically update Firestore here
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            // Navigate to login screen or reset app state
            print("User signed out")
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

// Multi-Select Sheet for Genres and Languages
struct MultiSelectSheet: View {
    let title: String
    let items: [String]
    @Binding var selectedItems: [String]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(items, id: \.self) { item in
                    MultiSelectRow(
                        title: item,
                        isSelected: selectedItems.contains(item)
                    ) {
                        if selectedItems.contains(item) {
                            selectedItems.removeAll { $0 == item }
                        } else {
                            selectedItems.append(item)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Done") { dismiss() }
            )
        }
    }
}

// Multi-Select Row Component
struct MultiSelectRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}

// Improved Profile Row with more options
struct ProfileRow: View {
    var title: String
    @Binding var value: String
    var isEditing: Bool
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            if isEditing {
                if isSecure {
                    SecureField("Enter \(title)", text: $value)
                        .multilineTextAlignment(.trailing)
                } else {
                    TextField("Enter \(title)", text: $value)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(keyboardType)
                }
            } else {
                Text(value)
                    .foregroundColor(.black)
            }
        }
        .padding(.vertical, 5)
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView()
    }
}
