//
//  DuplicateContactsViewController.swift
//  CleanerApp
//
//  Created by Manu on 20/02/24.
//

import UIKit
import Combine
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }
    
    
    //MARK: - customInit
    static func customInit() -> Self{
        UIStoryboard.main.instantiateViewController(identifier: "DuplicateContactsViewController") as! Self
    }
    
    
    //MARK: - setup Function
    func setupTableView(){
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "DuplicateContactTableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
    }
    
    func setupViewModel(){
        viewModel = DuplicateContactsViewModel()
        setSubscriber()
    }
    
    func showAlertToMerge(at indexPath: IndexPath){
        let alertVC = UIAlertController(title: "Alert!", message: "Are you sure want to merge?", preferredStyle: .alert)
        let mergeAction = UIAlertAction(title: "Merge", style: .default) { _ in
            self.viewModel.mergeAndSaveAt(indexPath: indexPath)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
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
    }
}

extension DuplicateContactsViewController: DuplicateContactTableViewCellDelegate{
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
