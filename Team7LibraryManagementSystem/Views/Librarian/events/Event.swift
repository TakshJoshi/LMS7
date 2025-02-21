//
//  Event.swift
//  Team7test
//
//  Created by Hardik Bhardwaj on 21/02/25.
//


//import SwiftUI
//import FirebaseStorage
//import FirebaseFirestore
//
//struct Event: Identifiable {
//    var id = UUID()
//    var coverImage: UIImage?
//    var title: String
//    var description: String
//    var startDate: Date
//    var endDate: Date
//    var startTime: Date
//    var endTime: Date
//    var location: String
//    var eventType: String
//    var notifyMembers: Bool
//}
//
//struct EventCreationView: View {
//    @State private var event = Event(
//        title: "",
//        description: "",
//        startDate: Date(),
//        endDate: Date(),
//        startTime: Date(),
//        endTime: Date(),
//        location: "",
//        eventType: "",
//        notifyMembers: false
//    )
//    
//    @State private var showingImagePicker = false
//    @State private var selectedImage: UIImage?
//    @State private var showingAlert = false
//    @State private var alertMessage = ""
//    
//    private let eventTypes = ["Meeting", "Workshop", "Conference", "Social"]
//    
//    var body: some View {
//        NavigationView {
//            Form {
//                // Image Section
//                Section {
//                    VStack {
//                        if let image = selectedImage {
//                            Image(uiImage: image)
//                                .resizable()
//                                .scaledToFit()
//                                .frame(height: 200)
//                        } else {
//                            Button(action: {
//                                showingImagePicker = true
//                            }) {
//                                VStack {
//                                    Image(systemName: "camera")
//                                        .font(.system(size: 30))
//                                        .foregroundColor(.gray)
//                                    Text("Add Event Cover Image")
//                                        .foregroundColor(.gray)
//                                }
//                                .frame(height: 100)
//                            }
//                        }
//                    }
//                    .frame(maxWidth: .infinity)
//                    .background(Color(.systemGray6))
//                    .cornerRadius(8)
//                }
//                
//                // Event Details Section
//                Section(header: Text("Event Details")) {
//                    TextField("Event Title", text: $event.title)
//                    TextField("Description", text: $event.description)
//                }
//                
//                // Date and Time Section
//                Section(header: Text("Date & Time")) {
//                    DatePicker("Start Date",
//                             selection: $event.startDate,
//                             displayedComponents: .date)
//                    
//                    DatePicker("End Date",
//                             selection: $event.endDate,
//                             displayedComponents: .date)
//                    
//                    DatePicker("Start Time",
//                             selection: $event.startTime,
//                             displayedComponents: .hourAndMinute)
//                    
//                    DatePicker("End Time",
//                             selection: $event.endTime,
//                             displayedComponents: .hourAndMinute)
//                }
//                
//                // Location Section
//                Section(header: Text("Location")) {
//                    TextField("Enter event location", text: $event.location)
//                }
//                
//                // Event Type Section
//                Section(header: Text("Event Type")) {
//                    Picker("Select Event Type", selection: $event.eventType) {
//                        Text("Select Type").tag("")
//                        ForEach(eventTypes, id: \.self) { type in
//                            Text(type).tag(type)
//                        }
//                    }
//                }
//                
//                // Notifications Section
//                Section {
//                    Toggle(isOn: $event.notifyMembers) {
//                        HStack {
//                            Image(systemName: "bell")
//                            Text("Notify Library Members")
//                        }
//                    }
//                }
//                
//                // Attachments Section
//                Section {
//                    Button(action: {
//                        // Handle attachments
//                    }) {
//                        HStack {
//                            Image(systemName: "paperclip")
//                            Text("Add Attachments")
//                        }
//                    }
//                }
//                
//                // Create Event Button
//                Section {
//                    Button(action: createEvent) {
//                        Text("Create Event")
//                            .frame(maxWidth: .infinity)
//                            .foregroundColor(.white)
//                    }
//                    .listRowBackground(Color.blue)
//                }
//            }
//            .navigationTitle("Events")
//            .sheet(isPresented: $showingImagePicker) {
//                ImagePicker(image: $selectedImage)
//            }
//            .alert("Event Creation", isPresented: $showingAlert) {
//                Button("OK", role: .cancel) { }
//            } message: {
//                Text(alertMessage)
//            }
//        }
//    }
//    
//    private func createEvent() {
//        // Upload image to Firebase Storage
//        if let image = selectedImage {
//            uploadImage(image) { imageUrl in
//                // Save event data to Firestore
//                saveEventData(imageUrl: imageUrl)
//            }
//        } else {
//            saveEventData(imageUrl: nil)
//        }
//    }
//    
//    private func uploadImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
//        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
//            completion(nil)
//            return
//        }
//        
//        let storageRef = Storage.storage().reference()
//        let imageRef = storageRef.child("eventImages/\(UUID().uuidString).jpg")
//        
//        imageRef.putData(imageData, metadata: nil) { metadata, error in
//            if let error = error {
//                print("Error uploading image: \(error)")
//                completion(nil)
//                return
//            }
//            
//            imageRef.downloadURL { url, error in
//                completion(url?.absoluteString)
//            }
//        }
//    }
//    
//    private func saveEventData(imageUrl: String?) {
//        let db = Firestore.firestore()
//        
//        let eventData: [String: Any] = [
//            "title": event.title,
//            "description": event.description,
//            "startDate": event.startDate,
//            "endDate": event.endDate,
//            "startTime": event.startTime,
//            "endTime": event.endTime,
//            "location": event.location,
//            "eventType": event.eventType,
//            "notifyMembers": event.notifyMembers,
//            "coverImage": imageUrl as Any,
//            "createdAt": FieldValue.serverTimestamp()
//        ]
//        
//        db.collection("events").addDocument(data: eventData) { error in
//            if let error = error {
//                alertMessage = "Error creating event: \(error.localizedDescription)"
//            } else {
//                alertMessage = "Event created successfully!"
//                // Reset form
//                resetForm()
//            }
//            showingAlert = true
//        }
//    }
//    
//    private func resetForm() {
//        event = Event(
//            title: "",
//            description: "",
//            startDate: Date(),
//            endDate: Date(),
//            startTime: Date(),
//            endTime: Date(),
//            location: "",
//            eventType: "",
//            notifyMembers: false
//        )
//        selectedImage = nil
//    }
//}
//
//// Image Picker Component
//struct ImagePicker: UIViewControllerRepresentable {
//    @Binding var image: UIImage?
//    @Environment(\.presentationMode) var presentationMode
//    
//    func makeUIViewController(context: Context) -> UIImagePickerController {
//        let picker = UIImagePickerController()
//        picker.delegate = context.coordinator
//        return picker
//    }
//    
//    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//    
//    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
//        let parent: ImagePicker
//        
//        init(_ parent: ImagePicker) {
//            self.parent = parent
//        }
//        
//        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
//            if let image = info[.originalImage] as? UIImage {
//                parent.image = image
//            }
//            parent.presentationMode.wrappedValue.dismiss()
//        }
//    }
//}
//
//struct EventCreationView_Previews: PreviewProvider {
//    static var previews: some View {
//        EventCreationView()
//    }
//}
import SwiftUI
import FirebaseStorage
import FirebaseFirestore

struct Event: Identifiable {
    var id = UUID()
    var coverImage: UIImage?
    var title: String
    var description: String
    var startDateTime: Date
    var endDateTime: Date
    var location: String
    var eventType: String
    var notifyMembers: Bool
    var status: String = "Live" // 🟢 Event status set to "Live"

    var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy h:mm a" // Example: Feb 21, 2025 3:30 PM
        return "\(formatter.string(from: startDateTime)) - \(formatter.string(from: endDateTime))"
    }
}

struct EventCreationView: View {
    @State private var event = Event(
        title: "",
        description: "",
        startDateTime: Date(),
        endDateTime: Date(),
        location: "",
        eventType: "",
        notifyMembers: false
    )

    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingAlert = false
    @State private var alertMessage = ""

    private let eventTypes = ["Meeting", "Workshop", "Conference", "Social"]

    var body: some View {
        NavigationView {
            Form {
                // 📷 Image Section
                Section {
                    VStack {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                        } else {
                            Button(action: { showingImagePicker = true }) {
                                VStack {
                                    Image(systemName: "camera")
                                        .font(.system(size: 30))
                                        .foregroundColor(.gray)
                                    Text("Add Event Cover Image")
                                        .foregroundColor(.gray)
                                }
                                .frame(height: 100)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }

                // 📝 Event Details Section
                Section(header: Text("Event Details")) {
                    TextField("Event Title", text: $event.title)
                    TextField("Description", text: $event.description)
                }

                // 📅 Date & Time Selection
                Section(header: Text("Date & Time")) {
                    DatePicker("Start Date & Time", selection: $event.startDateTime, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("End Date & Time", selection: $event.endDateTime, displayedComponents: [.date, .hourAndMinute])
                }

                // 📍 Location Section
                Section(header: Text("Location")) {
                    TextField("Enter event location", text: $event.location)
                }

                // 🎟 Event Type Section
                Section(header: Text("Event Type")) {
                    Picker("Select Event Type", selection: $event.eventType) {
                        Text("Select Type").tag("")
                        ForEach(eventTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }

                // 🔔 Notifications Section
                Section {
                    Toggle(isOn: $event.notifyMembers) {
                        HStack {
                            Image(systemName: "bell")
                            Text("Notify Library Members")
                        }
                    }
                }

                // 📎 Attachments Section
                Section {
                    Button(action: { }) {
                        HStack {
                            Image(systemName: "paperclip")
                            Text("Add Attachments")
                        }
                    }
                }

                // 🚀 Create Event Button
                Section {
                    Button(action: createEvent) {
                        Text("Create Event")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.blue)
                }
            }
            .navigationTitle("Events")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .alert("Event Creation", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    // 📤 Upload Image to Firebase
    private func uploadImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(nil)
            return
        }

        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("eventImages/\(UUID().uuidString).jpg")

        imageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Error uploading image: \(error)")
                completion(nil)
                return
            }

            imageRef.downloadURL { url, _ in
                completion(url?.absoluteString)
            }
        }
    }

    // 💾 Save Event Data to Firestore
    private func saveEventData(imageUrl: String?) {
        let db = Firestore.firestore()

        let eventData: [String: Any] = [
            "title": event.title,
            "description": event.description,
            "startDateTime": event.startDateTime,
            "endDateTime": event.endDateTime,
            "location": event.location,
            "eventType": event.eventType,
            "notifyMembers": event.notifyMembers,
            "coverImage": imageUrl as Any,
//            "createdAt": FieldValue.serverTimestamp(),
            "status": "Live" // 🟢 Marking event as Live upon creation
        ]

        db.collection("events").addDocument(data: eventData) { error in
            if let error = error {
                alertMessage = "Error creating event: \(error.localizedDescription)"
            } else {
                alertMessage = "Event created successfully!"
                resetForm()
            }
            showingAlert = true
        }
    }

    // 🔄 Create Event Function
    private func createEvent() {
        if let image = selectedImage {
            uploadImage(image) { imageUrl in
                saveEventData(imageUrl: imageUrl)
            }
        } else {
            saveEventData(imageUrl: nil)
        }
    }

    // ♻️ Reset Form
    private func resetForm() {
        event = Event(
            title: "",
            description: "",
            startDateTime: Date(),
            endDateTime: Date(),
            location: "",
            eventType: "",
            notifyMembers: false
        )
        selectedImage = nil
    }
}

// 📷 Image Picker Component
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct EventCreationView_Previews: PreviewProvider {
    static var previews: some View {
        EventCreationView()
    }
}
