//
//  OrganizeContactsViewController.swift
//  CleanerApp
//
//  Created by Manu on 20/02/24.
//

import UIKit
import Combine
import SwiftUI

class OrganizeContactsViewController: UIViewController {

    //MARK: - IBOutlets
    @IBOutlet weak var duplicateCountLabel: UILabel!
    @IBOutlet weak var incompleteContactsCountLabel: UILabel!
    @IBOutlet weak var backupCountLabel: UILabel!
    @IBOutlet weak var allContactsCountLabel: UILabel!
    
    
    //MARK: - Variables
    var viewModel: OrganizeContactViewModel!
    private var cancelables: Set<AnyCancellable> = []

    //MARK: - lifecycles
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        setupNavigationBarButton()
    }

    private func setupNavigationBarButton() {
        let previewButton = UIBarButtonItem(
            image: UIImage(systemName: "rectangle.on.rectangle"),
            style: .plain,
            target: self,
            action: #selector(previewDesignsTapped)
        )
        navigationItem.rightBarButtonItem = previewButton
    }

    @objc private func previewDesignsTapped() {
        showOrganizeContactsSwiftUIView()
    }


    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.getData()
        navigationController?.navigationBar.prefersLargeTitles = false
        setupNavigationAndTabBar(isScreenVisible: false)
    }

    
    //MARK: - Static Function
    static func customInit(viewModel: OrganizeContactViewModel) -> OrganizeContactsViewController{
        let vc = UIStoryboard.contact.instantiateViewController(identifier: Self.className) as! Self
        vc.viewModel = viewModel
        return vc
    }

    //MARK: - IBActions
    @IBAction func duplicateButtonPressed(_ sender: UIButton) {
        showDesignSelector()
    }

    //MARK: - Design Selector for Duplicate Contacts
    private func showDesignSelector() {
        let alert = UIAlertController(title: "Select Design", message: "Choose a design to preview", preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Design 0 - UIKit (Original)", style: .default) { [weak self] _ in
            self?.navigateToDuplicateContacts(design: 0)
        })

        alert.addAction(UIAlertAction(title: "Design 3 - Modern Gradient", style: .default) { [weak self] _ in
            self?.navigateToDuplicateContacts(design: 3)
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // For iPad support
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        present(alert, animated: true)
    }

    private func navigateToDuplicateContacts(design: Int) {
        let duplicateViewModel = DuplicateContactsViewModel(contactStore: viewModel.contactStore)

        switch design {
        case 0:
            // Original UIKit Design
            let vc = DuplicateContactsViewController.customInit(viewModel: duplicateViewModel)
            navigationController?.pushViewController(vc, animated: true)

        case 3:
            // SwiftUI Design 3 - Modern Gradient
            let swiftUIView = DuplicateContactsViewDesign(viewModel: duplicateViewModel)
            let hostingController = UIHostingController(rootView: swiftUIView)
            hostingController.title = "Duplicate Contacts"
            navigationController?.pushViewController(hostingController, animated: true)

        default:
            break
        }
    }
    

    @IBAction func inCompletContactButtonPressed(_ sender: UIButton) {
        let incompleteViewModel = IncompleteContactViewModel(contactStore: viewModel.contactStore)
        let swiftUIView = IncompleteContactView(viewModel: incompleteViewModel)
        let hostingController = UIHostingController(rootView: swiftUIView)
        navigationController?.pushViewController(hostingController, animated: true)
    }
    
    @IBAction func backUpButtonPressed(_ sender: UIButton) {

    }
    
    @IBAction func AllContactsButtonPressed(_ sender: UIButton) {
        let allContactViewModel = AllContactsVIewModel(contactStore: viewModel.contactStore)
        let swiftUIView = AllContactsView(viewModel: allContactViewModel)
        let hostingController = UIHostingController(rootView: swiftUIView)
        navigationController?.pushViewController(hostingController, animated: true)
    }
    
    
    
    //MARK: - setup Functions
    func setupViewModel(){
        setSubscribers()
    }

    //MARK: - SwiftUI Organize Contacts View
    private func showOrganizeContactsSwiftUIView() {
        let swiftUIView = OrganizeContactsView(
            viewModel: viewModel,
            onDuplicatesTapped: { [weak self] in self?.duplicateButtonPressed(UIButton()) },
            onIncompleteTapped: { [weak self] in self?.inCompletContactButtonPressed(UIButton()) },
            onBackupTapped: { [weak self] in self?.backUpButtonPressed(UIButton()) },
            onAllContactsTapped: { [weak self] in self?.AllContactsButtonPressed(UIButton()) }
        )
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.title = "Contacts"
        navigationController?.pushViewController(hostingController, animated: true)
    }
}



extension OrganizeContactsViewController{
    func setSubscribers(){
        viewModel.$allContacts.sink { [weak self] contacts in
            DispatchQueue.main.async {
                guard let self else { return }
                self.allContactsCountLabel.text = "\(contacts.count)"
            }
        }.store(in: &cancelables)
        
        viewModel.$duplicateCount.sink { [weak self] count in
            DispatchQueue.main.async {
                guard let self else { return }
                self.duplicateCountLabel.text = "\(count)"
            }
        }.store(in: &cancelables)
        
        viewModel.$incompleteContactsCount.sink { [weak self] count in
            DispatchQueue.main.async {
                guard let self else { return }
                self.incompleteContactsCountLabel.text = "\(count)"
            }
        }.store(in: &cancelables)

        viewModel.$incompleteContacts.sink { [weak self] incompletContacts in
            DispatchQueue.main.async {
                guard let self else { return }
                self.incompleteContactsCountLabel.text = "\(incompletContacts.count)"
            }
        }.store(in: &cancelables)
    }
}
