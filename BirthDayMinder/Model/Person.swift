//
//  Person.swift
//  BirthDayMinder
//  
//  Created by Holland Clarke on 3/18/19.
//  Copyright © 2019 Holland Clarke. All rights reserved.
//

import UIKit

struct Person {
    let name: String
    let image: UIImage?
    let birthday: Date
}

struct BirthdayData {
    let daysLeft: Int
    let upcomingAge: Int
}
