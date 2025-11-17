//
//  LanguageSelectorView.swift
//  Lingo-lens
//
//  Created by Claude on 11/17/25.
//

import SwiftUI

/// Language picker with auto-detect option
struct LanguageSelectorView: View {

    @Binding var selectedLanguage: Locale.Language?
    @EnvironmentObject var translationService: TranslationService

    let allowAutoDetect: Bool
    let title: String

    @State private var showingPicker = false

    var body: some View {
        Button(action: { showingPicker = true }) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Text(displayText)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .sheet(isPresented: $showingPicker) {
            NavigationView {
                languagePickerContent
                    .navigationTitle("Select Language")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingPicker = false
                            }
                        }
                    }
            }
        }
    }

    private var displayText: String {
        if let language = selectedLanguage {
            return language.displayName
        } else if allowAutoDetect {
            return "Auto-detect"
        } else {
            return "Select language"
        }
    }

    private var languagePickerContent: some View {
        List {
            if allowAutoDetect {
                Button(action: {
                    selectedLanguage = nil
                    showingPicker = false
                }) {
                    HStack {
                        Text("Auto-detect")
                        Spacer()
                        if selectedLanguage == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }

            Section(header: Text("Available Languages")) {
                ForEach(translationService.availableLanguages, id: \.language.minimalIdentifier) { item in
                    Button(action: {
                        selectedLanguage = item.language
                        showingPicker = false
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.language.displayName)
                                if !item.isDownloaded {
                                    Text("Download required")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                            Spacer()
                            if selectedLanguage?.minimalIdentifier == item.language.minimalIdentifier {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
        }
    }
}

#Preview {
    LanguageSelectorView(
        selectedLanguage: .constant(.spanish),
        allowAutoDetect: true,
        title: "From"
    )
    .environmentObject(TranslationService())
}
