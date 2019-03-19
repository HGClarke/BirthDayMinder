//
//  AddPersonVC.swift
//  BirthDayMinder
//
//  Created by Holland Clarke on 3/18/19.
//  Copyright © 2019 Holland Clarke. All rights reserved.
//

import UIKit
import Photos

class AddPersonVC: UIViewController {

    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var personImage: UIImageView!
    @IBOutlet var birthdayDatePicker: UIDatePicker!
    @IBOutlet var enterBdayLbl: UILabel!
    
    var person : Person?
    var indexToEdit : Int?
    let imagePickerController = UIImagePickerController()

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
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
    
    private func setupUI() {
        if let person = person {
            nameTextField.text = "\(person.name)"
            birthdayDatePicker.date = person.birthday
            personImage.image = person.image
        }
    }
    private func setupDatePicker() {
        birthdayDatePicker.datePickerMode = .date
        birthdayDatePicker.maximumDate = Date(timeIntervalSinceNow: 0)
    }
    
    fileprivate func presentPhotoPicker() {
        
        self.present(imagePickerController, animated: true)
    }

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
        
        guard let rootVC = navigationController?.viewControllers.first as? BirthdayListVC else {
            fatalError("No view controller found at the bottom of the navigation controller stack")
        }
        let temp = Person(name: nameTextField.text!, image: personImage.image, birthday: birthdayDatePicker.date)
        
        if let index = indexToEdit {
            rootVC.persons[index] = temp
        } else {
            rootVC.persons.append(temp)
        }
        rootVC.birthdayTableView.reloadData()
        
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
        
        if let image = info[.originalImage] as? UIImage {
            self.personImage.image = image
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
