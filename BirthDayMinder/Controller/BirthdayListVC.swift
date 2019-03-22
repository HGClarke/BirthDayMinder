//
//  ViewController.swift
//  BirthDayMinder
//
//  Created by Holland Clarke on 3/18/19.
//  Copyright © 2019 Holland Clarke. All rights reserved.
//

import UIKit
import CloudKit
import UserNotifications

class BirthdayListVC: UITableViewController {

    @IBOutlet var birthdayTableView: UITableView!
    
    var persons: [CKRecord] = []
    var notes: [CKRecord] = []
    var indexToEdit : Int?
    
    private let privateDatabase = CKContainer.default().privateCloudDatabase

    override func viewDidLoad() {
        super.viewDidLoad()
        birthdayTableView.delegate = self
        birthdayTableView.dataSource = self
        birthdayTableView.separatorStyle = .none
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull down to refresh")
        refreshControl.addTarget(self, action: #selector(fetchDataFromCloud), for: .valueChanged)
        birthdayTableView.refreshControl = refreshControl
        fetchDataFromCloud()

    }
    
    // Function gets all the data from iCloud and populates the notes array with all the data
    @objc fileprivate func fetchDataFromCloud() {
        // Create a query to get all the data
        let query = CKQuery(recordType: "Note", predicate: NSPredicate(value: true))
        
        // Perform the query on the private database because this is where the user's data is stored
        privateDatabase.perform(query, inZoneWith: nil) { (records, error) in
            // Ensure that there is no error
            // If there is an error we need to handle it
            guard error == nil else {
                print("Error: ", error.debugDescription)
                return
            }
            
            // Unwrap the records object in the handler
            if let records = records {
                // Sort the records by creation date
                // The newest records will appear first
                let sortedRecords = records.sorted(by: {$0.creationDate! > $1.creationDate! })
                
                // Assign sortedRecords to notes array
                self.notes = sortedRecords
                
                // Reload the tableview
                DispatchQueue.main.async {
                    self.birthdayTableView.refreshControl?.endRefreshing()
                    self.birthdayTableView.reloadData()
                }
            }
        }
        
    }
    
    // Save a new record to user's iCloud database
    func saveTextToCloud(string: String) {
        
        // Create a new record object
        let newNote = CKRecord(recordType: "Note")
        // Set a value for the key "note"
        newNote.setValue(string, forKey: "note")
        
        // Save the record to the database
        privateDatabase.save(newNote) { (record, error) in
            guard error == nil else {
                print("Error: ", error.debugDescription)
                return
            }
            
            if let _ = record {
                // Create some kind of alert that lets the user know that the data was succesfully saved
                
            }
        }
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
        let daysUntilNextBirthday = calendar.dateComponents([.day], from: today, to: nextBirthDay).day!
        
        // Get their upcoming age
        var upcomingAge = calendar.dateComponents([.year], from: birthday, to: nextBirthDay).year!
        
        if upcomingAge == 0 {
            upcomingAge = 1
        }
        let birthdayData = BirthdayData(daysLeft: daysUntilNextBirthday, upcomingAge: upcomingAge)
        return birthdayData
    }
    
    
    @IBAction func addBtnPressed(_ sender: UIBarButtonItem) {
        
        // This allows us to use test data to make sure data is being saved to the cloud
        let alertController = UIAlertController(title: "New Person", message: "Enter the name of a person", preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.placeholder = "Enter a name"
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let post = UIAlertAction(title: "Add", style: .default) { (_) in
            guard let text = alertController.textFields?.first?.text else { return }
            self.saveTextToCloud(string: text)
            
        }
        alertController.addAction(cancel)
        alertController.addAction(post)
        present(alertController, animated: true, completion: nil)
    }
}

extension BirthdayListVC  {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = birthdayTableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? BirthdayCell else {
            fatalError("The dequeued cell is not an instance of Birthday Cell")
        }
         cell.accessoryType = .disclosureIndicator
        let note = notes[indexPath.row]
        let text = note.value(forKey: "note") as! String
        cell.personNameLbl.text = text
        cell.upcomingBirthdayLbl.text = "Upcoming \(text)"
        
        return cell
    }
    
    // Remove a record from the private iCloud database
    private func removeRecordFromCloud(at indexPath: IndexPath) {
        // Get the record
        let record = notes[indexPath.row]
        
        // Delete the record from the user's iCloud
        privateDatabase.delete(withRecordID: record.recordID) { (recordID, error) in
            guard error == nil else {
                print("Error: ", error.debugDescription)
                return
            }
            
            // Reload the data
            DispatchQueue.main.async {
                self.notes.remove(at: indexPath.row)
                self.birthdayTableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
    // TODO - Not sure if I need to pass in the uuidString as an identifier for when I eventually want to remove the notification request, may be able to use NotificationDelegate Methods

    // Create a notification request
    private func createNotificationRequest(for person: Person, with uuidString: String) {
        // Create a date components object
        var dateComponents = DateComponents()
        
        // Get the current user's calendar
        let calendar = Calendar.current
        
        // Get the day and month components of the person's birthday, then assign it to the date components object
        let birthdayComponents = calendar.dateComponents([.day, .month], from: person.birthday)
        dateComponents.day = birthdayComponents.day
        dateComponents.month = birthdayComponents.month
        dateComponents.hour = 0
        
        // Create a trigger that will go off on this person's birthday at 00:00 hours
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "It's \(person.name)'s Birthday Today"
        content.body = "Don't forget to wish them Happy Birthday"
        content.sound = UNNotificationSound.default
        
        // Add the request to the user's notification center.
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request) { (error) in
            guard error == nil else {
                print("Error: ", error.debugDescription)
                return
            }
            
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        indexToEdit = indexPath.row
//        performSegue(withIdentifier: segueIdentifier, sender: persons[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count // placeholder data
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
            removeRecordFromCloud(at: indexPath)
            tableView.endUpdates()
        }
    }
    
    // Will implement this method, temporarily disabled to test deletion
//    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//
//        // Create an edit action to allow the user to edit the data at the index path
////        let edit = UIContextualAction(style: .normal, title: "Edit") { (contextualAction, view, actionPerformed: (Bool) -> Void) in
////            // Set indexToedit to the row so we pass the correct index to the
////            // destination view controller shown by the segue
////            self.indexToEdit = indexPath.row
////            let person = self.persons[indexPath.row]
////            self.performSegue(withIdentifier: segueIdentifier, sender: person)
////            actionPerformed(true)
//        }
////        edit.backgroundColor = .blue
//
////        return UISwipeActionsConfiguration(actions: [edit])
//    }
    
    
}

