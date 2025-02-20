//
//  AdminPermissionView.swift
//  LibraryManagement
//
//  Created by Taksh Joshi on 16/02/25.
//


import SwiftUI
import FirebaseFirestore

struct AdminPermissionView: View {
    var admin: Admin
    @State private var isActive: Bool
    @State private var permissions: [String: Bool] = [:]
    @State private var isLoading = false

    let db = Firestore.firestore()

    init(admin: Admin) {
        self.admin = admin
        _isActive = State(initialValue: admin.status == .active)
        _permissions = State(initialValue: [
            "View Users": false,
            "Edit Users": false,
            "Delete Users": false,
            "Create Content": false,
            "Edit Content": false,
            "Publish Content": false,
            "View Settings": false,
            "Modify Settings": false
        ])
    }

    var body: some View {
        VStack {
            Toggle("Active Status", isOn: $isActive)
                .padding()
                .onChange(of: isActive) { newValue in
                    updateAdminStatus(isActive: newValue)
                }
            
            Divider()
            
            Text("Permissions")
                .font(.headline)
                .padding(.top)
            
            ForEach(permissions.keys.sorted(), id: \.self) { key in
                Toggle(key, isOn: Binding(
                    get: { self.permissions[key] ?? false },
                    set: { self.permissions[key] = $0 }
                ))
                .padding(.horizontal)
            }
            
            Button(action: savePermissions) {
                Text(isLoading ? "Saving..." : "Save Changes")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(isLoading)
            .padding()
        }
        .onAppear {
            fetchPermissions()
        }
    }

    // Fetch current permissions from Firestore
    private func fetchPermissions() {
        db.collection("admins").document(admin.id).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                DispatchQueue.main.async {
                    let fetchedPermissions = data["permissions"] as? [String] ?? []
                    self.permissions = self.permissions.reduce(into: [:]) { result, pair in
                        result[pair.key] = fetchedPermissions.contains(pair.key)
                    }
                }
            }
        }
    }

    // Save updated permissions to Firestore
    private func savePermissions() {
        isLoading = true
        let selectedPermissions = permissions.filter { $0.value }.map { $0.key }

        db.collection("admins").document(admin.id).updateData([
            "permissions": selectedPermissions
        ]) { error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    print("Error updating permissions: \(error.localizedDescription)")
                }
            }
        }
    }

    // Update admin status (active/suspended) in Firestore
    private func updateAdminStatus(isActive: Bool) {
        let newStatus = isActive ? "active" : "suspended"
        db.collection("admins").document(admin.id).updateData([
            "status": newStatus
        ]) { error in
            if let error = error {
                print("Error updating status: \(error.localizedDescription)")
            }
        }
    }
}
