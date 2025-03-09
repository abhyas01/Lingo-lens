//
//  PersistenceController.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/9/25.
//

import Foundation
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        
        let viewContext = controller.container.viewContext
        
        // Sample Data
        let languages = [
            ("es-ES", "Spanish (es-ES)"),
            ("fr-FR", "French (fr-FR)"),
            ("de-DE", "German (de-DE)"),
            ("it-IT", "Italian (it-IT)"),
            ("ja-JP", "Japanese (ja-JP)")
        ]
        
        let words = [
            ("Hello", "Hola"),
            ("Goodbye", "Adiós"),
            ("Yes", "Sí"),
            ("No", "No"),
            ("Thank you", "Gracias")
        ]
        
        // Saving Sample Data
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
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        return controller
    }()
    
    let container: NSPersistentContainer
    
    private init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "lingo-lens-model")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate.
                // You should not use this function in a shipping application.
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        // Automatically merge changes from parent
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Keep track of changes and save automatically
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Core Data Convenience Methods
    
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
