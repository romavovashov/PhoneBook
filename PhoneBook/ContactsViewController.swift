//
//  ContactsViewController.swift
//  PhoneBook
//
//  Created by Vladimir Romashov on 07.05.2020.
//  Copyright © 2020 Vladimir Romashov. All rights reserved.
//

import UIKit
import CoreData

class ContactsViewController: UIViewController {

    static let reuseIdentifier = "ContactsViewController"
    
    @IBOutlet private weak var tableView: UITableView!
    
    private let database = DataStorage()
    lazy var fetchedResultsController = database.setupFetchedResultsController(delegate: self)
    
    var contacts: [ContactObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationItem.title = "Contacts"
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("An error occurred")
        }
    }

}

//MARK: - UITableViewDataSource

extension ContactsViewController: UITableViewDataSource, UITableViewDelegate {
    // 1
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections.count
        }
        return 0
    }
    
    // 2
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let sections = fetchedResultsController.sections?[section].numberOfObjects else  {
            return 0
        }
        print("SectionNumber: \(section)")
        return sections
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
    //5
     func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        print("sectionIndexTitles\(fetchedResultsController.sectionIndexTitles)")
        return fetchedResultsController.sectionIndexTitles
    }
    //6
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        let result = fetchedResultsController.section(forSectionIndexTitle: title, at: index)
        print("sectionForSectionIndexTitle: \(result)")
        return result
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
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(NSIndexSet(index: sectionIndex) as IndexSet, with: .fade)
        case .delete:
            tableView.deleteSections(NSIndexSet(index: sectionIndex) as IndexSet, with: .fade)
        default:
            return
        }
    }
    
    // 4
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if let indexPath = indexPath {
            switch type {
            case .update:
            let product = fetchedResultsController.object(at: indexPath)
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath)
                cell.textLabel?.text = "\(product.firstname ?? "") \(product.lastname ?? "")"
               
            case .delete:
                tableView.deleteRows(at: [indexPath], with: .automatic)
            case .insert:
                tableView.insertRows(at: [indexPath], with: .automatic)
            case .move:
                tableView.deleteRows(at: [indexPath], with: .automatic)
            default:
                break
            }
        }
    }
    
    // 5
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
