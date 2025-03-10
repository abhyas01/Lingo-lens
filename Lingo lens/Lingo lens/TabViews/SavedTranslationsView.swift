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
    
    init(query: String) {
        let predicate: NSPredicate? = query.isEmpty ? nil : NSPredicate(
            format: "languageName CONTAINS[cd] %@ OR originalText CONTAINS[cd] %@ OR translatedText CONTAINS[cd] %@",
            query, query, query
        )
        
        _savedTranslations = FetchRequest<SavedTranslation>(sortDescriptors: [
            NSSortDescriptor(key: "dateAdded", ascending: false)
        ], predicate: predicate, animation: .default)
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
                Text(flagEmoji(for: translation.languageCode ?? ""))
                    .font(.title3)
                
                if let date = translation.dateAdded {
                    Text(formatDate(date))
                        .font(.caption2)
                        .foregroundStyle(.secondary.opacity(0.7))
                }
            }
            .padding(.trailing, 5)
        }
        .padding(.vertical, 4)
    }
    
    private func flagEmoji(for languageCode: String) -> String {
        guard let regionCode = languageCode.split(separator: "-").last else {
            return "🌐"
        }
        
        let base: UInt32 = 127397
        var emoji = ""
        
        for scalar in regionCode.uppercased().unicodeScalars {
            if let flagScalar = UnicodeScalar(base + scalar.value) {
                emoji.append(Character(flagScalar))
            }
        }
        
        return emoji.isEmpty ? "🌐" : emoji
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func deleteTranslations(at offsets: IndexSet) {
        withAnimation {
            offsets.map { savedTranslations[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
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
