//
//  Interruption+CoreDataProperties.swift
//  focus_buddy (iOS)
//
//  Created by  macrochen on 2025/2/24.
//
//

import Foundation
import CoreData


extension Interruption {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Interruption> {
        return NSFetchRequest<Interruption>(entityName: "Interruption")
    }

    @NSManaged public var duration: Int32
    @NSManaged public var reason: String?
    @NSManaged public var startTime: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var endTime: Date?
    @NSManaged public var note: String?
    @NSManaged public var session: FocusSession?
    @NSManaged public var task: FocusTask?

}

extension Interruption : Identifiable {

}
