//
//  LanguageSelectionView.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/21/25.
//


import SwiftUI

struct LanguageSelectionView: View {
    @Binding var selectedLanguage: Language
    @Binding var isPresented: Bool
    @State private var tempSelectedLanguage: Language
    
    init(selectedLanguage: Binding<Language>, isPresented: Binding<Bool>) {
        self._selectedLanguage = selectedLanguage
        self._isPresented = isPresented
        self._tempSelectedLanguage = State(initialValue: selectedLanguage.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            List(Language.supportedLanguages) { language in
                HStack {
                    Text(language.name)
                    Spacer()
                    if language.code == tempSelectedLanguage.code {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    tempSelectedLanguage = language
                }
            }
            .navigationTitle("Select Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        selectedLanguage = tempSelectedLanguage
                        isPresented = false
                    }
                }
            }
        }
    }
}
