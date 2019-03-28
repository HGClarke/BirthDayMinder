//
//  File.swift
//  BirthDayMinder
//
//  Created by Holland Clarke on 3/18/19.
//  Copyright © 2019 Holland Clarke. All rights reserved.
//

import UIKit

let reuseIdentifier = "birthdayCell"
let segueIdentifier = "showPersonVC"

struct CoreDataKeys {
    static let recordType = "Person"
    static let personNameKey = "name"
    static let birthdayKey = "birthday"
    static let entityName = "PersonData"
    static let identifier = "identifier"
}


struct Colors {
    static let robinBlue = UIColor(red:0.00, green:0.81, blue:0.79, alpha:1.0)
    static let firstDate = UIColor(red:0.98, green:0.69, blue:0.63, alpha:1.0)
    static let blueTail = UIColor(red:0.45, green:0.73, blue:1.00, alpha:1.0)
    static let mintLeaf = UIColor(red:0.00, green:0.72, blue:0.58, alpha:1.0)
    
    static let colorsArray = [Colors.robinBlue, Colors.firstDate, Colors.blueTail, Colors.mintLeaf]

}
