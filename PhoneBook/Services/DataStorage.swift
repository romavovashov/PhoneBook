//
//  DataStorage.swift
//  PhoneBook
//
//  Created by Vladimir Romashov on 07.05.2020.
//  Copyright © 2020 Vladimir Romashov. All rights reserved.
//

import UIKit
import CoreData

protocol StorageObject {}

protocol ContactObject: StorageObject {
    var firstname: String? { get set }
    var lastname: String? { get set }
    var phone: String? { get set }
    var email: String? { get set }
}

open class DataStorage {

    public func cleanup() {
        storage.cleanup()
    }

    func save(onBackground: Bool = false) {
        storage.save(onBackground: onBackground)
    }

    func delete(object: Contacts) {
        storage.delete(object: object)
    }
    func createContact(onBackground: Bool = false) -> ContactObject {
        return storage.newContact(onBackground: onBackground)
    }
    
    func setupFetchedResultsController(delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<Contacts> {
        return storage.setupFetchedResultsController(delegate: delegate)
    }

    private var storage: LocalStorage = DatabaseServices.shared
}

protocol LocalStorage {
    func cleanup()
    func save(onBackground: Bool)
    func delete(object: Contacts)
    func newContact(onBackground: Bool) -> ContactObject
    func setupFetchedResultsController(delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<Contacts>
}

enum FetchResult {
    case object(StorageObject)
    case array([StorageObject])
    case report([[String:Any]])
    case empty
}
