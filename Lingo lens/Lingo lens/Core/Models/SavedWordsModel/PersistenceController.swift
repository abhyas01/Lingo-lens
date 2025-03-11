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
            print("Error setting up preview data: \(error.localizedDescription)")
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
                print("CoreData store failed to load: \(error), \(error.userInfo)")
                
                NotificationCenter.default.post(
                    name: NSNotification.Name("CoreDataStoreFailedToLoad"),
                    object: nil,
                    userInfo: ["error": error]
                )
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Core Data Convenience Methods
    
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("CoreData failed to save context: \(nserror), \(nserror.userInfo)")
                NotificationCenter.default.post(
                    name: NSNotification.Name("CoreDataSaveError"),
                    object: nil,
                    userInfo: ["error": nserror]
                )
            }
        }
    }
}
