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
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationSplitView {
            ZStack {
                SavedTranslationsView(
                    query: query,
                    sortOption: sortOption,
                    sortOrder: sortOrder,
                    languageFilter: selectedLanguageCode
                )
                .searchable(text: $query, prompt: "Search saved words")
            }
            .navigationTitle("Saved Words")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        // Language Filter Menu
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
                        
                        // Sort Menu
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
                }
            }
            .onAppear {
                loadAvailableLanguages()
            }
        } detail: {
            VStack {
                Image(systemName: "book.pages")
                    .font(.system(size: 70))
                    .foregroundColor(.blue.opacity(0.7))
                    .padding(.bottom, 10)
                
                Text("Select a saved word to view more details.")
                    .font(.title3.bold())
            }
        }
    }
    
    private func loadAvailableLanguages() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = SavedTranslation.fetchRequest() as! NSFetchRequest<NSFetchRequestResult>
        
        fetchRequest.propertiesToFetch = ["languageCode", "languageName"]
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.returnsDistinctResults = true
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "languageName", ascending: true)]
        
        do {
            let results = try viewContext.fetch(fetchRequest) as? [[String: Any]] ?? []
            
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
            availableLanguages = languages
        } catch {
            print("Error fetching languages: \(error.localizedDescription)")
        }
    }
}

#Preview {
    SavedWords()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
