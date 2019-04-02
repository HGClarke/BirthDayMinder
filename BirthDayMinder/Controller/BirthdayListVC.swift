//
//  ViewController.swift
//  BirthDayMinder
//
//  Created by Holland Clarke on 3/18/19.
//  Copyright © 2019 Holland Clarke. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

class BirthdayListVC: UITableViewController {

    // MARK: - IBOutlets
    @IBOutlet var birthdayTableView: UITableView!
    
    // MARK: - Variables
    var persons : [Person] = []
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var indexPathToEdit : IndexPath?
   
    // MARK: - View Life Cycles
    override func viewWillAppear(_ animated: Bool) {
        getAllPersons()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        birthdayTableView.delegate = self
        birthdayTableView.dataSource = self
    }
    
    // MARK: - Created Functions
    public func getAllPersons() {
        let request: NSFetchRequest<Person> = Person.fetchRequest()
        do {
            persons = try context.fetch(request)
        } catch let error as NSError {
            print("Error:", error.debugDescription)
        }
        birthdayTableView.reloadData()
    }
        
    // Calculate the time until the next birthday of the user
    private func timeUntilNextBirthday(from birthday: Date) -> BirthdayData {
        
        // Get the user's current calendar
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date()) //
        
        // Get the day and month of the person's birthday
        let dayAndMonth = calendar.dateComponents([.day, .month], from: birthday)
        
        // Find the next occurence of their birthday
        let nextBirthDay = calendar.nextDate(after: today, matching: dayAndMonth,
                                        matchingPolicy: .nextTimePreservingSmallerComponents)!
        
        // Calculate the number of days until their next birthday
        var isBirthdayToday = false;
        let daysUntilNextBirthday = calendar.dateComponents([.day], from: today, to: nextBirthDay).day!
        
        if calendar.dateComponents([.day], from: today).day! - calendar.dateComponents([.day], from: nextBirthDay).day! == 0 {
            isBirthdayToday = true
        }
        // Get their upcoming age
        let upcomingAge = calendar.dateComponents([.year], from: birthday, to: nextBirthDay).year!
        
        let birthdayData = BirthdayData(daysLeft: daysUntilNextBirthday, upcomingAge: upcomingAge, isBirthdayToday: isBirthdayToday)
        return birthdayData
    }
    
    private func deleteData(at indexPath: IndexPath) {
        birthdayTableView.deleteRows(at: [indexPath], with: .fade)
        let person = persons[indexPath.row]
        removeNotificationRequest(for: person)
        context.delete(person)
        saveItems()
        persons.remove(at: indexPath.row)
    }
    
    func saveItems(){
        do {
            try context.save()
        } catch let error as NSError {
            print("Error", error.debugDescription)
        }
    }
    private func removeNotificationRequest(for person: Person) {
        let identifier = person.identifier
        let noticationCenter = UNUserNotificationCenter.current()
        noticationCenter.removePendingNotificationRequests(withIdentifiers: [identifier!])
    }
    
    private func configureCellText(from data: BirthdayData) -> String {
        var text = ""
        
        if data.isBirthdayToday {
            text = "Turns \(data.upcomingAge - 1) Today"
        
        } else if data.daysLeft == 1 {
            text = "Turning \(data.upcomingAge) Tomorrow"
        } else {
            text = "Turning \(data.upcomingAge) in \(data.daysLeft) days"
        }
        return text
    }
    
    
    // MARK: - IBActions
    @IBAction func addBtnPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: segueIdentifier, sender: nil)
    }
}

extension BirthdayListVC  {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueIdentifier {
            guard let destinationVC = segue.destination as? AddPersonVC else { return }
            guard let data = sender as? Person else { return }
            destinationVC.specificPerson = data
            destinationVC.indexPathToEdit = indexPathToEdit
            indexPathToEdit = nil
        }
    }
    
    // MARK: - TableView Delegate Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = birthdayTableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? BirthdayCell else {
            fatalError("The dequeued cell is not an instance of Birthday Cell")
        }
        cell.accessoryType = .disclosureIndicator
        let person = persons[indexPath.row]
        cell.personNameLbl.text = person.name
        cell.personNameLbl.adjustsFontSizeToFitWidth = true
        let birthdayData = timeUntilNextBirthday(from: person.birthday!)
        let daysLeft = birthdayData.daysLeft
        var text = ""
        cell.personImage.image = UIImage(data: person.image!)
        // Sets the text based on when the person's birthday is
        // If daysLeft == 0 then their birthday is today
        // if days left == 1 then their birthday is tomorrow
        // if days left > 1 then it will show the number of days left until the person's birthday
        let birthYear = Calendar.current.dateComponents([.year], from: person.birthday!).year!
        let currentYear = Calendar.current.dateComponents([.year], from: Date()).year!
        
        // If person is born in the current year their upcoming age is 1
        // Configure the text of the upcoming age label otherwise
        if currentYear == birthYear {
            text = "Turns 1 in \(daysLeft) days"
            cell.daysLeftNumberLbl.text = "0"
        } else {
            text = configureCellText(from: birthdayData)
            cell.daysLeftNumberLbl.text = String(daysLeft)
        }
        
        cell.upcomingBirthdayLbl.text = text
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        indexPathToEdit = indexPath
        let person = persons[indexPath.row]
        performSegue(withIdentifier: segueIdentifier, sender: person)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return persons.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            tableView.beginUpdates()
            deleteData(at: indexPath)
            tableView.endUpdates()
        }
    }
    
}

