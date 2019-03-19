//
//  ViewController.swift
//  BirthDayMinder
//
//  Created by Holland Clarke on 3/18/19.
//  Copyright © 2019 Holland Clarke. All rights reserved.
//

import UIKit

class BirthdayListVC: UIViewController {

    @IBOutlet var birthdayTableView: UITableView!
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter
    }
    
    var persons: [Person] = []
    var indexToEdit : Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        birthdayTableView.delegate = self
        birthdayTableView.dataSource = self
        birthdayTableView.separatorStyle = .none
        
    }
    
    private func timeUntilNextBirthday(from birthday: Date) -> BirthdayData {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayAndMonth = calendar.dateComponents([.day, .month], from: birthday)
        let nextBirthDay = calendar.nextDate(after: today, matching: dayAndMonth,
                                        matchingPolicy: .nextTimePreservingSmallerComponents)!
        
        let daysUntilNextBirthday = calendar.dateComponents([.day], from: today, to: nextBirthDay).day!
        
        
        var upcomingAge = calendar.dateComponents([.year], from: birthday, to: nextBirthDay).year!
        
        if upcomingAge == 0 {
            upcomingAge = 1
        }
        let birthdayData = BirthdayData(daysLeft: daysUntilNextBirthday, upcomingAge: upcomingAge)
        return birthdayData
    }
}

extension BirthdayListVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = birthdayTableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? BirthdayCell else {
            fatalError("The dequeued cell is not an instance of Birthday Cell")
        }

        
        cell.personImage.contentMode = .scaleAspectFit
        cell.personImage.image = persons[indexPath.row].image
        cell.personNameLbl.text = persons[indexPath.row].name
        let birthdayData = timeUntilNextBirthday(from: persons[indexPath.row].birthday)
        let upcomingAge = birthdayData.upcomingAge
        let daysUntilBday = birthdayData.daysLeft
        
        cell.upcomingBirthdayLbl.text = "Turns \(upcomingAge) in: \(daysUntilBday) days"
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        indexToEdit = indexPath.row
        performSegue(withIdentifier: segueIdentifier, sender: persons[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return persons.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        
        if editingStyle == .delete {
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .fade)
            persons.remove(at: indexPath.row)
            tableView.endUpdates()
        }
    }
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let edit = UIContextualAction(style: .normal, title: "Edit") { (contextualAction, view, actionPerformed: (Bool) -> Void) in
            self.indexToEdit = indexPath.row
            let person = self.persons[indexPath.row]
            self.performSegue(withIdentifier: segueIdentifier, sender: person)
            actionPerformed(true)
        }
        edit.backgroundColor = .blue
        
        return UISwipeActionsConfiguration(actions: [edit])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == segueIdentifier {
            guard let destinationVC = segue.destination as? AddPersonVC else { return }
            guard let personData = sender as? Person else { return }
            destinationVC.person = personData
            destinationVC.indexToEdit = indexToEdit
        }
    }
    
    
}

