//
//  HomeViewController.swift
//  CleanerApp
//
//  Created by manu on 06/11/23.
//

import UIKit

class FutureHomeViewController: UIViewController {

    //MARK: - varibles and properties
    var viewModel: FutureHomeViewModel!
    
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
        tableView.register(UINib(nibName: FutureHomeTableViewCell.identifier, bundle: nil), forCellReuseIdentifier: FutureHomeTableViewCell.identifier)
    }
    
    func setupViewModel(){
        viewModel = FutureHomeViewModel()
    }
    
    func setup(){
    
    }

}



extension FutureHomeViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.homeCells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FutureHomeTableViewCell.identifier, for: indexPath) as! FutureHomeTableViewCell
        cell.configureCell(homeCell: viewModel.homeCells[indexPath.row])
        return cell
    }
}

extension FutureHomeViewController: UITableViewDelegate{
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
            let vc = VideoCompressorHostingController()
            self.navigationController?.pushViewController(vc, animated: true)
        case .secretSpace:
            let vc = SecretSpaceViewController.customInit()
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
