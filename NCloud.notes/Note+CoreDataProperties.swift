//
//  Note+CoreDataProperties.swift
//  NCloud.notes
//
//  Created by Sergey Didanov on 20.02.17.
//  Copyright © 2017 Sergey Didanov. All rights reserved.
//

import Foundation
import CoreData


extension Note {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Note> {
        return NSFetchRequest<Note>(entityName: "Note");
    }

    @NSManaged public var content: String?
    @NSManaged public var favorite: Bool
    @NSManaged public var id: Int64
    @NSManaged public var modified: Int64
    @NSManaged public var security: Double
    @NSManaged public var title: String?

}
