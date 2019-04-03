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
    @IBOutlet var searchBar: UISearchBar!
    
    // MARK: - Variables
    var persons : [Person] = []
    var filteredPersons : [Person] = []
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var indexPathToEdit : IndexPath?
    
   
    // MARK: - View Life Cycles
    override func viewDidAppear(_ animated: Bool) {
        getAllPersons()
//        setUpSearchBar()
        searchBar.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        
        
    }
    
    // MARK: - Created Functions
    private func setupTableView() {
        birthdayTableView.delegate = self
        birthdayTableView.dataSource = self
        birthdayTableView.rowHeight = 85
    }
    
    // Fetch all the items in core data and assign it to the person's array
    private func getAllPersons() {
        let request: NSFetchRequest<Person> = Person.fetchRequest()
        do {
            persons = try context.fetch(request)
            filteredPersons = persons
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
        let currentComponents = calendar.dateComponents([.day, .month], from: today)
        let birthdayComponents = calendar.dateComponents([.day,.month], from: nextBirthDay)
        
        if birthdayComponents.day! - currentComponents.day! == 0 && birthdayComponents.month! - currentComponents.month! == 0 {
            isBirthdayToday = true

        }
        // Get their upcoming age
        let upcomingAge = calendar.dateComponents([.year], from: birthday, to: nextBirthDay).year!
        
        let birthdayData = BirthdayData(daysLeft: daysUntilNextBirthday, upcomingAge: upcomingAge, isBirthdayToday: isBirthdayToday)
        return birthdayData
    }
    
    // Deletes the person from core data, removes the notification request and deletes the rows
    // from the table view
    private func deleteData(at indexPath: IndexPath) {
        birthdayTableView.deleteRows(at: [indexPath], with: .fade)
        let person = filteredPersons[indexPath.row]
        removeNotificationRequest(for: person)
        context.delete(person)
        saveItems()
        filteredPersons.remove(at: indexPath.row)
        
    }
    
    // Save any data if there have been any changes
    private func saveItems(){
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Could not save data")
            }
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
            text = "Turning \(data.upcomingAge)"
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
        
        let person = filteredPersons[indexPath.row]
        cell.personNameLbl.text = person.name
        cell.personNameLbl.adjustsFontSizeToFitWidth = true
        let birthdayData = timeUntilNextBirthday(from: person.birthday!)
        let daysLeft = birthdayData.daysLeft
        var text = ""
        cell.personImage.image = UIImage(data: person.image ?? UIImage().jpegData(compressionQuality: 1)!)
        // Sets the text based on when the person's birthday is
        let birthYear = Calendar.current.dateComponents([.year], from: person.birthday!).year!
        let currentYear = Calendar.current.dateComponents([.year], from: Date()).year!
        
        // If person is born in the current year their upcoming age is 1
        // Configure the text of the upcoming age label otherwise
        if currentYear == birthYear {
            text = "Turning 1"
            cell.daysLeftNumberLbl.text = String(daysLeft)
            
        }
        else if birthdayData.isBirthdayToday {
            cell.daysLeftNumberLbl.text = "0"
            text = configureCellText(from: birthdayData)
        }
        else {
            text = configureCellText(from: birthdayData)
            cell.daysLeftNumberLbl.text = String(daysLeft)
        }
        
        cell.upcomingBirthdayLbl.text = text
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        indexPathToEdit = indexPath
        let person = filteredPersons[indexPath.row]
        performSegue(withIdentifier: segueIdentifier, sender: person)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredPersons.count
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

extension BirthdayListVC: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
      filteredPersons = searchText.isEmpty ? persons : persons.filter({(person: Person) -> Bool in
            // If dataItem matches the searchText, return true to include it
        return person.name!.range(of: searchText, options: .caseInsensitive) != nil
        })
        birthdayTableView.reloadData()
     
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        searchBar.text = ""
        getAllPersons()
    }
    
}

