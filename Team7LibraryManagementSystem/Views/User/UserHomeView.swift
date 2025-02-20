


import SwiftUI

struct UserHomeView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeScreen()
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }

            NavigationStack {
                MyBooksScreen()
            }
            .tabItem {
                Image(systemName: "book.fill")
                Text("My Books")
            }

            NavigationStack {
                WishlistView()
            }
            .tabItem {
                Image(systemName: "heart.fill")
                Text("Wishlist")
            }

            NavigationStack {
                EventsScreen()
            }
            .tabItem {
                Image(systemName: "calendar")
                Text("Events")
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct HomeScreen: View {
    
    @State private var searchText = ""
    var body: some View {

        ScrollView {
          
            VStack(alignment: .leading, spacing: 12) {
                // Search Bar
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

                SectionHeader(title: "Books You May Like")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        NavigationLink(destination: UserBookDetailView(title: "The Silent Echo", author: "Sarah Mitchell")) {
                            UserBookCard(imageName: "book1", title: "The Silent Echo", author: "Sarah Mitchell", description: "A gripping tale of mystery and self-")
                        }

                        NavigationLink(destination: UserBookDetailView(title: "Book Title 2", author: "Author Name")) {
                            UserBookCard(imageName: "book2", title: "Book Title 2", author: "Author Name", description: "Short book description here")
                        }
                    }
                    .padding(.horizontal)
                }

                QuoteCard(text: "A reader lives a thousand lives before he dies.", author: "George R.R. Martin")
                    .padding(.horizontal)

                SectionHeader(title: "Trending Books")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        NavigationLink(destination: UserBookDetailView(title: "Ocean's Whisper", author: "Michael Chen")) {
                            UserBookCard(imageName: "book3", title: "Ocean's Whisper", author: "Michael Chen", description: "A poetic journey through the")
                        }

                        NavigationLink(destination: UserBookDetailView(title: "Book Title 4", author: "Author Name")) {
                            UserBookCard(imageName: "book4", title: "Book Title 4", author: "Author Name", description: "Short book description here")
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top)
        }
        .navigationTitle("HOME")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: {
                        // Handle notifications action
                    }) {
                        Image(systemName: "bell")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }

                    Button(action: {
                        // Handle profile action (Navigate to Profile Screen)
                    }) {
                        Image(systemName: "person.circle")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.headline)
            .padding(.horizontal)
    }
}

struct UserBookCard: View {
    let imageName: String
    let title: String
    let author: String
    let description: String

    @State private var isLiked = false // State to track heart status
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 160)
                    .cornerRadius(10)

                // Like Button
                Button(action: {
                    isLiked.toggle()
                }) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .gray)
                        .padding(8)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .offset(x: 8, y: -8)
            }
            .frame(maxWidth: .infinity, alignment: .topTrailing)

            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)

            Text(author)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(description)
                .font(.footnote)
                .foregroundColor(.gray)
                .lineLimit(2)

            Spacer()
        }
        .frame(width: 160, height: 230)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 5)
    }
}

struct MyBooksScreen: View {
    var body: some View {
        VStack {
            Text("My Books")
                .font(.largeTitle)
            
            NavigationLink(destination: UserBookDetailView(title: "Book 1", author: "Author 1")) {
                Text("Go to Book Detail")
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .navigationTitle("My Books")
    }
}

struct QuoteCard: View {
    let text: String
    let author: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("“")
                .font(.largeTitle)
                .foregroundColor(.blue)

            Text(text)
                .font(.body)
                .foregroundColor(.primary)

            Text("- \(author)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct WishlistScreen: View {
    var body: some View {
        VStack {
            Text("Wishlist")
                .font(.largeTitle)
        }
        .navigationTitle("Wishlist")
    }
}

struct EventsScreen: View {
    var body: some View {
        VStack {
            Text("Events")
                .font(.largeTitle)
        }
        .navigationTitle("Events")
    }
}

// Book Detail Screen
struct UserBookDetailView: View {
    let title: String
    let author: String

    var body: some View {
        VStack {
            Text(title)
                .font(.title)
                .fontWeight(.bold)

            Text("By \(author)")
                .font(.subheadline)
                .foregroundColor(.gray)

            Spacer()
        }
        .padding()
        .navigationTitle(title)
    }
}

// Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        UserHomeView()
    }
}
