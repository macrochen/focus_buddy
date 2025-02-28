//
//  FocusTask+CoreDataProperties.swift
//  focus_buddy (iOS)
//
//  Created by jolin on 2025/2/28.
//
//

import Foundation
import CoreData


extension FocusTask {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FocusTask> {
        return NSFetchRequest<FocusTask>(entityName: "FocusTask")
    }

    @NSManaged public var actualTime: Int32
    @NSManaged public var category: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var date: Date?
    @NSManaged public var deadline: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var estimatedTime: Int32
    @NSManaged public var id: UUID?
    @NSManaged public var startTime: Date?
    @NSManaged public var status: String?
    @NSManaged public var taskDescription: String?
    @NSManaged public var title: String?
    @NSManaged public var plannedDate: Date?
    @NSManaged public var order: Int16
    @NSManaged public var focusSessions: NSSet?
    @NSManaged public var interruptions: Interruption?

}

// MARK: Generated accessors for focusSessions
extension FocusTask {

    @objc(addFocusSessionsObject:)
    @NSManaged public func addToFocusSessions(_ value: FocusSession)

    @objc(removeFocusSessionsObject:)
    @NSManaged public func removeFromFocusSessions(_ value: FocusSession)

    @objc(addFocusSessions:)
    @NSManaged public func addToFocusSessions(_ values: NSSet)

    @objc(removeFocusSessions:)
    @NSManaged public func removeFromFocusSessions(_ values: NSSet)

}

extension FocusTask : Identifiable {

}
