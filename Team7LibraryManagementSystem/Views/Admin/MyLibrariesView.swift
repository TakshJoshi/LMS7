import SwiftUI
import FirebaseFirestore

struct MyLibrariesView: View {
    @State private var libraries: [Library] = []
    @State private var isAddLibraryPresented = false
    @State private var searchText = ""
    
    var filteredLibraries: [Library] {
        guard !searchText.isEmpty else { return libraries }

        return libraries.filter { library in
            let nameMatch = library.name.localizedCaseInsensitiveContains(searchText)
            let cityMatch = library.address.city.localizedCaseInsensitiveContains(searchText)
            let stateMatch = library.address.state.localizedCaseInsensitiveContains(searchText)

            return nameMatch || cityMatch || stateMatch
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                SearchBar2(searchText: $searchText)
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(filteredLibraries) { library in
                            NavigationLink(destination: EachLibraryView(library: library)) {
                                LibraryCard3(library: library)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Libraries")
            .toolbar {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .onTapGesture {
                        isAddLibraryPresented = true
                    }
            }
            .sheet(isPresented: $isAddLibraryPresented) {
                NavigationStack {
                    AddLibrariesForm()
                }
            }
            .background(Color(.systemGroupedBackground))
            .onAppear { fetchLibraries() }
        }
    }
    
    private func fetchLibraries() {
        let db = Firestore.firestore()
        db.collection("libraries").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching libraries: \(error.localizedDescription)")
                return
            }
            guard let documents = snapshot?.documents else { return }
            
            self.libraries = documents.compactMap { doc in
                try? doc.data(as: Library.self)
            }
        }
    }
}




struct LibraryCard3: View {
    let library: Library

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "building.columns.fill")
                .resizable()
                .scaledToFit()
                .frame(height: 80)
                .foregroundColor(.blue)
                .padding(.bottom, 8)
            
            Text(library.name)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: "mappin.and.ellipse")
                Text("\(library.address.city), \(library.address.state)")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "clock")
                Text("\(library.operationalHours.weekday.opening) - \(library.operationalHours.weekday.closing)")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 3)
    }
}


struct SearchBar2: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.gray)
                TextField("Search libraries...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background(Color(.systemGray5))
            .cornerRadius(8)
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
}
// MARK: - Preview
struct MyLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MyLibrariesView()
        }
    }
}
