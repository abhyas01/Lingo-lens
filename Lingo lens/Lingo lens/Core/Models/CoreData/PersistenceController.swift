//
//  PersistenceController.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/9/25.
//

import Foundation
import CoreData

/// Manages Core Data stack and provides access to the persistent store
/// Handles database setup, saving, and error handling for the app
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
            print("Error setting up preview data: \(error.localizedDescription)")
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
        
        // For previews, use an in-memory store that disappears when the app closes
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Load the database
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                print("CoreData store failed to load: \(error), \(error.userInfo)")
                
                // Notify the app about database loading errors
                NotificationCenter.default.post(
                    name: NSNotification.Name("CoreDataStoreFailedToLoad"),
                    object: nil,
                    userInfo: ["error": error]
                )
            }
        }
        
        // Setup auto-merging of changes and conflict resolution
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Core Data Convenience Methods
    
    /// Saves any pending changes to the database
    /// Posts a notification if the save operation fails
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                print("💾 Saving Core Data context with changes")
                try context.save()
                print("✅ Core Data context saved successfully")
            } catch {
                let nserror = error as NSError
                print("❌ Failed to save Core Data context: \(nserror), \(nserror.userInfo)")
                
                // Notify the app about database save errors
                NotificationCenter.default.post(
                    name: NSNotification.Name("CoreDataSaveError"),
                    object: nil,
                    userInfo: ["error": nserror]
                )
            }
        } else {
            print("ℹ️ No Core Data changes to save")
        }
    }
}
