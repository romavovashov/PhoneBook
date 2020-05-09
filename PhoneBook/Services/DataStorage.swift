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

    func save() {
        storage.save()
    }

    func delete(object: Contacts) {
        storage.delete(object: object)
    }
    func createContact() -> ContactObject {
        return storage.newContact()
    }

    func fetch(filter: FetchFilter) -> FetchResult {
        return storage.fetch(filter: filter)
    }
    
    func setupFetchedResultsController(delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<Contacts> {
        return storage.setupFetchedResultsController(delegate: delegate)
    }

    private var storage: LocalStorage = DatabaseServices.shared
}

protocol LocalStorage {
    func cleanup()
    func save()
    func delete(object: Contacts)
    func newContact() -> ContactObject
    func fetch(filter: FetchFilter) -> FetchResult
    func setupFetchedResultsController(delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<Contacts>
}

protocol FetchFilter {}

enum ContactFetchFilter: FetchFilter {
    case all
}

enum FetchResult {
    case object(StorageObject)
    case array([StorageObject])
    case report([[String:Any]])
    case empty
}
