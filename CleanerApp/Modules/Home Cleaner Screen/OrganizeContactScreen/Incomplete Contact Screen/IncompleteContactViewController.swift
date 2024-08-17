//
//  IncompleteContactViewController.swift
//  CleanerApp
//
//  Created by Manu on 06/03/24.
//

import UIKit
import Combine
import ContactsUI
import Contacts

class IncompleteContactViewController: UIViewController, CNContactViewControllerDelegate {

    //MARK: - IBOutlets
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
//#warning("manu")
//#error("error")

    //MARK: - Variables
    var viewModel: IncompleteContactViewModel!
    private var rightBarButtonItem: UIBarButtonItem!
    private var cancelables: Set<AnyCancellable> = []
    private var deleteButtonGradientLayer = CAGradientLayer()
    //MARK: - lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubscriber()
        setupTableView()
        setupUIView()
        configureRightBarButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logEvent(Event.IncompleteContactScreen.appear.rawValue, parameter: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        logEvent(Event.IncompleteContactScreen.disappear.rawValue, parameter: nil)
    }

    //MARK: - overrride functions
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            self.deleteButtonGradientLayer.colors = [UIColor.systemBackground.withAlphaComponent(0).cgColor,
                                   UIColor.systemBackground.withAlphaComponent(1).cgColor]
        }
    }

    //MARK: - customInit
    static func customInit(viewModel: IncompleteContactViewModel) -> IncompleteContactViewController{
        let vc = UIStoryboard.contact.instantiateViewController(identifier: Self.className) as! Self
        vc.viewModel = viewModel
        return vc
    }

    //MARK: - IBAction
    @IBAction func deleteButtonPressed(_ sender: UIButton) {
        logEvent(Event.IncompleteContactScreen.deleteButtonPressed.rawValue, parameter: nil)
        DeleteAlert()
    }


    //MARK: - Setup function
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 90, right: 0)
        tableView.register(UINib(nibName: IncompleteContactTableViewCell.className, bundle: nil), forCellReuseIdentifier: IncompleteContactTableViewCell.className)
    }
    
    func setupUIView(){
        title = "Incomplete Contacts"
        navigationController?.navigationBar.prefersLargeTitles = true
        deleteButton.makeCornerRadiusCircle()
        deleteButtonGradientLayer.colors = [UIColor.systemBackground.withAlphaComponent(0).cgColor,
                                            UIColor.systemBackground.withAlphaComponent(1).cgColor]

        deleteButtonGradientLayer.locations = [0, 1]
        deleteButtonGradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        deleteButtonGradientLayer.endPoint = CGPoint(x: 0, y: 0.5)

        deleteButtonGradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: deleteButton.superview!.bounds.height)

        // Add the gradient layer to the view's layer
        deleteButton.superview!.layer.insertSublayer(deleteButtonGradientLayer, at: 0)
    }

    func DeleteAlert(){
        let singularOrPurlarContact = viewModel.selectedContactSet.count > 1 ? ConstantString.contacts.rawValue : ConstantString.contact.rawValue

        let alertVC = UIAlertController(title: "Are you sure want to delete \(viewModel.selectedContactSet.count) \(singularOrPurlarContact)?", message: nil, preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: ConstantString.cancel.rawValue, style: .cancel) { action in
            logEvent(Event.IncompleteContactScreen.deleteCancel.rawValue, parameter: nil)

        }
        let deleteAction = UIAlertAction(title: ConstantString.delete.rawValue, style: .destructive) { _ in
            logEvent(Event.IncompleteContactScreen.deleteConfirmed.rawValue, parameter: ["deleted_count": self.viewModel.selectedContactSet.count])
            self.viewModel.deleteSelectedContacts()
        }

        alertVC.addAction(cancelAction)
        alertVC.addAction(deleteAction)

        self.present(alertVC, animated: true)
    }

    @objc func rightBarButtonPressed(){
        if viewModel.isAllSelected{
            logEvent(Event.IncompleteContactScreen.selectAll.rawValue, parameter: nil)
            viewModel.deselectAll()
        } else {
            logEvent(Event.IncompleteContactScreen.deselectAll.rawValue, parameter: nil)
            viewModel.selectAll()
        }
        tableView.reloadData()
    }
    
    func configureRightBarButton(){
        rightBarButtonItem = UIBarButtonItem(title: ConstantString.select.rawValue, style: .plain, target: self, action: #selector(rightBarButtonPressed))
        navigationItem.rightBarButtonItem = rightBarButtonItem
    }


    func setupSubscriber() {
        viewModel.$selectedContactSet.sink { [weak self] selectedContacts in
            logEvent(Event.IncompleteContactScreen.selectedCount.rawValue, parameter: ["count": selectedContacts.count])
            DispatchQueue.main.async {
                guard let self else { return }
                if selectedContacts.isEmpty {
                    self.deleteButton.isEnabled = false
                    self.deleteButton.backgroundColor  = .darkGray2
                } else {
                    self.deleteButton.isEnabled = true
                    self.deleteButton.backgroundColor = .darkBlue
                }
            }
        }.store(in: &cancelables)
        
        
        viewModel.$isAllSelected.sink { [weak self] isAllSelected in
            DispatchQueue.main.async {
                guard let self else { return }
                if isAllSelected{
                    self.rightBarButtonItem.title = ConstantString.deSelectAll.rawValue
                } else {
                    self.rightBarButtonItem.title = ConstantString.selectAll.rawValue
                }
            }
        }.store(in: &cancelables)

        viewModel.$showLoader.sink { [weak self] showLoader in
            guard let self else { return }
            showLoader ? showFullScreenLoader() : hideFullScreenLoader()
        }.store(in: &cancelables)

        viewModel.$inCompleteContacts.sink {[weak self] contacts in
            logEvent(Event.IncompleteContactScreen.count.rawValue, parameter: ["count": contacts.count])
            DispatchQueue.main.async { [weak self] in
                guard let self else {return}
                rightBarButtonItem.isEnabled = !contacts.isEmpty

                tableView.reloadData()
            }
        }.store(in: &cancelables)
    }
}

//MARK: - tableView Datasource & delegate
extension IncompleteContactViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.inCompleteContacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: IncompleteContactTableViewCell.className, for: indexPath) as! IncompleteContactTableViewCell
        
        let contact = viewModel.inCompleteContacts[indexPath.row]
        cell.isItemSelected = viewModel.selectedContactSet.contains(contact)
        cell.index = indexPath.row
        cell.contactView.configureContactView(contact: contact)
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

}


extension IncompleteContactViewController: IncompleteContactTableViewCellDelegate{
    func incompleteContactTableViewCell(cell: IncompleteContactTableViewCell, didSelectContact contact: CNContact?) {
        guard let contact else { return }
        let contactViewController = CNContactViewController(for: contact)
        contactViewController.allowsEditing = false
        contactViewController.allowsActions = true
        self.navigationController?.pushViewController(contactViewController, animated: true)
    }

    func incompleteContactTableViewCell(cell: IncompleteContactTableViewCell, checkButtonPressedAt index: Int) {
        viewModel.selectedContactAt(index: index)
    }
}
