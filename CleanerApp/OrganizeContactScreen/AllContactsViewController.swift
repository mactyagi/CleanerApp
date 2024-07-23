//
//  ContactsViewController.swift
//  CleanerApp
//
//  Created by Manukant Tyagi on 25/05/24.
//

import UIKit
import Combine

class AllContactsViewController: UIViewController, UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
            viewModel.setContacts()
                    return
                }
        viewModel.filterSectionBasedOnSearch(searchString: searchText)
    }
    

    //MARK: - Variables
    var viewModel: AllContactsVIewModel!
    let searchController = UISearchController()
    private var cancellables: Set<AnyCancellable> = []

    //MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    //MARK: - lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubscribers()
        setupSearchController()
        setupView()
        setupTableView()
        setupNavigationBar()
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
        tableView.dataSource = self
        tableView.delegate = self
    }

    func setupNavigationBar() {
        let rightBarButton = UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(selectButtonPressed))
        navigationItem.rightBarButtonItem = rightBarButton
    }

    @objc func selectButtonPressed() {
        viewModel.isSelectionMode = true
//        navigationItem.rightBarButtonItem = nil
        if #available(iOS 16.0, *) {
            navigationItem.backBarButtonItem?.isHidden = true
        } else {
            navigationItem.backBarButtonItem = nil
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "SelectAll", style: .plain, target: self, action: #selector(selectAllButtonTapped))
    }

    @objc func cancelButtonTapped() {
        viewModel.isSelectionMode = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(selectButtonPressed))
        if #available(iOS 16.0, *) {
            navigationItem.backBarButtonItem?.isHidden = false
            navigationItem.leftBarButtonItem = nil
        } else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backButtonTapped))
        }
    }


        @objc func backButtonTapped() {
            navigationController?.popViewController(animated: true)
        }



    @objc func selectAllButtonTapped() {

    }

}

extension AllContactsViewController {
    func setupSubscribers() {
        viewModel.$sectionTitles.sink { _ in
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }.store(in: &cancellables)

        viewModel.$isSelectionMode.sink { _ in
            self.viewModel.selectedContacts = []
            DispatchQueue.main.async {
                self.tableView.reloadData()
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
        if viewModel.isSelectionMode{
            if let contact = viewModel.contactsDictionary[viewModel.sectionTitles[indexPath.section]]?[indexPath.row]{
                if viewModel.selectedContacts.contains(contact){
                    viewModel.selectedContacts.remove(contact)
                }else {
                    viewModel.selectedContacts.insert(contact)
                }
            }
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        viewModel.sectionTitles
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        25
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }

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
