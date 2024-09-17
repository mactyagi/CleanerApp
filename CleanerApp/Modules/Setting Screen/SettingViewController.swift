//
//  Setting View Screen.swift
//  CleanerApp
//
//  Created by Mac on 15/05/24.
//


import UIKit

class SettingViewController: UIViewController {

    var dataSource: [SettingType] = SettingType.allCases
    
    @IBOutlet weak var tableView: UITableView!
    
    
    //MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
        setupNavigationView()
    }
    
    
    //MARK: - static functions
    static func customInit() -> Self {
        UIStoryboard.setting.instantiateViewController(withIdentifier: Self.className) as! Self
    }

    //MARK: - private functions
    private func setupNavigationView() {
        title = "Settings"
//        navigationController?.navigationBar.isHidden = true
        navigationController?.navigationBar.prefersLargeTitles = true
    }


    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(UINib(nibName: "SettingTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
    }
    
    func goToPrivacyPolicyViewController() {
        let vc = self.storyboard?.instantiateViewController(identifier: PrivacyPolicyViewController.className) as! PrivacyPolicyViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension SettingViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SettingTableViewCell
        let model = dataSource[indexPath.row].model
        cell.titleLabel.text = model.title
        cell.subtitleLabel.text = model.subTitle
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        goToPrivacyPolicyViewController()
    }
    

    
    
}
