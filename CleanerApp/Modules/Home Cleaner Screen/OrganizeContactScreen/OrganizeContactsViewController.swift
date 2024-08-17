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
    
        setupViewModel()
    }


    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.getData()
        navigationController?.navigationBar.prefersLargeTitles = false
        setupNavigationAndTabBar(isScreenVisible: false)
    }

    
    //MARK: - Static Function
    static func customInit(viewModel: OrganizeContactViewModel) -> OrganizeContactsViewController{
        let vc = UIStoryboard.contact.instantiateViewController(identifier: Self.className) as! Self
        vc.viewModel = viewModel
        return vc
    }

    //MARK: - IBActions
    @IBAction func duplicateButtonPressed(_ sender: UIButton) {
        let duplicateViewModel = DuplicateContactsViewModel(contactStore: viewModel.contactStore)
        let vc = DuplicateContactsViewController.customInit(viewModel: duplicateViewModel)
        navigationController?.pushViewController(vc, animated: true)
    }
    

    @IBAction func inCompletContactButtonPressed(_ sender: UIButton) {
        let viewModel = IncompleteContactViewModel(contactStore: viewModel.contactStore)
        let vc = IncompleteContactViewController.customInit(viewModel: viewModel)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func backUpButtonPressed(_ sender: UIButton) {

    }
    
    @IBAction func AllContactsButtonPressed(_ sender: UIButton) {
        let allContactViewModel = AllContactsVIewModel(contactStore: viewModel.contactStore)
        let vc = AllContactsViewController.customInit(viewModel: allContactViewModel)
        
//        let vc = TestViewController.customInit()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    
    //MARK: - setup Functions
    func setupViewModel(){
        setSubscribers()
    }
}



extension OrganizeContactsViewController{
    func setSubscribers(){
        viewModel.$allContacts.sink { [weak self] contacts in
            DispatchQueue.main.async {
                guard let self else { return }
                self.allContactsCountLabel.text = "\(contacts.count)"
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

        viewModel.$incompleteContacts.sink { [weak self] incompletContacts in
            DispatchQueue.main.async {
                guard let self else { return }
                self.incompleteContactsCountLabel.text = "\(incompletContacts.count)"
            }
        }.store(in: &cancelables)
    }
}
