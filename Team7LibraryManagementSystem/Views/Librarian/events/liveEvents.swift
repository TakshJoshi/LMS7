import SwiftUI
import FirebaseFirestore

struct EventModel: Identifiable {
    var id: String
    var title: String
    var description: String
    var coverImage: String
    var startTime: Date
    var endTime: Date
    var eventType: String
    var isLive: Bool
    var attendeesCount: Int
}

struct LiveEventsView: View {
    @State private var liveEvents: [EventModel] = []
    @State private var selectedCategory: String = "All"
    @State private var showingEventCreationView = false
    
    // Stats
    @State private var activeEventsCount: String = ""
    @State private var totalAttendeesCount: String = ""
    @State private var spacesInUse: String = ""
    
    private let db = Firestore.firestore()
    
    var categories = ["All", "Workshops", "Book Clubs", "Lect"]

    var filteredEvents: [EventModel] {
        if selectedCategory == "All" {
            return liveEvents
        } else {
            return liveEvents.filter {
                switch selectedCategory {
                case "Workshops": return $0.eventType == "Workshop"
                case "Book Clubs": return $0.eventType == "Book Club"
                case "Lect": return $0.eventType == "Lecture"
                default: return true
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack (spacing: 0){
                // Stats Header
                HStack(alignment: .center, spacing: 15) {
                    StatCard(icon: "", title: activeEventsCount, subtitle: "Active Events", color: .blue)
                    StatCard(icon: "", title: totalAttendeesCount, subtitle: "Attendees", color: .green)
                    StatCard(icon: "", title: spacesInUse, subtitle: "Spaces in Use", color: .red)
                    
                }
                .padding()
                .padding(.bottom, 15)
                .padding(.top, 25)
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .background(Color(.systemBackground))
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(categories, id: \.self) { category in
                            CategoryButton(category: category, selectedCategory: $selectedCategory)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Live Events List
                if filteredEvents.isEmpty {
                                    // Empty State
                    VStack {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                        Text("No live events")
                            .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight:.infinity)
                } else {
                    List(filteredEvents) { eventItem in
                        EventRow(eventItem: eventItem, endEvent: endEvent)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Live Events")
            .navigationBarItems(trailing:
                Button(action: {
                    showingEventCreationView = true
                }) {
                    Image(systemName: "plus")
                }
            )
            .onAppear(perform: fetchEvents)
            .sheet(isPresented: $showingEventCreationView) {
                EventCreationView()
            }
        }
    }

    // Fetch Events from Firebase Firestore
    private func fetchEvents() {
        db.collection("events")
            .whereField("status", isEqualTo: "Live")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching events: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                var events: [EventModel] = []
                var totalAttendees = 0
                var spacesUsed = 0
                
                for doc in documents {
                    let data = doc.data()
                    
                    let id = doc.documentID
                    let title = data["title"] as? String ?? "No Title"
                    let description = data["description"] as? String ?? "No Description"
                    let coverImage = data["coverImage"] as? String ?? ""
                    let startTime = (data["startDateTime"] as? Timestamp)?.dateValue() ?? Date()
                    let endTime = (data["endDateTime"] as? Timestamp)?.dateValue() ?? Date()
                    let eventType = data["eventType"] as? String ?? "Other"
                    let isLive = (data["status"] as? String ?? "") == "Live"
                    let attendeesCount = data["attendeesCount"] as? Int ?? 0

                    let eventItem = EventModel(
                        id: id,
                        title: title,
                        description: description,
                        coverImage: coverImage,
                        startTime: startTime,
                        endTime: endTime,
                        eventType: eventType,
                        isLive: isLive,
                        attendeesCount: attendeesCount
                    )
                    
                    events.append(eventItem)
                    totalAttendees += attendeesCount
                    spacesUsed += 1
                }
                
                liveEvents = events
                activeEventsCount = "\(events.count)"
                totalAttendeesCount = "\(totalAttendees)"
                spacesInUse = "\(spacesUsed)"
            }
    }

    // End Event Action
    private func endEvent(selectedEvent: EventModel) {
        db.collection("events").document(selectedEvent.id).updateData(["status": "Ended"]) { error in
            if let error = error {
                print("Error ending event: \(error)")
            } else {
                fetchEvents() // Refresh data
            }
        }
    }
}

// Stat Card View
struct StatCard3: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack {
            Text("\(value)")
                .font(.headline)
                .foregroundColor(.blue)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .frame(width: 120)
    }
}

// Category Button
struct CategoryButton: View {
    let category: String
    @Binding var selectedCategory: String

    var body: some View {
        Text(category)
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(selectedCategory == category ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundColor(selectedCategory == category ? Color.blue : Color.black)
            .clipShape(Capsule())
            .onTapGesture {
                selectedCategory = category
            }
    }
}

// Event Row UI
struct EventRow: View {
    let eventItem: EventModel
    var endEvent: ((EventModel) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(eventItem.title)
                    .font(.headline)
                
                Spacer()
                
                Text("● Live")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            HStack {
                Image(systemName: "calendar")
                Text("\(formattedTime(eventItem.startTime)) - \(formattedTime(eventItem.endTime))")
                Spacer()
            }
            .font(.caption)
            .foregroundColor(.gray)

            HStack {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "eye")
                        Text("View Details")
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button(action: { endEvent?(eventItem) }) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("End Event")
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

struct LiveEventsView_Previews: PreviewProvider {
    static var previews: some View {
        LiveEventsView()
    }
}

