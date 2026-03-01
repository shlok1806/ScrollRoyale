import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isLoggedIn = false
    @State private var showLoading = false

    var body: some View {
        Group {
            if isLoggedIn {
                MainTabView()
            } else if showLoading {
                LoadingView(onComplete: {
                    withAnimation { isLoggedIn = true }
                })
            } else {
                LoginView(onLogin: {
                    showLoading = true
                })
            }
        }
        .animation(.easeInOut, value: isLoggedIn)
        .animation(.easeInOut, value: showLoading)
    }
}
