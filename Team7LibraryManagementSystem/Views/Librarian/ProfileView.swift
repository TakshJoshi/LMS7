import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isSigningOut = false

    let librarian = LibrarianProfile(
        name: "Sarah Anderson",
        role: "Senior Librarian",
        location: "Central Library",
        email: "sarah.anderson@library.com",
        phone: "(555) 123-4567",
        office: "Room 204, Second Floor",
        workingHours: WorkingHours(
            weekday: "9:00 AM - 5:00 PM",
            saturday: "10:00 AM - 2:00 PM",
            sunday: "Closed"
        ),
        currentTasks: [
            Task(
                title: "Catalog New Acquisitions",
                progress: 0.7,
                dueDate: "Due tomorrow"
            ),
            Task(
                title: "Monthly Report Preparation",
                progress: 0.4,
                dueDate: "Due in 3 days"
            ),
            Task(
                title: "Staff Training Session",
                progress: 0.2,
                dueDate: "Due next week"
            )
        ],
        skills: [
            "Cataloging",
            "Reference Services",
            "Digital Resources",
            "Collection Management",
            "Information Literacy",
            "Database Management"
        ],
        recentActivities: [
            Activity(
                icon: "book.fill",
                description: "Processed 25 new book acquisitions",
                timeAgo: "2 hours ago"
            ),
            Activity(
                icon: "person.2.fill",
                description: "Assisted 12 library visitors",
                timeAgo: "4 hours ago"
            ),
            Activity(
                icon: "checkmark.circle.fill",
                description: "Completed monthly inventory check",
                timeAgo: "Yesterday"
            ),
            Activity(
                icon: "network",
                description: "Updated digital catalog system",
                timeAgo: "2 days ago"
            )
        ]
    )
    var body: some View {
        NavigationStack {
            
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Profile Header
                    ProfileHeader(librarian: librarian)
                        .frame(maxWidth: .infinity)
                    
                    // Contact Details
                    SectionView2(title: "Contact Details") {
                        ContactDetailsView(librarian: librarian)
                    }
                    
                    // Working Hours
                    SectionView2(title: "Working Hours") {
                        WorkingHoursView(hours: librarian.workingHours)
                    }
                    
                    // Current Tasks
                    SectionView2(title: "Current Tasks") {
                        TasksView(tasks: librarian.currentTasks)
                    }
                    
                    // Skills & Expertise
                    SectionView2(title: "Skills & Expertise") {
                        SkillsView(skills: librarian.skills)
                    }
                    
                    // Recent Activities
                    SectionView2(title: "Recent Activities") {
                        ActivitiesView(activities: librarian.recentActivities)
                    }
                    
                    // Sign Out Button
                    // Sign Out Button
                                Button(action: {
                                    isSigningOut = true
                                }) {
                                    Text("Sign Out")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.red)
                                        .cornerRadius(10)
                                }
                                .padding(.top, 20)
                                .fullScreenCover(isPresented: $isSigningOut) {
                                    LibraryLoginView()
                                        .navigationBarBackButtonHidden(true)
                                }
                            }
                            .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        
        
    }
}
struct ProfileHeader: View {
    let librarian: LibrarianProfile
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    Image(librarian.profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                }
                
                Button(action: { showImagePicker = true }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                        .background(Color.white)
                        .clipShape(Circle())
                }
                .offset(x: 5, y: 5)
            }
            
            VStack(spacing: 4) {
                Text(librarian.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(librarian.role)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(librarian.location)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }
}

struct ContactDetailsView: View {
    let librarian: LibrarianProfile
    
    var body: some View {
        VStack(spacing: 16) {
            ContactRow(icon: "envelope.fill", text: librarian.email)
            ContactRow(icon: "phone.fill", text: librarian.phone)
            ContactRow(icon: "mappin.circle.fill", text: librarian.office)
        }
    }
}

struct ContactRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

struct WorkingHoursView: View {
    let hours: WorkingHours
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Monday - Friday")
                    .foregroundColor(.gray)
                Spacer()
                Text(hours.weekday)
                    .foregroundColor(.black)
            }
            
            HStack {
                Text("Saturday")
                    .foregroundColor(.gray)
                Spacer()
                Text(hours.saturday)
                    .foregroundColor(.black)
            }
            
            HStack {
                Text("Sunday")
                    .foregroundColor(.gray)
                Spacer()
                Text(hours.sunday)
                    .foregroundColor(.black)
            }
        }
    }
}

struct TasksView: View {
    let tasks: [Task]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(tasks) { task in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(task.title)
                            .font(.subheadline)
                        Spacer()
                        Text(task.dueDate)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    ProgressView(value: task.progress)
                        .tint(.blue)
                }
            }
        }
    }
}

struct SkillsView: View {
    let skills: [String]
    
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(skills, id: \.self) { skill in
                SkillBadge(skill: skill)
            }
        }
    }
}

struct SkillBadge: View {
    let skill: String
    
    var body: some View {
        Text(skill)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(16)
    }
}

struct ActivitiesView: View {
    let activities: [Activity]
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(activities) { activity in
                ActivityyRow(activity: activity)
            }
        }
    }
}

struct ActivityyRow: View {
    let activity: Activity
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: activity.icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.description)
                    .font(.subheadline)
                
                Text(activity.timeAgo)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}

struct SectionView2<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Helper view for flowing layout of skills
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth {
                currentX = 0
                currentY += size.height + spacing
            }
            
            currentX += size.width + spacing
            height = max(height, currentY + size.height)
        }
        
        return CGSize(width: maxWidth, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += size.height + spacing
            }
            
            view.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
        }
    }
}

// Models
struct LibrarianProfile {
    let name: String
    let role: String
    let location: String
    let profileImage = "Profile_pic"
    let email: String
    let phone: String
    let office: String
    let workingHours: WorkingHours
    let currentTasks: [Task]
    let skills: [String]
    let recentActivities: [Activity]
}

struct WorkingHours {
    let weekday: String
    let saturday: String
    let sunday: String
}

struct Task: Identifiable {
    let id = UUID()
    let title: String
    let progress: Double
    let dueDate: String
}

struct Activity: Identifiable {
    let id = UUID()
    let icon: String
    let description: String
    let timeAgo: String
}

// Image Picker
struct ImagePickerr: UIViewControllerRepresentable {
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
        let parent: ImagePickerr
        
        init(_ parent: ImagePickerr) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
} 
