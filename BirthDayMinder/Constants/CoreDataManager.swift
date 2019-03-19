//
//  CoreDataManager.swift
//  BirthDayMinder
//
//  Created by Holland Clarke on 3/18/19.
//  Copyright © 2019 Holland Clarke. All rights reserved.
//

import UIKit
import CoreData

class CoreDataManager {
    
    // Add new person to the database
    internal func addPersonToDatabase(person: Person) {
        guard let application = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = application.persistentContainer.viewContext
        guard let entity = NSEntityDescription.entity(forEntityName: "PersonData", in: context) else { return }
        let newData = NSManagedObject(entity: entity, insertInto: context)
        
        newData.setValue(person.birthday, forKey: CoreDataKeys.birthday)
        newData.setValue(person.name, forKey: CoreDataKeys.name)
        // TODO: set value for image data
        
    }
    
    // Delete the person from the database
    internal func deleteData(at index: Int) {
        
        guard let application = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = application.persistentContainer.viewContext
        let request = NSFetchRequest<PersonData>(entityName: "PersonData")
        do {
            let results = try context.fetch(request)
            if results.indices.contains(index) {
                let item = results[index]
                context.delete(item)
                application.saveContext()
            }
        } catch let error as NSError {
            print("Error, ", error.debugDescription)
        }
    }
    
    // Modifying user data
    
    internal func overwriteData(at index: Int, with data: Person) {
        guard let application = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = application.persistentContainer.viewContext
        let request = NSFetchRequest<PersonData>(entityName: "PersonData")
        do {
            let results = try context.fetch(request)
            if results.indices.contains(index) {
                let item = results[index]
                item.birthday = data.birthday
//                item.image = data.image?.data(using: .)
                item.name = data.name
                
                application.saveContext()
            }
        } catch let error as NSError {
            print("Error ", error.debugDescription)
        }
    }

}

