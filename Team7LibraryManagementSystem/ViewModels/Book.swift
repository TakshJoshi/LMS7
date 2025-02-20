//
//  books.swift
//  Team7LibraryManagementSystem
//
//  Created by Taksh Joshi on 18/02/25.
//

import Foundation

// Models for Google Books API
struct GoogleBooksResponse: Codable {
    let items: [Volume]
}

struct Volume: Codable {
    let id: String
    let volumeInfo: VolumeInfo
}

struct VolumeInfo: Codable {
    let title: String
    let authors: [String]?
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let pageCount: Int?
    let categories: [String]?
    let imageLinks: ImageLinks?
    let language: String?
    let industryIdentifiers: [IndustryIdentifier]?
}

struct ImageLinks: Codable {
    let thumbnail: String?
    let smallThumbnail: String?
}

struct IndustryIdentifier: Codable {
    let type: String
    let identifier: String
}

// Model for Library Book
// Model for Library Book
struct Book: Identifiable {
    let id: String
    let title: String
    let authors: [String]
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let pageCount: Int?
    let categories: [String]?
    let coverImageUrl: String?
    let isbn13: String?
    let language: String?
    
    // Library-specific data
    let quantity: Int
    let availableQuantity: Int
    let location: String
    let status: String
    let totalCheckouts: Int
    let currentlyBorrowed: Int
    let isAvailable: Bool
    
    // Added method to safely handle image URL
    func getImageUrl() -> URL? {
        guard let coverImageUrl = coverImageUrl,
              let encodedURL = coverImageUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURL) else {
            return nil
        }
        return url
    }
}
