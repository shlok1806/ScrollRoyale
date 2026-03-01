import SwiftUI
import Combine
import Foundation

// MARK: - Brain Customization

struct BrainCustomization {
    var hat: String = "crown"
    var glasses: String = "sunglasses"
    var expression: String = "happy"
    var skin: String = "classic"
    var effect: String = "purple-aura"
    var accessory: String = "spoon"
}

// MARK: - App State (UI / customization only)

@MainActor
final class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var customization = BrainCustomization()

    init() {}

    func updateCustomization(_ newValue: BrainCustomization) {
        customization = newValue
    }
}
