//
//  ConversationListenerView.swift
//  Lingo-lens
//
//  Created by Claude on 11/17/25.
//

import SwiftUI

/// Main view for real-time conversation translation
struct ConversationListenerView: View {

    @StateObject private var viewModel: ConversationViewModel
    @State private var showExportSheet = false
    @State private var exportText = ""

    init(translationService: TranslationService, speechManager: SpeechManager = SpeechManager.shared) {
        _viewModel = StateObject(wrappedValue: ConversationViewModel(
            translationService: translationService,
            speechManager: speechManager
        ))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Language selection header
                languageSelectionHeader
                    .padding()
                    .background(Color(.systemGray6))

                Divider()

                // Conversation messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                ConversationBubble(message: message)
                                    .id(message.id)
                                    .contextMenu {
                                        Button(action: {
                                            viewModel.playTranslation(for: message)
                                        }) {
                                            Label("Play Translation", systemImage: "speaker.wave.2")
                                        }

                                        Button(action: {
                                            copyToClipboard(message.translatedText)
                                        }) {
                                            Label("Copy Translation", systemImage: "doc.on.doc")
                                        }
                                    }
                            }

                            // Current transcript indicator
                            if !viewModel.currentTranscript.isEmpty {
                                currentTranscriptView
                                    .id("current")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        // Auto-scroll to latest message
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.currentTranscript) { _ in
                        // Auto-scroll to current transcript
                        if !viewModel.currentTranscript.isEmpty {
                            withAnimation {
                                proxy.scrollTo("current", anchor: .bottom)
                            }
                        }
                    }
                }

                // Empty state
                if viewModel.messages.isEmpty && !viewModel.isListening {
                    emptyStateView
                }

                Spacer()

                // Listening indicator
                if viewModel.isListening {
                    listeningIndicatorView
                }

                // Control buttons
                controlButtonsView
                    .padding()
                    .background(Color(.systemGray6))
            }
            .navigationTitle("Conversation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Toggle("Auto-play Translation", isOn: $viewModel.autoPlayTranslation)

                        Toggle("Auto-detect Speaker", isOn: $viewModel.autoDetectSpeaker)

                        Divider()

                        Button(action: {
                            exportText = viewModel.exportConversation()
                            showExportSheet = true
                        }) {
                            Label("Export Conversation", systemImage: "square.and.arrow.up")
                        }
                        .disabled(viewModel.messages.isEmpty)

                        Button(role: .destructive, action: {
                            viewModel.clearConversation()
                        }) {
                            Label("Clear Conversation", systemImage: "trash")
                        }
                        .disabled(viewModel.messages.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Permission Required", isPresented: $viewModel.showPermissionAlert) {
                Button("Settings", action: openSettings)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Microphone and speech recognition access are required for conversation translation. Please enable them in Settings.")
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .sheet(isPresented: $showExportSheet) {
                ShareSheet(items: [exportText])
            }
        }
        .task {
            await viewModel.requestPermissions()
        }
    }

    // MARK: - Subviews

    private var languageSelectionHeader: some View {
        VStack(spacing: 12) {
            HStack {
                // My language
                VStack(alignment: .leading, spacing: 4) {
                    Text("I speak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.myLanguage.displayName)
                        .font(.headline)
                }

                Spacer()

                Button(action: viewModel.swapLanguages) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.title3)
                }
                .disabled(viewModel.isListening)

                Spacer()

                // Their language
                VStack(alignment: .trailing, spacing: 4) {
                    Text("They speak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.theirLanguage.displayName)
                        .font(.headline)
                }
            }

            // Speaker toggle
            Picker("Current Speaker", selection: $viewModel.currentSpeaker) {
                Text("Me").tag(ConversationMessage.Speaker.me)
                Text("Them").tag(ConversationMessage.Speaker.them)
            }
            .pickerStyle(.segmented)
            .disabled(viewModel.isListening)
            .onChange(of: viewModel.currentSpeaker) { _ in
                if viewModel.isListening {
                    viewModel.toggleSpeaker()
                }
            }
        }
    }

    private var currentTranscriptView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Listening...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(viewModel.currentTranscript)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            .padding()
            .background(Color(.systemGray5).opacity(0.5))
            .cornerRadius(16)
            .frame(maxWidth: .infinity, alignment: viewModel.currentSpeaker == .me ? .trailing : .leading)

            if viewModel.currentSpeaker == .me {
                Spacer()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No conversation yet")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Tap the microphone to start listening")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var listeningIndicatorView: some View {
        HStack(spacing: 12) {
            ListeningIndicator(audioLevel: $viewModel.audioLevel)

            VStack(alignment: .leading, spacing: 2) {
                Text("Listening to \(viewModel.currentSpeaker.displayName)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Speak in \(viewModel.currentSpeaker == .me ? viewModel.myLanguage.displayName : viewModel.theirLanguage.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var controlButtonsView: some View {
        HStack(spacing: 16) {
            if viewModel.isListening {
                Button(action: viewModel.stopListening) {
                    Label("Stop", systemImage: "stop.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            } else {
                Button(action: viewModel.startListening) {
                    Label("Start Listening", systemImage: "mic.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(!viewModel.isAuthorized)
            }
        }
    }

    // MARK: - Helper Methods

    private func copyToClipboard(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #endif
    }

    private func openSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }
}

#Preview {
    ConversationListenerView(
        translationService: TranslationService(),
        speechManager: SpeechManager.shared
    )
}
