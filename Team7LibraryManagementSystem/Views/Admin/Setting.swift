

import SwiftUI

struct Setting: View {
    @Environment(\.dismiss) var dismiss
    @State private var isOverdueNotificationsOn = true
    @State private var isBookRequestAlertsOn = true
    @State private var isSystemNotificationsOn = true

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Profile Section
                Section {
                    NavigationLink(destination: AdminProfile()) {
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 80)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading) {
                                Text("John Anderson")
                                    .font(.headline)
                                    .bold()
                                Text("Library Administrator")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("j.anderson@library.org")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                    }
                }
                
                // MARK: - Library Policies
                Section(header: Text("Library Policies")) {
                    NavigationLink(destination: Text("Manage Library Rules")) {
                        SettingsRow(icon: "book", title: "Manage Library Rules")
                    }
                    NavigationLink(destination: Text("Book Limits")) {
                        SettingsRow(icon: "book.closed", title: "Book Limits Per User")
                    }
                    NavigationLink(destination: Text("Fine Management")) {
                        SettingsRow(icon: "dollarsign.circle", title: "Fine Management")
                    }
                }

                // MARK: - Notifications & Alerts
                Section(header: Text("Notifications & Alerts")) {
                    ToggleRow(icon: "bell", title: "Overdue Notifications", isOn: $isOverdueNotificationsOn)
                    ToggleRow(icon: "envelope", title: "Book Request Alerts", isOn: $isBookRequestAlertsOn)
                    ToggleRow(icon: "gearshape", title: "System Notifications", isOn: $isSystemNotificationsOn)
                }

                // MARK: - Data Export
                Section(header: Text("Data Export")) {
                    Button(action: {}) {
                        ExportRow(icon: "doc", title: "Export Library Data (CSV)", description: "Complete database export")
                    }
                    Button(action: {}) {
                        ExportRow(icon: "chart.bar", title: "Generate PDF Report", description: "Monthly statistics and analytics")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
//                ToolbarItem(placement: .topBarLeading) {
//                    Button("Cancel") {
//                        dismiss()
//                    }
//                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        // Save settings action
                    }
                    .bold()
                }
            }
        }
    }
}

#Preview {
    Setting()
}
