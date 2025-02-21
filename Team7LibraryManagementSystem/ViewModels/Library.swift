////
////  Library.swift
////  Team7LibraryManagementSystem
////
////  Created by Taksh Joshi on 21/02/25.
////
import SwiftUI
import FirebaseFirestore

struct Library: Identifiable {
    let id: String
    let name: String
    let code: String
    let description: String
    let address: Address
    let contact: Contact
    let operationalHours: OperationalHours
    let settings: LibrarySettings
    let staff: Staff
    let features: Features
    let createdAt: Timestamp
}

struct Address {
    let line1: String
    let line2: String
    let city: String
    let state: String
    let zipCode: String
    let country: String
}

struct Contact {
    let phone: String
    let email: String
    let website: String
}

struct OperationalHours {
    let weekday: OpeningHours
    let weekend: OpeningHours
}

struct OpeningHours {
    let opening: String
    let closing: String
}

struct LibrarySettings {
    let maxBooksPerMember: String
    let lateFee: String
    let lendingPeriod: String
}

struct Staff {
    let headLibrarian: String
    let totalStaff: String
}

struct Features {
    let wifi: Bool
    let computerLab: Bool
    let meetingRooms: Bool
    let parking: Bool
}
