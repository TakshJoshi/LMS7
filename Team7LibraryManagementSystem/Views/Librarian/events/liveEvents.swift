import SwiftUI
import FirebaseFirestore


//struct EventModel: Identifiable {
//    var id: String
//    var title: String
//    var description: String
//    var coverImage: String
//    var startTime: Date
//    var endTime: Date
//    var eventType: String
//    var isLive: Bool
//    var attendeesCount: Int
//}
struct LiveEventsView: View {
    @State private var liveEvents: [EventModel] = []
    @State private var selectedCategory: String = "All"
    @State private var showingEventCreationView = false
    
    // Stats
    @State private var activeEventsCount: String = ""
    @State private var totalAttendeesCount: String = ""
    @State private var spacesInUse: String = ""
    
    @State private var eventStatus: String = ""
    
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
                case "Lecture": return $0.eventType == "Lecture"
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
                        EventRow(eventItem: eventItem)
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
        let now = Date()
        
        db.collection("events")
            .whereField("endDateTime", isGreaterThan: now)
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
                    let isLive = true // Since we're filtering by endDateTime
                    let attendeesCount = data["attendeesCount"] as? Int ?? 0
                    if(isLive){
                        eventStatus = "Live"
                    } else {
                        eventStatus = "Ended"
                    }
                    
                    let eventItem = EventModel(
                        id: id,
                        title: title,
                        description: description,
                        coverImage: coverImage,
                        startTime: startTime,
                        endTime: endTime,
                        eventType: eventType,
                       // coverImage: coverImage,
                        location: " ",
                        notifyMembers: false,
                       
                        status: eventStatus
                      //  isLive: isLive,
                       // attendeesCount: attendeesCount
                    )
                    
                    events.append(eventItem)
                    totalAttendees += attendeesCount
                    spacesUsed += 1
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
// Event Row UI
import SwiftUI

struct EventRow: View {
    let eventItem: EventModel

    var body: some View {
        NavigationLink(destination: EachEventView(event: eventItem)) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(eventItem.title)
                        .font(.headline)
                    
                    Text("\(formattedDate(eventItem.startTime)) - \(formattedDate(eventItem.endTime))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                HStack {
                    Text("● Live")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
        }
    }

    private func formattedDate(_ date: Date) -> String {
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

