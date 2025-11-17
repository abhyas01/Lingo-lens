//
//  PersistenceController.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/9/25.
//  Refactored by Claude Code Review on 11/17/25.
//

import Foundation
import CoreData

/// Manages Core Data stack and provides access to the persistent store
/// Handles database setup, saving, migration, and error handling for the app
struct PersistenceController {

    // Shared instance for app-wide access to database
    static let shared = PersistenceController()
    
    // Special instance loaded with sample data for SwiftUI previews
    static var preview: PersistenceController = {
        
        // Create an in-memory controller for previews
        let controller = PersistenceController(inMemory: true)
        
        let viewContext = controller.container.viewContext
        
        // Add sample data for different languages
        let languages = [
            ("es-ES", "Spanish (es-ES)"),
            ("fr-FR", "French (fr-FR)"),
            ("de-DE", "German (de-DE)"),
            ("it-IT", "Italian (it-IT)"),
            ("ja-JP", "Japanese (ja-JP)")
        ]
        
        // Add sample translation words
        let words = [
            ("Hello", "Hola"),
            ("Goodbye", "Adiós"),
            ("Yes", "Sí"),
            ("No", "No"),
            ("Thank you", "Gracias")
        ]
        
        // Create sample translation entries
        for i in 0..<5 {
            let newItem = SavedTranslation(context: viewContext)
            let (langCode, langName) = languages[i]
            let (originalText, translatedText) = words[i]
            
            newItem.id = UUID()
            newItem.languageCode = langCode
            newItem.languageName = langName
            newItem.originalText = originalText
            newItem.translatedText = translatedText
            newItem.dateAdded = Date().addingTimeInterval(-Double(i * 86400))
        }
        
        // Save the preview data
        do {
            try viewContext.save()
        } catch {
            Logger.error("Error setting up preview data: \(error.localizedDescription)")
        }

        return controller
    }()
    
    // Core Data container that holds the model, context, and stores
    let container: NSPersistentContainer
    
    // MARK: - Initialization

    /// Creates the Core Data stack, either in memory or persistent
    /// - Parameter inMemory: If true, creates a temporary in-memory database
    private init(inMemory: Bool = false) {

        // Create the container with our model name
        container = NSPersistentContainer(name: "lingo-lens-model")

        // Directory path
        let storeDirectory = NSPersistentContainer.defaultDirectoryURL()
        Logger.debug("Core Data store directory: \(storeDirectory.path)")

        // Configure store description with migration options
        if let storeDescription = container.persistentStoreDescriptions.first {
            if inMemory {
                // For previews, use an in-memory store
                storeDescription.url = URL(fileURLWithPath: "/dev/null")
                Logger.debug("Using in-memory Core Data store")
            } else {
                Logger.debug("Core Data store file: \(storeDescription.url?.path ?? "unknown")")

                // Enable automatic lightweight migration
                storeDescription.shouldMigrateStoreAutomatically = true
                storeDescription.shouldInferMappingModelAutomatically = true

                Logger.info("Enabled automatic Core Data migration")
            }
        }

        // Load the database
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                Logger.error("CoreData store failed to load: \(error), \(error.userInfo)")

                // Attempt recovery by deleting and recreating store
                if let storeURL = description.url, !inMemory {
                    Logger.warning("Attempting to recover by deleting corrupted store")
                    self.attemptStoreRecovery(at: storeURL)
                }

                // Notify the app about database loading errors
                NotificationCenter.default.post(
                    name: NSNotification.Name("CoreDataStoreFailedToLoad"),
                    object: nil,
                    userInfo: ["error": error]
                )
            } else {
                Logger.info("Successfully loaded Core Data store")
            }
        }

        // Setup auto-merging of changes and conflict resolution
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        Logger.debug("Core Data viewContext configured with merge policy")
    }

    /// Attempts to recover from a corrupted Core Data store
    /// WARNING: This will delete all existing data
    /// - Parameter storeURL: URL of the corrupted store
    private func attemptStoreRecovery(at storeURL: URL) {
        do {
            // Try to remove the corrupted store
            try FileManager.default.removeItem(at: storeURL)
            Logger.warning("Deleted corrupted Core Data store - user data was lost")

            // Also remove associated files
            let storeURLWithoutExtension = storeURL.deletingPathExtension()
            let shmURL = storeURLWithoutExtension.appendingPathExtension("sqlite-shm")
            let walURL = storeURLWithoutExtension.appendingPathExtension("sqlite-wal")

            try? FileManager.default.removeItem(at: shmURL)
            try? FileManager.default.removeItem(at: walURL)

            // Retry loading the store
            container.loadPersistentStores { description, error in
                if error == nil {
                    Logger.info("Successfully recovered Core Data store")
                } else {
                    Logger.error("Failed to recover Core Data store")
                }
            }
        } catch {
            Logger.error("Failed to delete corrupted store: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Core Data Convenience Methods
    
    /// Saves any pending changes to the database
    /// Posts a notification if the save operation fails
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                Logger.debug("Saving Core Data context with changes")
                try context.save()
                Logger.debug("Core Data context saved successfully")
            } catch {
                let nserror = error as NSError
                Logger.error("Failed to save Core Data context: \(nserror), \(nserror.userInfo)")

                // Notify the app about database save errors
                NotificationCenter.default.post(
                    name: NSNotification.Name("CoreDataSaveError"),
                    object: nil,
                    userInfo: ["error": nserror]
                )
            }
        } else {
            Logger.debug("No Core Data changes to save")
        }
    }
}
