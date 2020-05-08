//
//  String+Extensions.swift
//  PhoneBook
//
//  Created by Vladimir Romashov on 08.05.2020.
//  Copyright © 2020 Vladimir Romashov. All rights reserved.
//

import UIKit

extension String {
    func firstCharacter()-> String {
        let startIndex = self.startIndex
        let first = self[...startIndex]
        return String(first)
    }
    
}
