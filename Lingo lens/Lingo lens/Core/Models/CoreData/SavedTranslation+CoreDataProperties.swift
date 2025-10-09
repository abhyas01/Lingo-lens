//
//  SavedTranslation+CoreDataProperties.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/9/25.
//
//

import Foundation
import CoreData


extension SavedTranslation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SavedTranslation> {
        return NSFetchRequest<SavedTranslation>(entityName: "SavedTranslation")
    }

    @NSManaged public var dateAdded: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var languageCode: String?
    @NSManaged public var languageName: String?
    @NSManaged public var originalText: String?
    @NSManaged public var translatedText: String?

}

extension SavedTranslation : Identifiable {

}
