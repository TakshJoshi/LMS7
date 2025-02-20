//
//  SwiftUIView.swift
//  LibraryManagement
//
//  Created by Taksh Joshi on 16/02/25.
//

import SwiftUI
import FirebaseAuth

struct Setting: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isOverdueNotificationsOn = true
    @State private var isBookRequestAlertsOn = true
    @State private var isSystemNotificationsOn = true
    @State private var isLoggedOut = false  // Track logout state
    
    @State private var userName: String = "User"
    @State private var userEmail: String = "user@example.com"
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Section
                        VStack {
                            HStack {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                                    
                                VStack(alignment: .leading) {
                                    Text(userName)
                                        .font(.headline)
                                        .bold()
                                    Text("Library User")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Text(userEmail)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .padding()
                            
                            Button(action: {}) {
                                Text("Edit Profile")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .padding(.bottom, 10)
                            }
                            .padding(.horizontal)
                        }
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .background(Color(.systemGray6))
                        
                        Divider()

                        SectionViewSetting(title: "Library Policies")
                        SettingsRow(icon: "book", title: "Manage Library Rules")
                        SettingsRow(icon: "book.closed", title: "Book Limits Per User")
                        SettingsRow(icon: "dollarsign.circle", title: "Fine Management")

                        Divider()

                        SectionViewSetting(title: "Notifications & Alerts")
                        ToggleRow(icon: "bell", title: "Overdue Notifications", isOn: $isOverdueNotificationsOn)
                        ToggleRow(icon: "envelope", title: "Book Request Alerts", isOn: $isBookRequestAlertsOn)
                        ToggleRow(icon: "gearshape", title: "System Notifications", isOn: $isSystemNotificationsOn)

                        Divider()

                        SectionViewSetting(title: "Data Export")
                        ExportRow(icon: "doc", title: "Export Library Data (CSV)", description: "Complete database export")
                        ExportRow(icon: "chart.bar", title: "Generate PDF Report", description: "Monthly statistics and analytics")

                        Divider()

                        // Logout Button
                        Button(action: logout) {
                            Text("Log Out")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                        .padding(.top, 20)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
//                        Image(systemName: "chevron.left")
//                            .foregroundColor(.blue)
                    }
                }
            }
            .onAppear {
                fetchUserData()
            }
            
            // Navigate to Login on Logout
            NavigationLink(destination: LibraryLoginView(), isActive: $isLoggedOut) {
                EmptyView()
            }
        }
    }
    
    // MARK: - Fetch Firebase User Data
    private func fetchUserData() {
        if let user = Auth.auth().currentUser {
            self.userName = user.displayName ?? "Library User"
            self.userEmail = user.email ?? "user@example.com"
        }
    }

    // MARK: - Logout Function
    private func logout() {
        do {
            try Auth.auth().signOut()
            isLoggedOut = true  // Trigger navigation to LibraryLoginView
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}


// MARK: - Preview
#Preview {
    Setting()
}
