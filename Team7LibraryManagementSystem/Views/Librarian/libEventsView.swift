import SwiftUI

struct EventsView: View {
    @State private var selectedFilter: String = "All"
    let filters = ["All", "Workshops", "Book Clubs", "Lectures"]
    
    let stats = EventStats(
        activeEvents: 12,
        attendees: 234,
        spacesInUse: 4
    )
    
    let events = [
        Event(
            title: "Book Club: Mystery Novels",
            location: "Reading Room A",
            startTime: "10:00 AM",
            endTime: "11:30 AM",
            attendees: 25,
            isLive: true
        ),
        Event(
            title: "Children's Story Time",
            location: "Kids Corner",
            startTime: "2:00 PM",
            endTime: "3:00 PM",
            attendees: 45,
            isLive: true
        ),
        Event(
            title: "Digital Skills Workshop",
            location: "Computer Lab",
            startTime: "3:30 PM",
            endTime: "5:00 PM",
            attendees: 15,
            isLive: true
        ),
        Event(
            title: "Author Talk: Local Writers",
            location: "Main Hall",
            startTime: "4:00 PM",
            endTime: "5:30 PM",
            attendees: 92,
            isLive: true
        ),
        Event(
            title: "Poetry Reading Circle",
            location: "Study Room 2",
            startTime: "5:00 PM",
            endTime: "6:30 PM",
            attendees: 18,
            isLive: true
        ),
        Event(
            title: "Teen Book Discussion",
            location: "Teen Zone",
            startTime: "4:30 PM",
            endTime: "6:00 PM",
            attendees: 22,
            isLive: true
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            EventsHeaderView()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Stats Section
                    EventStatsSection(stats: stats)
                    
                    // Filters
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(filters, id: \.self) { filter in
                                FilterButton(title: filter, isSelected: selectedFilter == filter) {
                                    selectedFilter = filter
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Events List
                    VStack(spacing: 16) {
                        ForEach(events) { event in
                            EventRow(event: event)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
    }
}

struct EventsHeaderView: View {
    @State private var showAddEvent = false
    
    var body: some View {
        HStack {
            Text("Live Events")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            Button(action: { showAddEvent = true }) {
                Image(systemName: "plus")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.white)
        .sheet(isPresented: $showAddEvent) {
            AddEventView()
        }
    }
}

struct EventStatsSection: View {
    let stats: EventStats
    
    var body: some View {
        HStack(spacing: 16) {
            EventStatItem(value: "\(stats.activeEvents)", label: "Active\nEvents")
            EventStatItem(value: "\(stats.attendees)", label: "Attendees")
            EventStatItem(value: "\(stats.spacesInUse)", label: "Spaces in\nUse")
        }
        .padding(.horizontal)
    }
}

struct EventStatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .black)
                .cornerRadius(20)
        }
    }
}

struct EventRow: View {
    let event: Event
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.gray)
                        Text(event.location)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                if event.isLive {
                    Text("Live")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.gray)
                Text("\(event.startTime) - \(event.endTime)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Image(systemName: "person.2")
                    .foregroundColor(.gray)
                Text("\(event.attendees) attendees")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Button(action: {}) {
                    Text("View Details")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Text("End Event")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Models
struct EventStats {
    let activeEvents: Int
    let attendees: Int
    let spacesInUse: Int
}

struct Event: Identifiable {
    let id = UUID()
    let title: String
    let location: String
    let startTime: String
    let endTime: String
    let attendees: Int
    let isLive: Bool
} 