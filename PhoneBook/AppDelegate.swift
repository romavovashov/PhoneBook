//
//  AppDelegate.swift
//  PhoneBook
//
//  Created by Vladimir Romashov on 07.05.2020.
//  Copyright © 2020 Vladimir Romashov. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        if UserDefaults.isFirstLaunch() {
            storeContacts()
        }
        return true
    }
    
    func storeContacts() {
        let queue = DispatchQueue.global(qos: .background)
        queue.async {
            let dataStorage = DataStorage()
            guard let path = Bundle(for: type(of: self)).url(forResource: "contacts_data", withExtension: "json"), let data = try? Data(contentsOf: path) else { return }
            guard let contacts = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: AnyHashable]]else { return }
            
            for contactDictionary in contacts {
                var contact = dataStorage.createContact()
                guard let firstname = contactDictionary["firstname"] as? String else { return }
                contact.firstname = firstname
                guard let lastname = contactDictionary["lastname"] as? String else { return }
                contact.lastname = lastname
                guard let email = contactDictionary["email"] as? String else { return }
                contact.email = email
                guard let phone = contactDictionary["phone"] as? String else { return }
                contact.phone = phone
                
            }
            dataStorage.save()
        }
    }
}

