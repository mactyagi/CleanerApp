//
//  ReportErrorViewController.swift
//  CleanerApp
//
//  Created by Sneha Tyagi on 14/10/24.
//

import UIKit

class ReportErrorViewController: UIViewController {
    
    
    // MARK: - IBOutlets
    @IBOutlet weak var contactInfoLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!

    @IBOutlet weak var emailTextField: UITextField!
        @IBOutlet weak var messageTextView: UITextView!
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }
    
    // Setup the initial UI
    func setupUI() {
        contactInfoLabel.font = .avenirNext(ofSize: 18, weight: .medium)
        messageLabel.font = .avenirNext(ofSize: 18, weight: .medium)
        
        // Set the placeholder text for the TextView
               messageTextView.text = "report an error, request a feature, or say hello"
        messageTextView.textColor = UIColor.systemGray
        
        // Add a border around the TextView (optional)
               messageTextView.layer.borderWidth = 1.0
               messageTextView.layer.borderColor = UIColor.systemGray6.cgColor
               messageTextView.layer.cornerRadius = 8
        
    }
    
    // MARK: - Submit Button Action
        @IBAction func submitButtonTapped(_ sender: UIButton) {
            // Handle the submit action
            let email = emailTextField.text ?? ""
            let message = messageTextView.text ?? ""

            if email.isEmpty || message.isEmpty {
                // Show an alert or handle empty input
                showAlert(title: "Error", message: "Please fill out all fields.")
            } else {
                // Proceed with submitting the message
                print("Email: \(email), Message: \(message)")
            }
        }
   
    // MARK: - Show Alert Helper Function
        func showAlert(title: String, message: String) {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
        }
    
}
