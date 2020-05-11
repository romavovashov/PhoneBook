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

        let container = NSPersistentCloudKitContainer(name: "PhoneBook")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    lazy var writeContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()

        NotificationCenter.default.addObserver(self, selector: #selector(self.mergeChangesIntoReadContext(notification:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)

        return context
    }()
    
    @objc private func mergeChangesIntoReadContext(notification: Notification) {
        let context = notification.object as? NSManagedObjectContext
        if context !== writeContext {
            writeContext.perform { [writeContext] in
                writeContext.mergeChanges(fromContextDidSave: notification)
            }
        }
    }

    func save(onBackground: Bool) {
        let context = onBackground ? writeContext : persistentContainer.viewContext
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
        let context = persistentContainer.viewContext
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: context,
                                                                  sectionNameKeyPath: "lastNameFirstLetter",
                                                                  cacheName: nil)
        fetchedResultsController.delegate = delegate
                do {
            try fetchedResultsController.performFetch()
        } catch {
            print("An error occurred")
        }
        return fetchedResultsController
    }
    
    func delete(object: Contacts) {
        let context = persistentContainer.viewContext
        context.delete(object)
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
    
    func newContact(onBackground: Bool) -> ContactObject {
        return Contacts(context: onBackground ? writeContext : persistentContainer.viewContext)
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

