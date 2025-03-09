import SwiftUI

struct ContentView: View {
    @EnvironmentObject var translationService: TranslationService
    @StateObject private var arViewModel = ARViewModel()

    enum Tab {
        case arTranslationView
        case savedTranslationsView
    }
    
    @State private var selectedTab: Tab = .arTranslationView

    var body: some View {
        TabView(selection: $selectedTab) {
            ARTranslationView(arViewModel: arViewModel, isActiveTab: selectedTab == .arTranslationView)
                .environmentObject(translationService)
                .tabItem {
                    Label("Translate", systemImage: "camera.viewfinder")
                }
                .tag(Tab.arTranslationView)
            
            SavedTranslationsView()
                .tabItem {
                    Label("Saved Words", systemImage: "bookmark.fill")
                }
                .tag(Tab.savedTranslationsView)
        }
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    let translationService = TranslationService()
    translationService.availableLanguages = [
        AvailableLanguage(locale: Locale.Language(languageCode: "es", region: "ES")),
        AvailableLanguage(locale: Locale.Language(languageCode: "fr", region: "FR")),
        AvailableLanguage(locale: Locale.Language(languageCode: "de", region: "DE"))
    ]
    
    return ContentView()
        .environmentObject(translationService)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
