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
    //MARK: - lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubscriber()
        setupTableView()
        setupUIView()
        configureRightBarButton()
    }
    
    //MARK: - customInit
    static let identifier = "IncompleteContactViewController"
    static func customInit(viewModel: IncompleteContactViewModel) -> IncompleteContactViewController{
        let vc = UIStoryboard.main.instantiateViewController(identifier: Self.identifier) as! Self
        vc.viewModel = viewModel
        return vc
    }

    //MARK: - IBAction
    @IBAction func deleteButtonPressed(_ sender: UIButton) {
        
    }


    //MARK: - Setup function
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "IncompleteContactTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
    }
    
    func setupUIView(){
        title = "Incomplete Contacts"
        navigationController?.navigationBar.prefersLargeTitles = true
        deleteButton.makeCornerRadiusCircle()
    }
    
    @objc func rightBarButtonPressed(){
        if viewModel.isAllSelected{
            viewModel.deselectAll()
            
        } else {
            viewModel.selectAll()
        }
        tableView.reloadData()
    }
    
    func configureRightBarButton(){
         rightBarButtonItem = UIBarButtonItem(title: "selectAll", style: .plain, target: self, action: #selector(rightBarButtonPressed))
        navigationItem.rightBarButtonItem = rightBarButtonItem
    }


    func setupSubscriber() {
        viewModel.$selectedContactSet.sink { [weak self] selectedContacts in
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
                    self.rightBarButtonItem.title = "Deselect All"
                } else {
                    self.rightBarButtonItem.title = "Select All"
                }
            }
        }.store(in: &cancelables)
    }
}

//MARK: - tableView Datasource & delegate
extension IncompleteContactViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.incompleteContacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! IncompleteContactTableViewCell
        
        let contact = viewModel.incompleteContacts[indexPath.row]
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

        if !contact.areKeysAvailable([CNContactViewController.descriptorForRequiredKeys()]) {
            do {
                let contact = try viewModel.contactStore.unifiedContact(withIdentifier: contact.identifier, keysToFetch: [CNContactViewController.descriptorForRequiredKeys()])
                let contactVC = CNContactViewController(for: contact)
                contactVC.delegate = self
                contactVC.hidesBottomBarWhenPushed = true
                contactVC.allowsEditing = false
                contactVC.allowsActions = false
                self.navigationController?.pushViewController(contactVC, animated: true)
            }
            catch {
                logError(error: error as NSError)
            }
        }
    }

    func incompleteContactTableViewCell(cell: IncompleteContactTableViewCell, checkButtonPressedAt index: Int) {
        viewModel.selectedContactAt(index: index)
    }
}
