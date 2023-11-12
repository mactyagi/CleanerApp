//
//  HomeViewController.swift
//  CleanerApp
//
//  Created by manu on 06/11/23.
//

import UIKit

class HomeViewController: UIViewController {

    //MARK: - varibles and properties
    
    //MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    //MARK: - LifeCyclea
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    func setupTableView(){
        tableView.dataSource = self
    }

}



extension HomeViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        <#code#>
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        <#code#>
    }
    
    
}
