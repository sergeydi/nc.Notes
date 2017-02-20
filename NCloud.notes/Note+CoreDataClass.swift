//
//  Note+CoreDataClass.swift
//  NCloud.notes
//
//  Created by Sergey Didanov on 20.02.17.
//  Copyright © 2017 Sergey Didanov. All rights reserved.
//

import Foundation
import CoreData

@objc(Note)
public class Note: NSManagedObject {
    convenience init() {
        self.init(entity: CoreDataManager.instance.entityForName(entityName: "Note"), insertInto: CoreDataManager.instance.managedObjectContext)
    }

}
