import SwiftUI
import FirebaseFirestore


// MARK: - Wishlist Manager (Separate File)
class WishlistManager: ObservableObject {
    @Published var wishlist: [String] = [] // Store book IDs
    private var db = Firestore.firestore()
    private let userId = "5" // Replace with actual user authentication
    
    init() {
        fetchWishlist()
    }
    
    func fetchWishlist() {
        db.collection("users").document(userId).collection("wishlist").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching wishlist: \(error)")
                return
            }
            self.wishlist = snapshot?.documents.compactMap { $0.documentID } ?? []
        }
    }
    
    func addToWishlist(bookId: String) {
        db.collection("users").document(userId).collection("wishlist").document(bookId).setData(["added": true]) { error in
            if let error = error {
                print("Error adding to wishlist: \(error)")
            } else {
                DispatchQueue.main.async {
                    self.wishlist.append(bookId)
                }
            }
        }
    }
    
    func removeFromWishlist(bookId: String) {
        db.collection("users").document(userId).collection("wishlist").document(bookId).delete { error in
            if let error = error {
                print("Error removing from wishlist: \(error)")
            } else {
                DispatchQueue.main.async {
                    self.wishlist.removeAll { $0 == bookId }
                }
            }
        }
    }
}
