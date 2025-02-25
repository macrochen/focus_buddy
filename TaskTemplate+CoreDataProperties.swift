//
//  TaskTemplate+CoreDataProperties.swift
//  focus_buddy (iOS)
//
//  Created by  macrochen on 2025/2/24.
//
//

import Foundation
import CoreData


extension TaskTemplate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskTemplate> {
        return NSFetchRequest<TaskTemplate>(entityName: "TaskTemplate")
    }

    @NSManaged public var title: String?
    @NSManaged public var estimatedTime: Int32
    @NSManaged public var order: Int32
    @NSManaged public var createdAt: Date?

}

extension TaskTemplate : Identifiable {

}
