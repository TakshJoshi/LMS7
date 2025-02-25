//
//  SwiftUIView.swift
//  Team7LibraryManagementSystem
//
//  Created by Taksh Joshi on 25/02/25.
//
import SwiftUI
import FirebaseFirestore

struct EachEventView: View {
    let event: EventModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Image and Title
                ZStack(alignment: .bottomLeading) {
                    // Event Cover Image (placeholder for now)
                    Image(systemName: "photo.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                        .foregroundColor(.gray)
                    
                    HStack {
                        Text(event.title)
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.white)
                            Text(formattedEventType)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                
                // Event Details Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("About Event")
                        .font(.headline)
                    
                    Text(event.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                // Date and Time Information
                EventInfoRow(
                    icon: "clock",
                    title: "Date & Time",
                    value: formattedDateTime
                )
                
                // Event Type
                EventInfoRow(
                    icon: "tag",
                    title: "Event Type",
                    value: event.eventType
                )
                
                // Attendees Information
                EventInfoRow(
                    icon: "person.3",
                    title: "Attendees",
                    value: "\(event.attendeesCount) Registered"
                )
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: registerForEvent) {
                        Text("Register for Event")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: shareEvent) {
                        Text("Share Event")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Formatted Event Type
    private var formattedEventType: String {
        return event.eventType.capitalized
    }
    
    // Formatted Date and Time
    private var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        return "\(formatter.string(from: event.startTime)) • \(timeFormatter.string(from: event.startTime)) - \(timeFormatter.string(from: event.endTime))"
    }
    
    // Register for Event Action
    private func registerForEvent() {
        // TODO: Implement event registration logic
        print("Registering for event: \(event.title)")
    }
    
    // Share Event Action
    private func shareEvent() {
        // TODO: Implement event sharing functionality
        print("Sharing event: \(event.title)")
    }
}

// Reusable Event Info Row
struct EventInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.body)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// Preview for development
struct EachEventView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EachEventView(event: EventModel(
                id: "1",
                title: "Book Reading Session",
                description: "Join us for an exciting book reading session with local authors.",
                coverImage: "",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                eventType: "Book Club",
                isLive: true,
                attendeesCount: 25
            ))
        }
    }
}
