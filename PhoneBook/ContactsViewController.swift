//
//  ContactsViewController.swift
//  PhoneBook
//
//  Created by Vladimir Romashov on 07.05.2020.
//  Copyright © 2020 Vladimir Romashov. All rights reserved.
//

import UIKit
import CoreData
import ContactsUI
import CallKit

class ContactsViewController: UIViewController, UISearchResultsUpdating {

    static let reuseIdentifier = "ContactsViewController"
    
    @IBOutlet private weak var tableView: UITableView!
    
    private let database = DataStorage()
    private lazy var fetchedResultsController = database.setupFetchedResultsController(delegate: self)
    private var isEditContact: Bool = false
    private var currentObject: Contacts?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearch()
    }
    
    private func setupSearch() {
        let searchController = UISearchController()
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Contacts Search"
        searchController.searchBar.autocapitalizationType = .none
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
    }
    
    @IBAction private func addContactFromPhone(sender: UIBarButtonItem) {
        isEditContact = false
        let contactController = CNContactViewController(forNewContact: nil)
        contactController.allowsEditing = true
        contactController.allowsActions = false
        contactController.displayedPropertyKeys = [ CNContactPhoneNumbersKey, CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey]
        contactController.delegate = self
        contactController.view.layoutIfNeeded()
        navigationController?.pushViewController(contactController, animated: true)
    }
    
// MARK: - SearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""
        var predicate: NSPredicate?
        if searchText.count > 0 {
            predicate = NSPredicate(format: "(firstname contains[cd] %@) || (lastname contains[cd] %@)", searchText, searchText)
        } else {
            predicate = nil
        }
        fetchedResultsController.fetchRequest.predicate = predicate
        do {
            try fetchedResultsController.performFetch()
            tableView.reloadData()
        } catch let err {
            print(err)
        }
    }
}

//MARK: - UITableViewDataSource

extension ContactsViewController: UITableViewDataSource {
    // 1
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections.count
        }
        return 0
    }
    
    // 2
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let count = fetchedResultsController.sections?[section].numberOfObjects else  {
            return 0
        }

        return count
    }
    
    // 3
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let firstname = fetchedResultsController.object(at: indexPath).firstname,
            let lastname = fetchedResultsController.object(at: indexPath).lastname else {
                return UITableViewCell()
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath)
        cell.textLabel?.text = "\(firstname) \(lastname)"
        return cell
    }
    
    // 4
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let section = fetchedResultsController.sections?[section] {
            return section.name
        }
        return nil
    }
    // 5
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return fetchedResultsController.sectionIndexTitles
    }
    // 6
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        let result = fetchedResultsController.section(forSectionIndexTitle: title, at: index)
        return result
    }
    
    // 7
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") {  (contextualAction, view, boolValue) in
            self.database.delete(object: self.fetchedResultsController.object(at: indexPath))
        }
        let swipeActions = UISwipeActionsConfiguration(actions: [deleteAction])
        return swipeActions
    }
}

//MARK: - UITableViewDelegate

extension ContactsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        isEditContact = true
        tableView.deselectRow(at: indexPath, animated: true)
        let contact = fetchedResultsController.object(at: indexPath)
        currentObject = contact
        let contactViewController = CNContactViewController(for: contact.contactValue)
        contactViewController.allowsEditing = true
        contactViewController.allowsActions = false
        contactViewController.delegate = self
        navigationController?.pushViewController(contactViewController, animated: true)
    }
}

//MARK: - CNContactViewControllerDelegate

extension ContactsViewController: CNContactViewControllerDelegate {
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        
        if let contact = contact {
            if isEditContact {
                currentObject?.firstname = contact.givenName
                currentObject?.lastname = contact.familyName
                currentObject?.email = contact.emailAddresses.compactMap { $0 }.first?.value as String?
                currentObject?.phone = contact.phoneNumbers.compactMap { $0 }.first?.value.stringValue
                database.save()
            } else {
                var newContact = database.createContact()
                newContact.firstname = contact.givenName
                newContact.lastname = contact.familyName
                newContact.email = contact.emailAddresses.compactMap { $0 }.first?.value as String?
                newContact.phone = contact.phoneNumbers.compactMap { $0 }.first?.value.stringValue
                
                database.save()
            }
        }
        navigationController?.popViewController(animated: true)
    }
    func contactViewController(_ viewController: CNContactViewController,
                               shouldPerformDefaultActionFor property: CNContactProperty) -> Bool {
        return true
    }
}

//MARK: - NSFetchedResultsControllerDelegate

extension ContactsViewController: NSFetchedResultsControllerDelegate {
    
    // 1
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, sectionIndexTitleForSectionName sectionName: String) -> String? {
        return sectionName
    }
    
    // 2
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        DispatchQueue.main.async {
            self.tableView.beginUpdates()
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        DispatchQueue.main.async {
            switch type {
            case .insert:
                self.tableView.insertSections(NSIndexSet(index: sectionIndex) as IndexSet, with: .fade)
            case .delete:
                self.tableView.deleteSections(NSIndexSet(index: sectionIndex) as IndexSet, with: .fade)
            default:
                return
            }
        }
    }
    
    // 4
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        DispatchQueue.main.async {

            switch type {
            case .update:
                if let indexPath = indexPath {
                    let product = self.fetchedResultsController.object(at: indexPath)
                    let cell = self.tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath)
                    cell.textLabel?.text = "\(product.firstname ?? "") \(product.lastname ?? "")"
                    self.tableView.reloadData()
                }
            case .delete:
                if let indexPath = indexPath {
                    self.tableView.deleteRows(at: [indexPath], with: .automatic)
                }
            case .insert:
                if let indexPath = newIndexPath {
                    self.tableView.insertRows(at: [indexPath], with: .automatic)
                }
            case .move:
                if let indexPath = indexPath {
                    self.tableView.deleteRows(at: [indexPath], with: .automatic)
                }
            default:
                break

            }
        }
    }
    
    // 5
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        DispatchQueue.main.async {
            self.tableView.endUpdates()
        }
    }
}
