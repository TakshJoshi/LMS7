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
      
    }
}

// Preview
#Preview {
    BookGridView()
}
