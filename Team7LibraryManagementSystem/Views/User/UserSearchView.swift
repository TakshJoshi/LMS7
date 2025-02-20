//import SwiftUI
//
//struct BookGridView: View {
//    @State private var searchText = ""
//    
//    let columns = [
//        GridItem(.flexible(), spacing: 35),
//        GridItem(.flexible(), spacing: 12)
//    ]
//    
//    var body: some View {
//        NavigationView {
//            VStack {
//
//                
//                HStack {
//                    Image(systemName: "magnifyingglass")
//                        .foregroundColor(.gray)
//                        .padding(.leading, 10)
//                    
//                    TextField("Search", text: $searchText)
//                        .padding(5)
//                }
//                .padding(1)
//                .background(Color(.systemGray6))
//                .cornerRadius(10)
//                .padding(.horizontal)

//
//
//                // Book Grid
//                ScrollView {
//                    LazyVGrid(columns: columns, spacing: 16) {
//                        ForEach(0..<4, id: \.self) { _ in // Dummy Loop for 4 items
//                            NavigationLink(destination: BookDetailView(title: "The Silent Echo", author: "Sarah Mitchell")) {
//                                BookCard(imageName: "book1", title: "The Silent Echo", author: "Sarah Mitchell", description: "A gripping tale of mystery and self-")
//                            }
//                        }
//                    }
//                    .padding()
//                }
//            }
//            .navigationTitle("Books")
//        }
//    }
//}
//
//
//
//
//// Preview
//#Preview {
//    BookGridView()
//}
//


import SwiftUI

struct BookGridView: View {
    @State private var searchText = ""

    let columns = [
        GridItem(.flexible(), spacing: 35),
        GridItem(.flexible(), spacing: 35)
    ]

    var body: some View {
        NavigationStack {
            VStack {
                searchBar()

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(0..<4, id: \.self) { _ in
                            bookCard()
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Books")
        }
    }

    // Extracted Search Bar
    @ViewBuilder
    private func searchBar() -> some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.leading, 10)
            
            TextField("Search", text: $searchText)
                .padding(5)
        }
        .padding(1)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    // Extracted Book Card
    @ViewBuilder
    private func bookCard() -> some View {
        NavigationLink(destination: UserBookDetailView(title: "The Silent Echo", author: "Sarah Mitchell")) {
            UserBookCard(imageName: "book1", title: "The Silent Echo", author: "Sarah Mitchell", description: "A gripping tale of mystery and self-")
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Preview
#Preview {
    BookGridView()
}
