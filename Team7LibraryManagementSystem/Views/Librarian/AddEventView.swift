import SwiftUI

struct AddEventView: View {
    @Environment(\.dismiss) var dismiss
    @State private var eventTitle = ""
    @State private var description = ""
    @State private var location = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var selectedEventType = "Select Event Type"
    @State private var notifyMembers = false
    @State private var showImagePicker = false
    @State private var eventImage: UIImage?
    
    let eventTypes = ["Workshop", "Book Club", "Lecture", "Story Time", "Discussion"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Image Upload Section
                    Button(action: { showImagePicker = true }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                                .frame(height: 200)
                            
                            if let image = eventImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "camera")
                                        .font(.system(size: 24))
                                        .foregroundColor(.gray)
                                    Text("Add Event Cover Image")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    
                    // Event Details Form
                    Group {
                        InputSection(title: "Event Title") {
                            TextField("Enter event title", text: $eventTitle)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        InputSection(title: "Description") {
                            TextField("Enter event description", text: $description)
                                .textFieldStyle(CustomTextFieldStyle())
                                .frame(height: 100)
                        }
                        
                        HStack(spacing: 16) {
                            InputSection(title: "Start Date") {
                                DateButton(date: $startDate, placeholder: "Select date")
                            }
                            
                            InputSection(title: "End Date") {
                                DateButton(date: $endDate, placeholder: "Select Date")
                            }
                        }
                        
                        HStack(spacing: 16) {
                            InputSection(title: "Start Time") {
                                TimeButton(time: $startTime, placeholder: "Select Time")
                            }
                            
                            InputSection(title: "End Time") {
                                TimeButton(time: $endTime, placeholder: "Select time")
                            }
                        }
                        
                        InputSection(title: "Location") {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.gray)
                                TextField("Enter event location", text: $location)
                            }
                            .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Event Type Picker
                        Menu {
                            ForEach(eventTypes, id: \.self) { type in
                                Button(type) {
                                    selectedEventType = type
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedEventType)
                                    .foregroundColor(selectedEventType == "Select Event Type" ? .gray : .black)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                    
                    // Notifications Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("NOTIFICATIONS")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Toggle(isOn: $notifyMembers) {
                            Text("Notify Library Members")
                                .font(.subheadline)
                        }
                        
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "paperclip")
                                Text("Add Attachments")
                            }
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        }
                    }
                    
                    // Create Button
                    Button(action: createEvent) {
                        Text("Create Event")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.top)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Events")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                    }
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $eventImage)
        }
    }
    
    func createEvent() {
        // Implement event creation logic
        dismiss()
    }
}

struct InputSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
            content
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
    }
}

struct DateButton: View {
    @Binding var date: Date
    let placeholder: String
    
    var body: some View {
        DatePicker(
            "",
            selection: $date,
            displayedComponents: [.date]
        )
        .labelsHidden()
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct TimeButton: View {
    @Binding var time: Date
    let placeholder: String
    
    var body: some View {
        DatePicker(
            "",
            selection: $time,
            displayedComponents: [.hourAndMinute]
        )
        .labelsHidden()
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
    }
} 
