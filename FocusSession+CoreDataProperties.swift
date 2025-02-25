//
//  FocusSession+CoreDataProperties.swift
//  focus_buddy (iOS)
//
//  Created by  macrochen on 2025/2/24.
//
//

import Foundation
import CoreData


extension FocusSession {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FocusSession> {
        return NSFetchRequest<FocusSession>(entityName: "FocusSession")
    }

    @NSManaged public var actualDuration: Int32
    @NSManaged public var endTime: Date?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var musicTrack: String?
    @NSManaged public var plannedDuration: Int32
    @NSManaged public var startTime: Date?
    @NSManaged public var usedMusic: Bool
    @NSManaged public var interruptions: NSSet?
    @NSManaged public var task: FocusTask?

}

// MARK: Generated accessors for interruptions
extension FocusSession {

    @objc(addInterruptionsObject:)
    @NSManaged public func addToInterruptions(_ value: Interruption)

    @objc(removeInterruptionsObject:)
    @NSManaged public func removeFromInterruptions(_ value: Interruption)

    @objc(addInterruptions:)
    @NSManaged public func addToInterruptions(_ values: NSSet)

    @objc(removeInterruptions:)
    @NSManaged public func removeFromInterruptions(_ values: NSSet)

}

extension FocusSession : Identifiable {

}
