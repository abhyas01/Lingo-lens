//
//  SavedWords.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/10/25.
//

import SwiftUI

struct SavedWords: View {
    @State var query: String = ""
    
    var body: some View {
        NavigationSplitView {
            VStack {
                SavedTranslationsView(query: query)
            }
            .searchable(text: $query, prompt: "Search saved words")
            .navigationTitle("Saved Words")
        } detail: {
            VStack{
                Image(systemName: "book.pages")
                    .font(.system(size: 70))
                    .foregroundColor(.blue.opacity(0.7))
                    .padding(.bottom, 10)
                
                Text("Select a saved word to view more details.")
                    .font(.title3.bold())
            }
        }
    }
}

#Preview {
    SavedWords()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
