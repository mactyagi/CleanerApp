//
//  Setting View Screen.swift
//  CleanerApp
//
//  Created by Mac on 15/05/24.
//


import UIKit

class SettingViewController: UIViewController {

    var dataSource = ["Privacy Policy"]
    
    @IBOutlet weak var tableView: UITableView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
    }
    
    func setupNavigationView() {
        title = "Settings"
        navigationController?.navigationBar.prefersLargeTitles = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
        setupNavigationView()
    }
    
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(UINib(nibName: "SettingTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
    }
    
    func goToPrivacyPolicyViewController() {
        let vc = self.storyboard?.instantiateViewController(identifier: "PrivacyPolicyViewController") as! PrivacyPolicyViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension SettingViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SettingTableViewCell
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        goToPrivacyPolicyViewController()
    }
    

    
    
}
