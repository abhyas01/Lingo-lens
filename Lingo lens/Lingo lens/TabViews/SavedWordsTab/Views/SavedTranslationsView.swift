//
//  SavedTranslationsView.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/9/25.
//

import SwiftUI
import CoreData

/// View that displays the list of saved translations
/// Supports filtering, sorting, and deletion of translations
struct SavedTranslationsView: View {
    
    // Core Data context for database operations
    @Environment(\.managedObjectContext) private var viewContext
    
    // Dynamic fetch request with filters applied
    @FetchRequest var savedTranslations: FetchedResults<SavedTranslation>
    
    // Callback to refresh language filter list in parent view
    var updateFilterList: (() -> Void)?
    
    // MARK: - State Properties

    // Loading state for deletion process
    @State private var isDeleting = false
    
    // Loading state for deletion process
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""

    /// Initializes the view with search and filter options
    /// Sets up the Core Data fetch request with appropriate predicates and sort descriptors
    init(query: String, sortOption: SavedWords.SortOption = .dateCreated, sortOrder: SavedWords.SortOrder = .descending, languageFilter: String? = nil, updateFilterList: (() -> Void)? = nil) {
        
        // Start building the predicate
        var predicates: [NSPredicate] = []
        
        // Add search query predicate if it exists
        // Searches across language name, original text, and translated text
        if !query.isEmpty {
            let searchPredicate = NSPredicate(
                format: "languageName CONTAINS[cd] %@ OR originalText CONTAINS[cd] %@ OR translatedText CONTAINS[cd] %@",
                query, query, query
            )
            predicates.append(searchPredicate)
        }
        
        // Add language filter predicate if a specific language is selected
        if let languageCode = languageFilter {
            let languagePredicate = NSPredicate(format: "languageCode == %@", languageCode)
            predicates.append(languagePredicate)
        }
        
        // Combine predicates if we have more than one
        let predicate: NSPredicate? = predicates.isEmpty ? nil :
            predicates.count == 1 ? predicates[0] : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        // Determine sort direction based on the sort order
        let isAscending = sortOrder == .ascending
        
        // Configure sort descriptors based on the selected sort option
        var sortDescriptors: [NSSortDescriptor] = []
        
        switch sortOption {
            
        // Sort by date, newest/oldest first depending on sort order
        case .dateCreated:
            sortDescriptors = [
                NSSortDescriptor(key: "dateAdded", ascending: isAscending)
            ]
            
        // Sort alphabetically by original text with date as secondary sort
        case .originalText:
            sortDescriptors = [
                NSSortDescriptor(key: "originalText", ascending: isAscending),
                NSSortDescriptor(key: "dateAdded", ascending: false)
            ]
            
        // Sort alphabetically by translated text with date as secondary sort
        case .translatedText:
            sortDescriptors = [
                NSSortDescriptor(key: "translatedText", ascending: isAscending),
                NSSortDescriptor(key: "dateAdded", ascending: false)
            ]
        }
        
        // Create the fetch request with the configured predicates and sort descriptors
        _savedTranslations = FetchRequest<SavedTranslation>(
            sortDescriptors: sortDescriptors,
            predicate: predicate,
            animation: .default
        )
        
        self.updateFilterList = updateFilterList
    }
    
    var body: some View {
        Group {
            if !savedTranslations.isEmpty {
                savedWordsList
            } else {
                emptyStateView
            }
        }
        
        // Listen for Core Data changes to refresh the language filter
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange)) { _ in
            updateFilterList?()
        }
        
        // Error alert for deletion failures
        .alert("Delete Error", isPresented: $showDeleteError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(deleteErrorMessage)
        }
    }
    
    // MARK: - View Components

    /// Empty state view shown when no translations are available
    /// Displays a friendly message and icon
    private var emptyStateView: some View {
        VStack{
            Spacer()
            
            VStack {
                
                // Book icon to represent empty collection
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
    
    /// Main list view showing all saved translations
    /// Includes count, edit button, and swipe-to-delete functionality
    private var savedWordsList: some View {
        List {
            
            // Shows total count of translations at the top
            Section {
                Text("Total: \(savedTranslations.count)")
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            // List of all translations with navigation links
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
        
        // Overlay loading indicator during deletion
        .overlay(
            isDeleting ?
                ProgressView("Deleting...")
                    .padding()
                    .background(Color(.systemBackground).opacity(0.7))
                    .cornerRadius(10)
                : nil
        )
        .disabled(isDeleting)
    }
    
    /// Creates a row for a single translation item
    /// Shows original text, translation, language flag, and date
    private func translationRow(_ translation: SavedTranslation) -> some View {
        HStack(spacing: 12) {
            
            // Left side: Translation text content
            VStack(alignment: .leading, spacing: 4) {
                Text(translation.originalText ?? "")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(translation.translatedText ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Right side: Flag and date
            VStack(alignment: .trailing, spacing: 4) {
                
                // Show language flag emoji
                Text(translation.languageCode?.toFlagEmoji() ?? "🌐")
                    .font(.title3)
                
                // Show date added in short format
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
    
    // MARK: - Helper Methods

    /// Handles swipe-to-delete functionality
    /// Removes translations from Core Data and handles error states
    private func deleteTranslations(at offsets: IndexSet) {
        isDeleting = true
        
        Task {
            do {
                
                // Delete on main thread since it affects UI
                await MainActor.run {
                    for offset in offsets {
                        viewContext.delete(savedTranslations[offset])
                    }
                }
                
                // Save context to persist the deletion
                try viewContext.save()
                
                await MainActor.run {
                    isDeleting = false
                }
            } catch {
                
                // Show error if deletion fails
                await MainActor.run {
                    isDeleting = false
                    showDeleteErrorAlert(message: "Unable to delete translation(s). Please try again later.")
                }
            }
        }
    }
    
    /// Shows error alert with custom message
    /// Used when deletion or other operations fail
    private func showDeleteErrorAlert(message: String) {
        deleteErrorMessage = message
        showDeleteError = true
    }
}

#Preview {
    SavedTranslationsView(query: "")
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
