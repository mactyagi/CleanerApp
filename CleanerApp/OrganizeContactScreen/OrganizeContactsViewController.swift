//
//  OrganizeContactsViewController.swift
//  CleanerApp
//
//  Created by Manu on 20/02/24.
//

import UIKit
import Combine
class OrganizeContactsViewController: UIViewController {

    //MARK: - IBOutlets
    @IBOutlet weak var duplicateCountLabel: UILabel!
    @IBOutlet weak var incompleteContactsCountLabel: UILabel!
    @IBOutlet weak var backupCountLabel: UILabel!
    @IBOutlet weak var allContactsCountLabel: UILabel!
    
    
    //MARK: - Variables
    var viewModel: OrganizeContactViewModel!
    private var cancelables: Set<AnyCancellable> = []
    
    
    //MARK: - lifecycles
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        setupViewModel()
    }

    
    //MARK: - Static Function
    static let identifier = "OrganizeContactsViewController"
    static func customInit() -> OrganizeContactsViewController{
        let vc = UIStoryboard.main.instantiateViewController(identifier: Self.identifier) as! Self
        return vc
    }

    //MARK: - IBActions
    @IBAction func duplicateButtonPressed(_ sender: UIButton) {
        let vc = DuplicateContactsViewController.customInit()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func inCompletContactButtonPressed(_ sender: UIButton) {
    }
    
    @IBAction func backUpButtonPressed(_ sender: UIButton) {
    }
    
    @IBAction func AllContactsButtonPressed(_ sender: UIButton) {
    }
    
    
    
    //MARK: - setup Functions
    func setupViewModel(){
        viewModel = OrganizeContactViewModel()
        setSubscribers()
    }
}



extension OrganizeContactsViewController{
    func setSubscribers(){
        viewModel.$contactsCount.sink { [weak self] count in
            DispatchQueue.main.async {
                guard let self else { return }
                self.allContactsCountLabel.text = "\(count)"
            }
        }.store(in: &cancelables)
        
        viewModel.$duplicateCount.sink { [weak self] count in
            DispatchQueue.main.async {
                guard let self else { return }
                self.duplicateCountLabel.text = "\(count)"
            }
        }.store(in: &cancelables)
        
        viewModel.$incompleteContactsCount.sink { [weak self] count in
            DispatchQueue.main.async {
                guard let self else { return }
                self.incompleteContactsCountLabel.text = "\(count)"
            }
        }.store(in: &cancelables)
    }
}
