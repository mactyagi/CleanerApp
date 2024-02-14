//
//  SecretSpaceViewController.swift
//  CleanerApp
//
//  Created by manu on 15/11/23.
//

import UIKit

class SecretSpaceViewController: UIViewController {

    //MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    //MARK: - variables
    var tableDataSource: [[SecretSpaceCellType]] = [[.SecretAlbum, .SecretContacts], [.SetPasscode]]
    
    //MARK: - Lifecycles
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
        //MARK: - Static varible and functions
    static let identifier = "SecretSpaceViewController"
    static func customInit() -> SecretSpaceViewController{
        let vc = UIStoryboard(name: "SecretSpace", bundle: nil).instantiateViewController(withIdentifier: identifier) as! SecretSpaceViewController
        return vc
    }
    
    //MARK: - func
    func setupTableView(){
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: FutureHomeTableViewCell.identifier, bundle: nil), forCellReuseIdentifier: FutureHomeTableViewCell.identifier)
    }
}


extension SecretSpaceViewController: UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        tableDataSource.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableDataSource[section].count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "Protection"
        }
        return ""
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FutureHomeTableViewCell.identifier, for: indexPath) as! FutureHomeTableViewCell
        let secretCell = tableDataSource[indexPath.section][indexPath.row]
        cell.configureCell(secretCell: secretCell.cell)
        return cell
    }
    
}


extension SecretSpaceViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellType = tableDataSource[indexPath.section][indexPath.row]
        switch cellType{
        case .SecretAlbum:
            let vc = SecretAlbumViewController.customInit()
            navigationController?.pushViewController(vc, animated: true)
        case .SecretContacts:
            break
        case .SetPasscode:
            break
        }
    }
}
