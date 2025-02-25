import SwiftUI
import FirebaseFirestore



struct UserEventsView: View {
    @State private var liveEvents: [EventModel] = []
    @State private var selectedCategory: String = "All"
    @State private var showingEventCreationView = false
    
    // Stats
    @State private var activeEventsCount: String = ""
    @State private var totalAttendeesCount: String = ""
    @State private var spacesInUse: String = ""
    
    private let db = Firestore.firestore()
    
    var categories = ["All", "Workshops", "Book Clubs", "Lecture","Social"]

    var filteredEvents: [EventModel] {
        if selectedCategory == "All" {
            return liveEvents
        } else {
            return liveEvents.filter {
                switch selectedCategory {
                case "Workshops": return $0.eventType == "Workshop"
                case "Book Clubs": return $0.eventType == "Book Club"
                case "Lecture": return $0.eventType == "Lecture"
                case "Social": return $0.eventType == "Social"
                default: return true
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
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
                        EventRow(eventItem: eventItem)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Events")
            .navigationBarItems(trailing:
                Button(action: { showingEventCreationView = true }) {
                    Image(systemName: "plus")
                }
            )
            .onAppear(perform: fetchEvents)
            .sheet(isPresented: $showingEventCreationView) {
                EventCreationView()
            }
        }
    }

    // Existing fetchEvents method remains the same

    // StatCard for the header
    struct StatCard: View {
        let icon: String
        let title: String
        let subtitle: String
        let color: Color
        
        var body: some View {
            VStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }


    // Fetch Events from Firebase Firestore
    private func fetchEvents() {
        let now = Date()
        
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

                    // Check if the event is in the future or currently ongoing
                    if endTime > now {
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
                }
                
                DispatchQueue.main.async {
                    self.liveEvents = events
                    self.activeEventsCount = "\(events.count)"
                    self.totalAttendeesCount = "\(totalAttendees)"
                    self.spacesInUse = "\(spacesUsed)"
                    
                    print("Filtered Events Count: \(events.count)")
                }
            }
    }
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



struct UserEventsView_Previews: PreviewProvider {
    static var previews: some View {
        UserEventsView()
    }
}

