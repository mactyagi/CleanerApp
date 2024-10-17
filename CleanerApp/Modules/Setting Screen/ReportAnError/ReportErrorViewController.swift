//
//  ReportErrorViewController.swift
//  CleanerApp
//
//  Created by Sneha Tyagi on 14/10/24.
//

import UIKit

class ReportErrorViewController: UIViewController, UITextViewDelegate {
    
    
    // MARK: - IBOutlets
    @IBOutlet weak var contactInfoLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!

    @IBOutlet weak var emailTextField: UITextField!
        @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var messageTextViewHeightConstraint: NSLayoutConstraint!
    
    let minHeight: CGFloat = 250
    // MARK: - ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUIView()
        setupUI()
        messageTextView.delegate = self

    }
    
    
    // MARK: - UIView Changes
    func setupUIView() {
        // Set the background color of your existing view
        view.backgroundColor = UIColor.secondaryBackground// Replace with your preferred color
//        navigationController?.navigationBar.barTintColor = UIColor.red
       }
    
    // MARK: - UITextViewDelegate Methods
    
    // This method is called when the user starts editing
      func textViewDidBeginEditing(_ textView: UITextView) {
          if textView.text == messageTextView.text {
              textView.text = "" // Clear the placeholder text
              textView.textColor = UIColor.systemGray // Set the text color for user input
          }
      }
      
      // This method is called when the user finishes editing
      func textViewDidEndEditing(_ textView: UITextView) {
          if textView.text.isEmpty {
              // If text view is empty, show the placeholder
              textView.text = messageTextView.text
              textView.textColor = UIColor.lightGray // Set the placeholder color back
          }
      }
    
    
    
    func textViewDidChange(_ textView: UITextView) {
        let size = textView.contentSize
        messageTextViewHeightConstraint.constant = size.height
//        UIView.animate(withDuration: 0.2) {
//            self.view.layoutIfNeeded()
//        }
        let maxHeight: CGFloat = view.bounds.height/2 // Set the maximum height for the text view
        
        if size.height > minHeight{
            if size.height <= maxHeight {
                messageTextViewHeightConstraint.constant = size.height
            } else {
                messageTextViewHeightConstraint.constant = maxHeight
            }
        }else{
            messageTextViewHeightConstraint.constant = minHeight
        }
        
    }

    
    // MARK: - Setup the initial UI
    func setupUI() {
        contactInfoLabel.font = .avenirNext(ofSize: 20, weight: .semibold)
        messageLabel.font = .avenirNext(ofSize: 20, weight: .semibold)
        
//        // Set the placeholder text for the TextView
               messageTextView.text = "report an error, request a feature, or say hello"
        messageTextView.textColor = UIColor.systemGray
        
        // Add a border around the TextView (optional)
               messageTextView.layer.borderWidth = 1.0
               messageTextView.layer.borderColor = UIColor.systemGray6.cgColor
               messageTextView.layer.cornerRadius = 8
        
        messageTextViewHeightConstraint.constant = minHeight
        
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
