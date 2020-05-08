//
//  DatabaseServices.swift
//  PhoneBook
//
//  Created by Vladimir Romashov on 07.05.2020.
//  Copyright © 2020 Vladimir Romashov. All rights reserved.
//

import Foundation
import CoreData

internal class DatabaseServices: LocalStorage {

    static var shared = DatabaseServices()

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentCloudKitContainer(name: "PhoneBook")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
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
        })
        return container
    }()

    func save() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func setupFetchedResultsController(delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<Contacts> {
        let fetchRequest: NSFetchRequest<Contacts> = Contacts.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "lastname", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.fetchBatchSize = 25
        let context = persistentContainer.viewContext
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = delegate
        try! fetchedResultsController.performFetch()
        return fetchedResultsController
    }
    
    func delete(object: Contacts) {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Contacts> = Contacts.fetchRequest()
        fetchRequest.returnsObjectsAsFaults = false
        do {
            let results = try context.fetch(fetchRequest)
            for item in results as [NSManagedObject] {
                if item == object {
                    context.delete(item)
                }
            }
        }
        catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        do {
            try context.save()
        } catch {
            print("Failed saving")
        }
    }

    func cleanup() {
        for tableName in ["Contacts"] {
            deleteAllData(tableName)
        }
    }
    
    func newContact() -> ContactObject {
        return Contacts(context: persistentContainer.viewContext)
    }

    
    func fetch(filter: FetchFilter) -> FetchResult {
        guard let filter = filter as? FetchFilterRequest, let request = filter.fetchRequest(), let result = try? persistentContainer.viewContext.fetch(request) else { return .empty }
        if let array = result as? [StorageObject] {
            if array.count > 1 {
                return .array(array)
            }
            else if let object = array.first {
                return .object(object)
            }
        }
        else if let array = result as? [[String: Any]] {
            return .report(array)
        }
        return .empty
    }

    private func deleteAllData(_ entity: String) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try persistentContainer.viewContext.execute(deleteRequest)
            try persistentContainer.viewContext.save()
        } catch let error {
            print("Detele all data in \(entity) error :", error)
        }
    }
}

extension Contacts: ContactObject {

}

fileprivate protocol FetchFilterRequest {
    func fetchRequest() -> NSFetchRequest<NSFetchRequestResult>?
}

extension ContactFetchFilter: FetchFilterRequest {
    func fetchRequest() -> NSFetchRequest<NSFetchRequestResult>? {
        switch self {
        case .all:
            return NSFetchRequest<NSFetchRequestResult>(entityName: "Contacts")
//        default:
//            return nil
        }
    }
}
