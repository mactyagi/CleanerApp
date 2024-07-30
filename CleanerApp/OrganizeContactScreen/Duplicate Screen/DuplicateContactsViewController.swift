//
//  DuplicateContactsViewController.swift
//  CleanerApp
//
//  Created by Manu on 20/02/24.
//

import UIKit
import Combine
import Contacts
import ContactsUI
class DuplicateContactsViewController: UIViewController {


    var viewModel: DuplicateContactsViewModel!
    var cancellable: Set<AnyCancellable> = []
    
    
    //MARK: - IBOutlet
    @IBOutlet weak var tableView: UITableView!
    
    
    //MARK: - LifeCycles
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupViewModel()
        configureTitle()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logEvent(Event.DuplicateContactScreen.appear.rawValue, parameter: nil)
        tableView.reloadData()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        logEvent(Event.DuplicateContactScreen.disappear.rawValue, parameter: nil)
    }

    
    //MARK: - customInit
    static func customInit(viewModel: DuplicateContactsViewModel) -> Self{
        let vc = UIStoryboard.main.instantiateViewController(identifier: "DuplicateContactsViewController") as! Self
        vc.viewModel = viewModel
        return vc
    }
    
    
    //MARK: - setup Function
    func setupTableView(){
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "DuplicateContactTableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
    }
    
    func configureTitle(){
        title = "Duplicate Contacts"
    }
    
    func setupViewModel(){
        setSubscriber()
    }
    
    func showAlertToMerge(at indexPath: IndexPath){
        let alertVC = UIAlertController(title: "Alert!", message: "Are you sure want to merge?", preferredStyle: .alert)
        let mergeAction = UIAlertAction(title: "Merge", style: .default) { _ in
            logEvent(Event.DuplicateContactScreen.mergeConfirmed.rawValue, parameter: ["merge_count": self.viewModel.dataSource[indexPath.row].duplicatesContacts.count])
            self.viewModel.mergeAndSaveAt(indexPath: indexPath)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            logEvent(Event.DuplicateContactScreen.mergeCancel.rawValue, parameter: nil)
        }

        alertVC.addAction(mergeAction)
        alertVC.addAction(cancelAction)
        
        self.present(alertVC, animated: true)
    }
}


//MARK: - TableView Delegates and Data Sources
extension DuplicateContactsViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! DuplicateContactTableViewCell
        cell.configure(tuple: viewModel.dataSource[indexPath.row], indexPath: indexPath)
        cell.delegate = self
        
        return cell
    }
}


//MARK: - Set subscriber
extension DuplicateContactsViewController{
    func setSubscriber(){
        viewModel.$reloadAtIndex.sink { [weak self] index in
            DispatchQueue.main.async {
                guard let self else { return }
                if let index{
                    self.tableView.reloadRows(at: [index], with: .none)
                }else{
                    self.tableView.reloadData()
                }
            }
        }.store(in: &cancellable)

        viewModel.$dataSource.sink { items in
            logEvent(Event.DuplicateContactScreen.totalMergeItems.rawValue, parameter: ["count": items.count])
        }.store(in: &cancellable)
    }
}

extension DuplicateContactsViewController: DuplicateContactTableViewCellDelegate{
    func duplicateContactTableViewCell(_ cell: DuplicateContactTableViewCell, didContactSelected contact: CNContact?) {
        guard let contact else { return }
        if !contact.areKeysAvailable([CNContactViewController.descriptorForRequiredKeys()]) {

            if let contact = try? viewModel.contactStore.unifiedContact(withIdentifier: contact.identifier, keysToFetch: [CNContactViewController.descriptorForRequiredKeys()]) {
                let contactVC = CNContactViewController(forUnknownContact: contact)
    //                contactVC.delegate = self
                contactVC.hidesBottomBarWhenPushed = true
                contactVC.allowsEditing = false
                contactVC.allowsActions = false
                self.navigationController?.pushViewController(contactVC, animated: true)
            }else {
                let newContact = CNMutableContact()
                newContact.givenName = contact.givenName
                newContact.familyName = contact.familyName
                let contactVC = CNContactViewController(forUnknownContact: contact)
    //                contactVC.delegate = self
                contactVC.hidesBottomBarWhenPushed = true
                contactVC.allowsEditing = false
                contactVC.allowsActions = false
                self.navigationController?.pushViewController(contactVC, animated: true)
            }
        }
    }
    

    func duplicateContactTableViewCell(_ cell: UITableViewCell, mergeContactAt indexPath: IndexPath) {
        showAlertToMerge(at: indexPath)
    }
    
    func duplicateContactTableViewCell(_ cell: UITableViewCell, didChangeAt indexPath: IndexPath, viewIndex: Int, isSelected: Bool) {
        viewModel.dataSource[indexPath.row].duplicatesContacts[viewIndex].isSelected = isSelected
        viewModel.resetMergeContactAt(indexes: [indexPath.row])
    }
    
    func duplicateContactTableViewCell(_ cell: UITableViewCell, selectionAt indexPath: IndexPath, isAllSelected: Bool) {
        viewModel.resetSelectionAt(index: indexPath.row, isSelectedAll: isAllSelected)
    }
    
    
}
