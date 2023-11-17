//
//  HomeViewController.swift
//  CleanerApp
//
//  Created by manu on 06/11/23.
//

import UIKit

class HomeViewController: UIViewController {

    //MARK: - varibles and properties
    var viewModel: HomeViewModel!
    
    //MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    //MARK: - LifeCyclea
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupViewModel()
    }
    
    //MARK: - functions
    func setupTableView(){
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: HomeTableViewCell.identifier, bundle: nil), forCellReuseIdentifier: HomeTableViewCell.identifier)
    }
    
    func setupViewModel(){
        viewModel = HomeViewModel()
    }
    
    func setup(){
    
    }

}



extension HomeViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.homeCells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HomeTableViewCell.identifier, for: indexPath) as! HomeTableViewCell
        cell.configureCell(homeCell: viewModel.homeCells[indexPath.row])
        return cell
    }
}

extension HomeViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedCell = viewModel.homeCells[indexPath.row]
        switch selectedCell.cellType{
        case .battery:
            break
        case .speedTest:
            break
        case .widgetCell:
            break
        case .videoCompressor:
            let vc = VideoCompressorViewController.initWith()
            self.navigationController?.pushViewController(vc, animated: true)
        case .secretSpace:
            let vc = SecretSpaceViewController.customInit()
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
