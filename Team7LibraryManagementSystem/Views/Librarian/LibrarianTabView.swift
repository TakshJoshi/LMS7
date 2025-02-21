//
//  LinrarianTabView.swift
//  LinrarianSide
//
//  Created by Taksh Joshi on 20/02/25.
//

import SwiftUI

struct LibrarianTabView: View {
    var body: some View {
            TabView {
                libHomeView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                
                BooksView()
                    .tabItem {
                        Label("Books", systemImage: "book")
                    }
                
                LiveEventsView()
                    .tabItem {
                        Label("Events", systemImage: "calendar")
                    }
                
                libUsersView()
                    .tabItem {
                        Label("Users", systemImage: "person")
                    }
                
                
            }
        }
}

#Preview {
    LibrarianTabView()
}
