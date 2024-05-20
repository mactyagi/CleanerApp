//
//  IncompleteContactViewController.swift
//  CleanerApp
//
//  Created by Manu on 06/03/24.
//

import UIKit

class IncompleteContactViewController: UIViewController {

    //MARK: - IBOutlets
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    //MARK: - Variables
    var viewModel: IncompleteContactViewModel!

    //MARK: - lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    }

}

//MARK: - tableView Datasource & delegate
extension IncompleteContactViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.incompleteContacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }


}
