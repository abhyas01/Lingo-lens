//
//  SavedTranslationsView.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/9/25.
//

import SwiftUI
import CoreData

struct SavedTranslationsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest var savedTranslations: FetchedResults<SavedTranslation>
    var onDeleteTranslation: (() -> Void)?

    init(query: String, sortOption: SavedWords.SortOption = .dateCreated, sortOrder: SavedWords.SortOrder = .descending, languageFilter: String? = nil, onDeleteTranslation: (() -> Void)? = nil) {
        // Start building the predicate
        var predicates: [NSPredicate] = []
        
        // Add search query predicate if it exists
        if !query.isEmpty {
            let searchPredicate = NSPredicate(
                format: "languageName CONTAINS[cd] %@ OR originalText CONTAINS[cd] %@ OR translatedText CONTAINS[cd] %@",
                query, query, query
            )
            predicates.append(searchPredicate)
        }
        
        // Add language filter predicate if it exists
        if let languageCode = languageFilter {
            let languagePredicate = NSPredicate(format: "languageCode == %@", languageCode)
            predicates.append(languagePredicate)
        }
        
        // Combine predicates if we have more than one
        let predicate: NSPredicate? = predicates.isEmpty ? nil :
            predicates.count == 1 ? predicates[0] : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        let isAscending = sortOrder == .ascending
        
        var sortDescriptors: [NSSortDescriptor] = []
        
        switch sortOption {
        case .dateCreated:
            sortDescriptors = [
                NSSortDescriptor(key: "dateAdded", ascending: isAscending)
            ]
        case .originalText:
            sortDescriptors = [
                NSSortDescriptor(key: "originalText", ascending: isAscending),
                NSSortDescriptor(key: "dateAdded", ascending: false)
            ]
        case .translatedText:
            sortDescriptors = [
                NSSortDescriptor(key: "translatedText", ascending: isAscending),
                NSSortDescriptor(key: "dateAdded", ascending: false)
            ]
        }
        
        _savedTranslations = FetchRequest<SavedTranslation>(
            sortDescriptors: sortDescriptors,
            predicate: predicate,
            animation: .default
        )
        
        self.onDeleteTranslation = onDeleteTranslation
    }
    
    var body: some View {
        Group {
            if !savedTranslations.isEmpty {
                savedWordsList
            } else {
                emptyStateView
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack{
            Spacer()
            
            VStack {
                Image(systemName: "book.closed")
                    .font(.system(size: 70))
                    .foregroundColor(.blue.opacity(0.7))
                    .padding(.bottom, 8)
                
                Text("No Saved Translations")
                    .font(.title2.bold())
                    .padding(.bottom, 8)
                
                Text("Your saved words will appear here.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private var savedWordsList: some View {
        List {
            Section {
                Text("Total: \(savedTranslations.count)")
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            ForEach(savedTranslations, id: \.id) { translation in
                NavigationLink {
                    SavedTranslationDetailView(translation: translation)
                } label: {
                    translationRow(translation)
                }
            }
            .onDelete(perform: deleteTranslations)
        }
        .listStyle(InsetGroupedListStyle())
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
    }
    
    private func translationRow(_ translation: SavedTranslation) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(translation.originalText ?? "")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(translation.translatedText ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(translation.languageCode?.toFlagEmoji() ?? "🌐")
                    .font(.title3)
                
                if let date = translation.dateAdded {
                    Text(date.toShortDateString())
                        .font(.caption2)
                        .foregroundStyle(.secondary.opacity(0.7))
                }
            }
            .padding(.trailing, 5)
        }
        .padding(.vertical, 4)
    }
    
    private func deleteTranslations(at offsets: IndexSet) {
        withAnimation {
            for offset in offsets {
                viewContext.delete(savedTranslations[offset])
            }
            do {
                try viewContext.save()
                onDeleteTranslation?()
            } catch {
                print("Error deleting translation: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    SavedTranslationsView(query: "")
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
