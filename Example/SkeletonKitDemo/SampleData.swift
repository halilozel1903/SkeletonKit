import SwiftUI
import UIKit

struct Profile {
    let name: String
    let handle: String
    let role: String
    let bio: String
    let initials: String
    let posts: String
    let followers: String
    let following: String

    static let sample = Profile(
        name: "Maya Chen",
        handle: "@mayachen",
        role: "Product designer",
        bio: "Designing calm interfaces in Lisbon. Coffee, film cameras and long walks by the river.",
        initials: "MC",
        posts: "248",
        followers: "12.4K",
        following: "312"
    )
}

struct Post: Identifiable {
    let id: Int
    let author: String
    let initials: String
    let avatarColors: [Color]
    let time: String
    let text: String
    let photo: Photo?
    let likes: String
    let comments: String

    struct Photo {
        let symbol: String
        let caption: String
        let colors: [Color]
    }

    static let samples: [Post] = [
        Post(
            id: 1,
            author: "Maya Chen",
            initials: "MC",
            avatarColors: [.orange, .pink],
            time: "2h",
            text: "Golden hour at Miradouro da Graça. The whole city turns pink for about four minutes.",
            photo: Photo(symbol: "sun.horizon.fill", caption: "Lisbon, Portugal", colors: [.orange, .pink, .purple]),
            likes: "1,284",
            comments: "86"
        ),
        Post(
            id: 2,
            author: "Maya Chen",
            initials: "MC",
            avatarColors: [.orange, .pink],
            time: "Yesterday",
            text: "Shipped the new onboarding today. Fewer screens, clearer choices, and a skeleton state that finally feels fast.",
            photo: nil,
            likes: "642",
            comments: "41"
        ),
        Post(
            id: 3,
            author: "Maya Chen",
            initials: "MC",
            avatarColors: [.orange, .pink],
            time: "3d",
            text: "Weekend hike along the coast from Cascais to Guincho.",
            photo: Photo(symbol: "mountain.2.fill", caption: "Sintra-Cascais Natural Park", colors: [.teal, .blue, .indigo]),
            likes: "978",
            comments: "53"
        ),
    ]
}

@MainActor
extension Color {
    static var screenBackground: Color { Color(uiColor: .systemGroupedBackground) }
    static var cardBackground: Color { Color(uiColor: .secondarySystemGroupedBackground) }
}
