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

class ContactsViewController: UIViewController {

    static let reuseIdentifier = "ContactsViewController"
    
    @IBOutlet private weak var tableView: UITableView!
    
    private let database = DataStorage()
    private lazy var fetchedResultsController = database.setupFetchedResultsController(delegate: self)
    //TODO: Add implementation
    private let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationItem.title = "Contacts"
    }

    @IBAction private func addContactFromPhone(sender: UIBarButtonItem) {
        
        let contactController = CNContactViewController(forNewContact: nil)

        contactController.allowsEditing = true
        contactController.allowsActions = false
        contactController.displayedPropertyKeys = [ CNContactPhoneNumbersKey, CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey]
        contactController.delegate = self
        contactController.view.layoutIfNeeded()
        navigationController?.pushViewController(contactController, animated: true)
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
        print("SectionNumber: \(count)")
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
            print("SectionName: \(section.name)")
            return section.name
        }
        return nil
    }
    // 5
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        print("sectionIndexTitles\(fetchedResultsController.sectionIndexTitles)")
        return fetchedResultsController.sectionIndexTitles
    }
    // 6
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        let result = fetchedResultsController.section(forSectionIndexTitle: title, at: index)
        print("sectionForSectionIndexTitle: \(result)")
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
        tableView.deselectRow(at: indexPath, animated: true)
        // 1
        let contacts = fetchedResultsController.object(at: indexPath)
        let contact = contacts.contactValue
        // 2
        let contactViewController = CNContactViewController(for: contact)

        contactViewController.allowsEditing = true
        contactViewController.allowsActions = true
        contactViewController.delegate = self
        // 3
        navigationController?.pushViewController(contactViewController, animated: true)
    }
}

//MARK: - CNContactViewControllerDelegate
extension ContactsViewController: CNContactViewControllerDelegate {
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        if let contact = contact {
            var newContact = database.createContact()
            newContact.firstname = contact.givenName
            newContact.lastname = contact.familyName
            newContact.email = contact.emailAddresses.first?.label
            newContact.phone = contact.phoneNumbers.first?.label
            database.save()
        }
        navigationController?.popViewController(animated: true)
    }
    
    func contactViewController(_ viewController: CNContactViewController, shouldPerformDefaultActionFor property: CNContactProperty) -> Bool {
        print("")
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
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
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
