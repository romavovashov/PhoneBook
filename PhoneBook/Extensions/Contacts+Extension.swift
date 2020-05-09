//
//  Contacts+Extension.swift
//  PhoneBook
//
//  Created by Vladimir Romashov on 08.05.2020.
//  Copyright © 2020 Vladimir Romashov. All rights reserved.
//

import UIKit
import Contacts

extension Contacts {
   @objc var lastNameFirstLetter: String { String(lastname?.prefix(1) ?? "#") }
}

extension Contacts {
    var contactValue: CNContact {
        get {
            let contact = CNMutableContact()
            contact.givenName = firstname ?? ""
            contact.familyName = lastname ?? ""
            contact.emailAddresses = [CNLabeledValue(label: CNLabelWork,
                                                     value: (email ?? "") as NSString)]
            contact.phoneNumbers = [CNLabeledValue(label:CNLabelPhoneNumberiPhone,
                                                   value:CNPhoneNumber(stringValue: "\(phone ?? "")"))]
            return contact.copy() as! CNContact
        }
    }
}

