//
//  ContactsViewController.swift
//  CleanerApp
//
//  Created by Manukant Tyagi on 25/05/24.
//

import UIKit
import Combine
import ContactsUI
import AlertToast

class AllContactsViewController: UIViewController, UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
            viewModel.setContacts()
                    return
                }
        logEvent(Event.AllContactScreen.search.rawValue, parameter: nil)
        viewModel.filterSectionBasedOnSearch(searchString: searchText)
    }



    //MARK: - Variables
    var viewModel: AllContactsVIewModel!
    let searchController = UISearchController()
    private var cancellables: Set<AnyCancellable> = []
    private var rightBarButtonItem: UIBarButtonItem?
    private var deleteButtonGradientLayer = CAGradientLayer()

    //MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var deleteButton: UIButton!

    //

    @IBAction func deleteButtonPressed(_ sender: UIButton) {
        logEvent(Event.AllContactScreen.deletePressed.rawValue, parameter: nil)
        DeleteAlert()
    }
    
    //MARK: - lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubscribers()
        setupSearchController()
        setupView()
        setupTableView()
        setupNavigationBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logEvent(Event.AllContactScreen.appear.rawValue, parameter: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        logEvent(Event.AllContactScreen.disAppear.rawValue, parameter: nil)
    }

    //MARK: - overrride functions
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            self.deleteButtonGradientLayer.colors = [UIColor.systemBackground.withAlphaComponent(0.2).cgColor,
                                   UIColor.systemBackground.withAlphaComponent(1).cgColor]
        }
    }

    //MARK: - customInit
    static func customInit(viewModel: AllContactsVIewModel) -> Self {
        let vc = UIStoryboard.main.instantiateViewController(withIdentifier: Self.className) as! Self
        vc.viewModel = viewModel
        return vc
    }

    //MARK: - Setup
    func setupView() {
        navigationController?.navigationBar.prefersLargeTitles = false
        title = "Contacts"
        deleteButton.makeCornerRadiusCircle()
        deleteButtonGradientLayer.colors = [UIColor.systemBackground.withAlphaComponent(0.2).cgColor,
                                            UIColor.systemBackground.withAlphaComponent(1).cgColor]

        deleteButtonGradientLayer.locations = [0, 0.5]
        deleteButtonGradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        deleteButtonGradientLayer.endPoint = CGPoint(x: 0, y: 1)

        deleteButtonGradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: deleteButton.superview!.bounds.height)

        // Add the gradient layer to the view's layer
        deleteButton.superview!.layer.insertSublayer(deleteButtonGradientLayer, at: 0)
    }

    func setupSearchController() {
        searchController.searchResultsUpdater = self
                searchController.obscuresBackgroundDuringPresentation = false
                searchController.searchBar.placeholder = "Name, number, company, or email"
                searchController.searchBar.delegate = self
                searchController.hidesNavigationBarDuringPresentation = false
                navigationItem.searchController = searchController
                navigationItem.hidesSearchBarWhenScrolling = false
            searchController.hidesNavigationBarDuringPresentation = true
                searchController.searchBar.delegate = self
                definesPresentationContext = true
    }

    func setupTableView() {
        tableView.sectionHeaderTopPadding = 0
        tableView.dataSource = self
        tableView.delegate = self
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 90, right: 0)
        tableView.register(UINib(nibName: AllContactsTableViewCell.className, bundle: nil), forCellReuseIdentifier: AllContactsTableViewCell.className)
    }

    func setupNavigationBar() {
        rightBarButtonItem = UIBarButtonItem(title: ConstantString.select.rawValue, style: .plain, target: self, action: #selector(selectButtonPressed))
        navigationItem.rightBarButtonItem = rightBarButtonItem
    }

    func DeleteAlert(){
        let singularOrPurlarContact = viewModel.selectedContacts.count > 1 ? ConstantString.contacts.rawValue : ConstantString.contact.rawValue

        let alertVC = UIAlertController(title: "Are you sure want to delete \(viewModel.selectedContacts.count) \(singularOrPurlarContact)?", message: nil, preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: ConstantString.cancel.rawValue, style: .cancel) { action in

            logEvent(Event.AllContactScreen.deletePressed.rawValue, parameter: nil)
        }
        let deleteAction = UIAlertAction(title: ConstantString.delete.rawValue, style: .destructive) { _ in
            logEvent(Event.AllContactScreen.deleteConfirmed.rawValue, parameter: ["count": self.viewModel.selectedContacts.count])
            self.viewModel.deleteSelectedContacts()


        }

        alertVC.addAction(cancelAction)
        alertVC.addAction(deleteAction)

        self.present(alertVC, animated: true)
    }

    @objc func selectButtonPressed() {
        viewModel.isSelectionMode = true
        logEvent(Event.AllContactScreen.select.rawValue, parameter: nil)

    }

    @objc func cancelButtonTapped() {
        viewModel.isSelectionMode = false

    }


        @objc func backButtonTapped() {
            navigationController?.popViewController(animated: true)
        }



    @objc func selectAllButtonTapped() {

        if viewModel.isAllSelected {
            logEvent(Event.AllContactScreen.deselectAll.rawValue, parameter: nil)
        }else {
            logEvent(Event.AllContactScreen.selectAll.rawValue, parameter: nil)
        }
        viewModel.isAllSelected ? viewModel.deselectAll() : viewModel.selectAll()
        tableView.reloadData()
    }

}

extension AllContactsViewController {
    func setupSubscribers() {
        viewModel.$allContacts.sink { contacts in
            logEvent(Event.AllContactScreen.allContactCount.rawValue, parameter: ["count": contacts.count])
        }.store(in: &cancellables)

        viewModel.$sectionTitles.sink { sectionTitles in
            DispatchQueue.main.async {
                self.rightBarButtonItem?.isEnabled = !sectionTitles.isEmpty
                self.tableView.reloadData()
            }
        }.store(in: &cancellables)

        viewModel.$isSelectionMode.sink { [weak self] isSelectedMode in
            guard let self else { return }
            if isSelectedMode {
                if #available(iOS 16.0, *) {
                    navigationItem.backBarButtonItem?.isHidden = true
                } else {
                    navigationItem.backBarButtonItem = nil
                }
                navigationItem.leftBarButtonItem = UIBarButtonItem(title: ConstantString.cancel.rawValue, style: .plain, target: self, action: #selector(cancelButtonTapped))
                rightBarButtonItem = UIBarButtonItem(title: ConstantString.selectAll.rawValue, style: .plain, target: self, action: #selector(selectAllButtonTapped))
                navigationItem.rightBarButtonItem = rightBarButtonItem

            }else {
                viewModel.deselectAll()
                rightBarButtonItem = UIBarButtonItem(title: ConstantString.select.rawValue, style: .plain, target: self, action: #selector(selectButtonPressed))
                navigationItem.rightBarButtonItem = rightBarButtonItem
                if #available(iOS 16.0, *) {
                    navigationItem.backBarButtonItem?.isHidden = false
                    navigationItem.leftBarButtonItem = nil
                } else {
                    navigationItem.leftBarButtonItem = UIBarButtonItem(title: ConstantString.back.rawValue, style: .plain, target: self, action: #selector(backButtonTapped))
                }
            }

            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }.store(in: &cancellables)

        viewModel.$selectedContacts.sink {[weak self] selectedContacts in
            guard let self else { return }
            logEvent(Event.AllContactScreen.selectedCount.rawValue, parameter: nil)
            if selectedContacts.isEmpty {
                self.deleteButton.isEnabled = false
                self.deleteButton.backgroundColor  = .darkGray2
            } else {
                self.deleteButton.isEnabled = true
                self.deleteButton.backgroundColor = .darkBlue
            }

        }.store(in: &cancellables)

        viewModel.$isAllSelected.sink {[weak self] isAllSelected in
            guard let self else { return }
            if isAllSelected{
                self.rightBarButtonItem?.title = ConstantString.deSelectAll.rawValue
            } else {
                self.rightBarButtonItem?.title = ConstantString.selectAll.rawValue
            }

            
        }.store(in: &cancellables)


        viewModel.$showLoader.sink { [weak self] showLoader in
            DispatchQueue.main.async {
                guard let self else { return }
                showLoader ? self.showFullScreenLoader() : self.hideFullScreenLoader()
            }
        }.store(in: &cancellables)

    }
}

extension AllContactsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.sectionTitles.count
    }


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.contactsDictionary[viewModel.sectionTitles[section]]!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AllContactsTableViewCell.className, for: indexPath) as! AllContactsTableViewCell
        if let contact = viewModel.contactsDictionary[viewModel.sectionTitles[indexPath.section]]?[indexPath.row]{
            if viewModel.isSelectionMode{
                if viewModel.selectedContacts.contains(contact){
                    cell.configureContact(contact: contact, isSelected: true)
                }else {
                    cell.configureContact(contact: contact, isSelected: false)
                }
            }else {
                cell.configureContact(contact: contact, isSelected: nil)
            }
        }



        return cell
    }


    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let contact = viewModel.contactsDictionary[viewModel.sectionTitles[indexPath.section]]?[indexPath.row] else { return }
        if viewModel.isSelectionMode{

            vibrate()
                viewModel.selectedContact(contact)
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }else{
            let keysToFetch = [CNContactViewController.descriptorForRequiredKeys()]
            let contactViewController = CNContactViewController(for: contact)
            contactViewController.allowsEditing = false
            contactViewController.allowsActions = true
            self.navigationController?.pushViewController(contactViewController, animated: true)
        }
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        viewModel.sectionTitles
    }

//    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        10
//    }
//    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
//        .leastNormalMagnitude
//    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }

    

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        let headerView = UIView()
        headerView.backgroundColor = UIColor.lightGrayAndDarkGray2

        let label = UILabel()
        label.font = .avenirNext(ofSize: 17, weight: .regular)
        headerView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 10),
            label.centerXAnchor.constraint(equalTo: headerView.centerXAnchor)
        ])
        label.text = viewModel.sectionTitles[section]
        label.textColor = .label
        return headerView
    }
}


extension AllContactsViewController: UISearchBarDelegate {

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
//        navigationController?.navigationBar.isHidden = true
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
//        navigationController?.navigationBar.isHidden = false
    }
}
