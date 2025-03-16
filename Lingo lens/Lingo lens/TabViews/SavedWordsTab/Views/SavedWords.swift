//
//  SavedWords.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/10/25.
//

import SwiftUI
import CoreData

/// Main container view for the "Saved Words" tab
/// Handles filtering, sorting and displaying the user's saved translations
struct SavedWords: View {
    
    /// Sort options for the saved translations list
    enum SortOption: String, CaseIterable, Identifiable {
        var id: String { self.rawValue }
        case dateCreated = "Date Added"
        case originalText = "Original Word"
        case translatedText = "Translated Word"
    }
    
    /// Sort direction options (ascending or descending)
    enum SortOrder: String, CaseIterable, Identifiable {
        var id: String { self.rawValue }
        case ascending = "Ascending"
        case descending = "Descending"
    }
    
    // MARK: - State Properties

    // Search text entered by the user
    @State private var query: String = ""
    
    // Current sort settings
    @State private var sortOption: SortOption = .dateCreated
    @State private var sortOrder: SortOrder = .descending
    
    // Currently selected language filter
    @State private var selectedLanguageCode: String? = nil
    
    // List of available languages for filtering
    @State private var availableLanguages: [LanguageFilter] = []
    
    // Loading and error states
    @State private var isLoadingLanguages: Bool = false
    @State private var showLanguageLoadError: Bool = false
    @State private var languageLoadErrorMessage: String = ""
    
    // Core Data context for database operations
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        
        // Split view with list on left, details on right for larger screens
        NavigationStack {
            contentView
        }
        .navigationViewStyle(StackNavigationViewStyle())
        
        // Error alert for language filter loading failures
        .alert("Error Loading Languages", isPresented: $showLanguageLoadError) {
            Button("OK", role: .cancel) { }
            Button("Try Again") {
                loadAvailableLanguages()
            }
        } message: {
            Text(languageLoadErrorMessage)
        }
    }
    
    // MARK: - View Components
    
    /// Main content view with search, filters and translations list
    private var contentView: some View {
        ZStack {
            
            // The main translations list with filters applied
            SavedTranslationsView(
                query: query,
                sortOption: sortOption,
                sortOrder: sortOrder,
                languageFilter: selectedLanguageCode,
                updateFilterList: {
                    loadAvailableLanguages()
                }
            )
            .searchable(text: $query, prompt: "Search saved words")
            
            // Overlay loading indicator while fetching language filters
            if isLoadingLanguages {
                ProgressView("Loading...")
                    .padding()
                    .background(Color(.systemBackground).opacity(0.7))
                    .cornerRadius(10)
            }
        }
        .navigationTitle("Saved Words")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                toolbarButtons
            }
        }
        .onAppear {
            loadAvailableLanguages()
        }
    }
    
    /// Toolbar buttons for filtering and sorting
    private var toolbarButtons: some View {
        HStack {
            languageFilterButton
            sortButton
        }
    }
    
    /// Button and menu for filtering by language
    /// Shows the available languages with their flags
    private var languageFilterButton: some View {
        Menu {
            
            // Option to show all languages
            Button {
                selectedLanguageCode = nil
            } label: {
                HStack {
                    Text("All Languages")
                    if selectedLanguageCode == nil {
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            // List all available languages if any exist
            if !availableLanguages.isEmpty {
                Divider()
                
                ForEach(availableLanguages) { language in
                    Button {
                        selectedLanguageCode = language.languageCode
                    } label: {
                        HStack {
                            Text("\(language.flag) \(language.languageName)")
                            if selectedLanguageCode == language.languageCode {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        } label: {
            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                .foregroundColor(.blue)
        }
        .disabled(isLoadingLanguages)
    }
    
    /// Button and menu for sorting the translations
    /// Options for sorting by date, original text, or translated text
    private var sortButton: some View {
        Menu {
            Section("Sort By") {
                ForEach(SortOption.allCases) { option in
                    Button {
                        sortOption = option
                    } label: {
                        HStack {
                            Text(option.rawValue)
                            if sortOption == option {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            
            Section("Order") {
                ForEach(SortOrder.allCases) { order in
                    Button {
                        sortOrder = order
                    } label: {
                        HStack {
                            Text(order.rawValue)
                            if sortOrder == order {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
                .foregroundColor(.blue)
        }
    }
    
    // MARK: - Helper Functions
    
    /// Loads all unique languages used in saved translations
    /// Populates the language filter dropdown menu
    private func loadAvailableLanguages() {
        print("🔍 Loading available languages for filter")
        isLoadingLanguages = true
        
        Task {
            do {
                
                print("📊 Creating fetch request (unique languages) for filter")
                // Create a fetch request that only gets language info
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = SavedTranslation.fetchRequest() as! NSFetchRequest<NSFetchRequestResult>
                
                // Only fetch the language fields we need
                fetchRequest.propertiesToFetch = ["languageCode", "languageName"]
                fetchRequest.resultType = .dictionaryResultType
                fetchRequest.returnsDistinctResults = true
                
                // Sort alphabetically by language name
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "languageName", ascending: true)]
                
                // Execute the fetch request on the view context
                let results = try await viewContext.perform {
                    try fetchRequest.execute() as? [[String: Any]] ?? []
                }
                
                print("✅ Found \(results.count) unique languages")

                // Convert results to language filter objects
                var languages = [LanguageFilter]()
                
                for result in results {
                    if let code = result["languageCode"] as? String,
                       let name = result["languageName"] as? String {
                        let filter = LanguageFilter(
                            languageCode: code,
                            languageName: name
                        )
                        languages.append(filter)
                    }
                }
                
                // Update UI on main thread
                await MainActor.run {
                    availableLanguages = languages
                    print("✅ Updated language filter with \(languages.count) languages")
                    isLoadingLanguages = false
                }
                
            } catch {
                print("❌ Failed to load language filters: \(error.localizedDescription)")

                // Handle any errors during loading
                await MainActor.run {
                    isLoadingLanguages = false
                    showLanguageLoadErrorAlert(message: "Unable to load language filters. Please try again.")
                }
            }
        }
    }
    
    /// Shows error alert with custom message when loading languages fails
    private func showLanguageLoadErrorAlert(message: String) {
        languageLoadErrorMessage = message
        showLanguageLoadError = true
    }
}

#Preview {
    SavedWords()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
