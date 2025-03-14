//
//  SavedWords.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/10/25.
//

import SwiftUI
import CoreData

struct SavedWords: View {
    
    enum SortOption: String, CaseIterable, Identifiable {
        var id: String { self.rawValue }
        case dateCreated = "Date Added"
        case originalText = "Original Word"
        case translatedText = "Translated Word"
    }
    
    enum SortOrder: String, CaseIterable, Identifiable {
        var id: String { self.rawValue }
        case ascending = "Ascending"
        case descending = "Descending"
    }
    
    @State private var query: String = ""
    @State private var sortOption: SortOption = .dateCreated
    @State private var sortOrder: SortOrder = .descending
    @State private var selectedLanguageCode: String? = nil
    @State private var availableLanguages: [LanguageFilter] = []
    
    @State private var isLoadingLanguages: Bool = false
    @State private var showLanguageLoadError: Bool = false
    @State private var languageLoadErrorMessage: String = ""
    
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationSplitView {
            contentView
        } detail: {
            detailPlaceholderView
        }
        .alert("Error Loading Languages", isPresented: $showLanguageLoadError) {
            Button("OK", role: .cancel) { }
            Button("Try Again") {
                loadAvailableLanguages()
            }
        } message: {
            Text(languageLoadErrorMessage)
        }
    }
    
    // MARK: - Extracted Views
    
    private var contentView: some View {
        ZStack {
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
    
    private var toolbarButtons: some View {
        HStack {
            languageFilterButton
            sortButton
        }
    }
    
    private var languageFilterButton: some View {
        Menu {
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
    
    private var detailPlaceholderView: some View {
        VStack {
            Image(systemName: "book.pages")
                .font(.system(size: 70))
                .foregroundColor(.blue.opacity(0.7))
                .padding(.bottom, 10)
            
            Text("Select a saved word to view more details.")
                .font(.title3.bold())
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadAvailableLanguages() {
        isLoadingLanguages = true
        
        Task {
            do {
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = SavedTranslation.fetchRequest() as! NSFetchRequest<NSFetchRequestResult>
                
                fetchRequest.propertiesToFetch = ["languageCode", "languageName"]
                fetchRequest.resultType = .dictionaryResultType
                fetchRequest.returnsDistinctResults = true
                
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "languageName", ascending: true)]
                
                let results = try await viewContext.perform {
                    try fetchRequest.execute() as? [[String: Any]] ?? []
                }
                
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
                
                await MainActor.run {
                    availableLanguages = languages
                    isLoadingLanguages = false
                }
                
            } catch {
                await MainActor.run {
                    isLoadingLanguages = false
                    showLanguageLoadErrorAlert(message: "Unable to load language filters. Please try again.")
                }
            }
        }
    }
    
    private func showLanguageLoadErrorAlert(message: String) {
        languageLoadErrorMessage = message
        showLanguageLoadError = true
    }
}

#Preview {
    SavedWords()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
