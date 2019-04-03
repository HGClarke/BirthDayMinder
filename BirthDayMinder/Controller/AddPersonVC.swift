//
//  AddPersonVC.swift
//  BirthDayMinder
//
//  Created by Holland Clarke on 3/18/19.
//  Copyright © 2019 Holland Clarke. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

class AddPersonVC: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var personImage: UIImageView!
    @IBOutlet var birthdayDatePicker: UIDatePicker!
    @IBOutlet var enterBdayLbl: UILabel!
    
    // MARK: - Variables
    var specificPerson: Person?
    var indexPathToEdit : IndexPath?
    let imagePickerController = UIImagePickerController()
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDatePicker()
        setupUI()
        nameTextField.delegate = self
        nameTextField.textAlignment = .center
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.allowsEditing = true
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // MARK: - Created Functions
    
    private func setupUI() {
        if let person = specificPerson {
            nameTextField.text = "\(person.name!)"
            birthdayDatePicker.date = person.birthday ?? Date()
            personImage.image = UIImage(data: person.image!)
        }
    }
    
    private func setupDatePicker() {
        birthdayDatePicker.datePickerMode = .date
        birthdayDatePicker.maximumDate = Date(timeIntervalSinceNow: 0)
    }
    
    private func presentPhotoPicker() {
        
        self.present(imagePickerController, animated: true)
    }

    // Create a notification request
    private func createNotificationRequest(for person: Person) {
        
        // TODO: - Use optional chaining to unwrap the person object
        // Create a date components object
        var dateComponents = DateComponents()
        
        // Get the current user's calendar
        let calendar = Calendar.current
        
        // Get the day and month components of the person's birthday, then assign it to the date components object
        let birthdayComponents = calendar.dateComponents([.day, .month], from: person.birthday!)
        dateComponents = birthdayComponents
        dateComponents.hour = 0
      
        // Create a trigger that will go off on this person's birthday at 00:00 hours
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "It's \(person.name!)'s Birthday Today"
        content.body = "Don't forget to wish them Happy Birthday"
        content.sound = UNNotificationSound.default

        // Add the request to the user's notification center.
        let request = UNNotificationRequest(identifier: person.identifier!, content: content, trigger: trigger)
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request) { (error) in
            guard error == nil else {
                print("Error: ", error.debugDescription)
                return
            }
        }
    }
    
    // Create a new person object and add it to Core Data
    private func createNewPerson() {
        let newPerson = Person(context: context)
        newPerson.birthday = birthdayDatePicker.date
        newPerson.name = nameTextField.text!
        newPerson.identifier = UUID().uuidString
        let image = personImage.image
        newPerson.image = image?.jpegData(compressionQuality: 1)
        context.insert(newPerson)
        createNotificationRequest(for: newPerson)
    }
    
    // Modify the person if a person was passed through the segue
    private func modifySpecificPerson() {
        
        if let  person = specificPerson {
            person.name = nameTextField.text ?? ""
            person.birthday = birthdayDatePicker.date
            person.identifier = specificPerson?.identifier
            let image = personImage.image
            let imageData = image?.jpegData(compressionQuality: 1)
            person.image = imageData
            specificPerson = person
            modifiyNotificationRequest(for: person)
            
        }

    }
    
    // Modify the notification request with the new data for the person
    private func modifiyNotificationRequest(for person: Person) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [person.identifier!])
        createNotificationRequest(for: person)
    }
    
    // Save any changes
    private func saveItems() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Could not save data")
            }
        }
    }
    
    // MARK: - IBAction Functions
    @IBAction func textFieldChanged(_ sender: UITextField) {
        if let name = nameTextField.text, !nameTextField.text!.isEmpty {
            enterBdayLbl.text = "Enter birth date for: \(name)"
        } else {
            enterBdayLbl.text = "Enter birth date for:"
        }
    }
    
    @IBAction func customImageBtnPressed(_ sender: UIButton) {
        
        presentPhotoPicker()
    }
    
    @IBAction func doneBtnPressed(_ sender: UIButton) {

        // If an indexPath was passed in then we are editting the data of that specific person
        // Otherwise we will create a new person and add it to Core Data
        if let _ = indexPathToEdit {
            modifySpecificPerson()
        } else {
           createNewPerson()
        }
        saveItems()
        navigationController?.popViewController(animated: true)
    }
}

extension AddPersonVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}

extension AddPersonVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[.editedImage] as? UIImage {
            self.personImage.image = image
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
