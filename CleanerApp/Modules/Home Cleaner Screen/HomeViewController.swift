//
//  HomeViewController.swift
//  CleanerApp
//
//  Created by Manu on 23/12/23.
//

import UIKit
import SwiftUI
import Combine
import EventKit
import Firebase
import Contacts
class HomeViewController: UIViewController {

    //MARK: - IBOutlets
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var usedCPULabel: UILabel!
    @IBOutlet weak var availableRAMLabel: UILabel!
    @IBOutlet weak var downloadLabel: UILabel!
    @IBOutlet weak var deviceInfoItemsView: UIView!
    @IBOutlet weak var howToCleanUpView: UIView!
    @IBOutlet weak var contactCountView: UIView!
    @IBOutlet weak var EventView: UIView!
    @IBOutlet weak var telegramIconView: IconView!
    @IBOutlet weak var mediaMemoryView: UIView!
    @IBOutlet weak var mediaMemoryLabel: UILabel!
    @IBOutlet weak var mediaItemLabel: UILabel!
    @IBOutlet weak var photosView: UIView!
    @IBOutlet weak var contactsLabel: UILabel!
    @IBOutlet weak var EventsLabel: UILabel!
    @IBOutlet weak var contactsView: UIView!
    @IBOutlet weak var calenderView: UIView!
    @IBOutlet weak var storageUsedLabel: UILabel!
    @IBOutlet weak var totalStorageLabel: UILabel!
    @IBOutlet weak var smartCleaningView: UIView!
    @IBOutlet weak var progressMainView: UIView!
    @IBOutlet weak var infoImageView: UIImageView!
    @IBOutlet weak var cpuIconView: IconView!
    @IBOutlet weak var ramIconView: IconView!
    @IBOutlet weak var wifiIconView: IconView!
    @IBOutlet weak var calenderIconView: IconView!
    @IBOutlet weak var contactIconView: IconView!
    @IBOutlet weak var photosIconView: IconView!
    @IBOutlet weak var whatsAppIconView: IconView!
    @IBOutlet weak var viberIconView: IconView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progressLabel: UILabel!
    
    
        //MARK: - Variables
    private var cancelables: Set<AnyCancellable> = []
    private var viewModel: HomeViewModel!
    private var progressBar: CircularProgressBarView?
    
    //MARK: - View Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        logEvent(Event.HomeScreen.loaded.rawValue, parameter: nil)
        setupView()
        setupViewModel()
        setupTapOnView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationAndTabBar(isScreenVisible: true)
        viewModel.updateData()
        NotificationCenter.default.addObserver(self, selector: #selector(progressFractionCompleted(notification:)), name: Notification.Name.updateData, object: nil)
  
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logEvent(Event.HomeScreen.appear.rawValue, parameter: nil)
        startFetchingAnimation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.stopUpdatingDeviceInfo()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        logEvent(Event.HomeScreen.disAppear.rawValue, parameter: nil)
    }
    
    
    
    //MARK: - static functions
    static func customInit() -> HomeViewController{
        let vc = UIStoryboard.home.instantiateViewController(identifier: HomeViewController.className) as! HomeViewController
        return vc
    }
   
    
    
    //MARK: - setup Functions
    
    
    @objc func progressFractionCompleted(notification: Notification) {
        viewModel.fetchPhotoAndvideosCountAndSize()
    }
    
    func setupView(){
        scrollView.bounces = false
        infoImageView.makeCornerRadiusCircle()
        addCornerRadius(10, views: EventView, contactCountView, mediaMemoryView)
        addCornerRadius(15, views: deviceInfoItemsView, progressMainView, calenderView, contactsView, photosView, howToCleanUpView)
        addCornerRadius(20, views: smartCleaningView)
        
        setupIcons()

        let customFont =  UIFont.avenirNext(ofSize: 18, weight: .semibold)
//        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: customFont!], for: .normal)
        setupProgressBar()
    }
    
    func startFetchingAnimation() {
            UIView.animate(withDuration: 0.5, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
                self.progressLabel.alpha = 0.3
            }) { a in
                self.progressLabel.alpha = 1
            }
        }
    

    
    
    func setupProgressBar(){
        progressBar = CircularProgressBarView(frame: CGRect(x: 0, y: 0, width: progressMainView.bounds.width, height: progressMainView.bounds.width))
        print(progressMainView.bounds.width)
        print(progressMainView.bounds.size.width)
        guard let progressBar else { return }
        progressBar.setProgress(0)
        progressMainView.addSubview(progressBar)
        
        
    }
    
    func setupIcons(){
        wifiIconView.imageView.image = UIImage(systemName: "wifi")!
        wifiIconView.contentView.backgroundColor = .systemTeal
        
        cpuIconView.imageView.image = UIImage.cpuIcon
        cpuIconView.contentView.backgroundColor = .systemPurple
        
        ramIconView.contentView.backgroundColor = .systemIndigo
        ramIconView.imageView.image = UIImage.ramIcon
        
        calenderIconView.imageView.image = UIImage(systemName: "calendar")
        calenderIconView.contentView.backgroundColor = .systemPink
        
        contactIconView.imageView.image = UIImage(systemName: "person.fill")
        contactIconView.contentView.backgroundColor = .systemPurple
        
        photosIconView.contentView.backgroundColor = .systemGreen
        photosIconView.imageView.image = UIImage(systemName: "photo.fill")
        
        telegramIconView.imageView.image = UIImage.telegramIcon
        telegramIconView.contentView.backgroundColor = .darkBlue
        
        whatsAppIconView.imageView.image = UIImage.whatsappIcon
        whatsAppIconView.contentView.backgroundColor = UIColor.systemGreen
        
        viberIconView.imageView.image = UIImage.viberIcon
        viberIconView.contentView.backgroundColor = .systemPurple
        
    }
    
    func addCornerRadius(_ radius: CGFloat, views: UIView ...){
        views.forEach { $0.layer.cornerRadius = radius }
    }
    
    
    func setupTapOnView(){
        let calendarTapGesture = UITapGestureRecognizer(target: self, action: #selector(calendarViewTapped))
        calenderView.addGestureRecognizer(calendarTapGesture)
        
        let galleryItemTapGesture = UITapGestureRecognizer(target: self, action: #selector(photoAndVideoTapped))
        photosView.addGestureRecognizer(galleryItemTapGesture)
        
        let contactTapGesture = UITapGestureRecognizer(target: self, action: #selector(contactViewTapped))
        let smartCleaningTapGesture = UITapGestureRecognizer(target: self, action: #selector(smartCleaningViewTapped))
        contactsView.addGestureRecognizer(contactTapGesture)
        smartCleaningView.addGestureRecognizer(smartCleaningTapGesture)
    }
    
    @objc func calendarViewTapped(){
        logEvent(Event.HomeScreen.tapCalendar.rawValue, parameter: nil)
        let designSelector = CalendarDesignSelector()
        let hostingController = UIHostingController(rootView: designSelector)
        hostingController.title = "Calendar"
        hostingController.hidesBottomBarWhenPushed = true
        // Show navigation bar (it's hidden on Home screen)
        navigationController?.navigationBar.isHidden = false
        navigationController?.pushViewController(hostingController, animated: true)
    }
    
    @objc func contactViewTapped(){
        let store = CNContactStore()
        logEvent(Event.HomeScreen.tapContacts.rawValue, parameter: nil)
        store.requestAccess(for: .contacts) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    let organizeViewModel = OrganizeContactViewModel(contactStore: self.viewModel.contactStore)
                    self.navigateToOrganizeContactsSwiftUI(viewModel: organizeViewModel)
                } else {
                    self.goToSettingAlertVC(message: "In order to find duplicate and empty contacts, the app needs an access to contacts.")
                }
            }
        }
    }
    
    @objc func smartCleaningViewTapped(){
        logEvent(Event.HomeScreen.tapSmartCleaning.rawValue, parameter: nil)
        let vc = ComingSoonViewController.customInit()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func photoAndVideoTapped(){
        logEvent(Event.HomeScreen.tapPhotos.rawValue, parameter: nil)
        if viewModel.photosAndVideosSize != nil{
            navigationController?.pushViewController(MediaScreenHostingController(), animated: true)
        }else{
            goToSettingAlertVC(message: "Allow the app access to Photos. No files will be deleted without your permission.")
        }
        
    }
    
    func goToSettingAlertVC(message: String){
        let alertVc = UIAlertController(title: "Access Needed", message: message, preferredStyle: .alert)

        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel)
        let goToSettingAction = UIAlertAction(title: "Go to Settings", style: .default) { action in
            let url = URL(string:UIApplication.openSettingsURLString)
                if UIApplication.shared.canOpenURL(url!){
                    UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                }
        }

        alertVc.addAction(cancelButton)
        alertVc.addAction(goToSettingAction)

        self.present(alertVc, animated: true)
    }

    func navigateToOrganizeContactsSwiftUI(viewModel: OrganizeContactViewModel) {
        Task {
            // Load data
            await viewModel.getData()
        }
        

        let swiftUIView = OrganizeContactsView(
            viewModel: viewModel,
            onDuplicatesTapped: { [weak self] in
                self?.navigateToDuplicateContacts(viewModel: viewModel)
            },
            onIncompleteTapped: { [weak self] in
                self?.navigateToIncompleteContacts(viewModel: viewModel)
            },
            onBackupTapped: {
                // Backup functionality - coming soon
            },
            onAllContactsTapped: { [weak self] in
                self?.navigateToAllContacts(viewModel: viewModel)
            }
        )
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.title = "Contacts"
        hostingController.hidesBottomBarWhenPushed = true
        // Show navigation bar (it's hidden on Home screen)
        navigationController?.navigationBar.isHidden = false
        navigationController?.pushViewController(hostingController, animated: true)
    }

    private func navigateToDuplicateContacts(viewModel: OrganizeContactViewModel) {
        let duplicateViewModel = DuplicateContactsViewModel(contactStore: viewModel.contactStore)
        let swiftUIView = DuplicateContactsViewDesign(viewModel: duplicateViewModel)
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.title = "Duplicate Contacts"
        hostingController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(hostingController, animated: true)
    }

    private func navigateToIncompleteContacts(viewModel: OrganizeContactViewModel) {
        let incompleteViewModel = IncompleteContactViewModel(contactStore: viewModel.contactStore)
        let swiftUIView = IncompleteContactView(viewModel: incompleteViewModel)
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(hostingController, animated: true)
    }

    private func navigateToAllContacts(viewModel: OrganizeContactViewModel) {
        let allContactViewModel = AllContactsVIewModel(contactStore: viewModel.contactStore)
        let swiftUIView = AllContactsView(viewModel: allContactViewModel)
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(hostingController, animated: true)
    }

}



// MARK: - Set subscribers and View Model
extension HomeViewController{
    
    func setupViewModel(){
        let deviceManager = DeviceInfoManager()
        viewModel = HomeViewModel(deviceInfoManager: deviceManager, contactStore: CNContactStore())
        setSubscribers()
    }
    
    func setSubscribers(){
        viewModel.$availableRAM.sink { [weak self] availableRAM in
            guard let self else { return }
            DispatchQueue.main.async {
                self.availableRAMLabel.text = availableRAM.formatBytes()
            }
        }.store(in: &cancelables)
        
        
        viewModel.$eventsCount.sink { [weak self] count in
                DispatchQueue.main.async {
                    if let count, let reminderCount = self?.viewModel.reminderCount {
                        self?.EventsLabel.text = "Events: \(count + reminderCount)"
                    }else{
                        self?.EventsLabel.text = "Give Access"
                    }
                }
            } .store(in: &cancelables)
        
        
        viewModel.$reminderCount.sink { [weak self] count in
                DispatchQueue.main.async {
                    if let count, let eventCount = self?.viewModel.eventsCount {
                        self?.EventsLabel.text = "Events: \(count + eventCount)"
                    }else{
                        self?.EventsLabel.text = "Give Access"
                    }
                    
                }
            } .store(in: &cancelables)
        
        viewModel.$contactsCount.sink { [weak self] count in
            DispatchQueue.main.async {
                guard let self else { return }
                if let count{
                    self.contactsLabel.text = "Contacts: \(count)"
                }else{
                    self.contactsLabel.text = "Give Access"
                }
            }
        }.store(in: &cancelables)
        
        viewModel.$photosAndVideosCount.sink { [weak self] count in
            DispatchQueue.main.async {
                self?.mediaItemLabel.text = "Items: \(count)"
            }
            
        }.store(in: &cancelables)
        
        viewModel.$photosAndVideosSize.sink { [weak self] size in
            DispatchQueue.main.async {
                if let size{
                    self?.mediaMemoryLabel.text = size.formatBytes()
                }else{
                    self?.mediaMemoryLabel.text = "Give Access"
                }
                
            }
        }.store(in: &cancelables)
        
        viewModel.$usedStorage.sink { [weak self] usedStorage in
            DispatchQueue.main.async {
                guard let self else { return }
                self.storageUsedLabel.text = usedStorage.formatBytes()
                logEvent(Event.HomeScreen.storageInfo.rawValue, parameter: ["info": "usedStorage:\(usedStorage.formatBytes()), totalStorage: \(self.viewModel.totalStorage.formatBytes())"])
                
                let progress = Float(usedStorage) / Float(self.viewModel.totalStorage)
                if progress > 0{  // some time progress comes NaN
                    self.progressBar?.setProgress(Float(progress))
                }else{
                    self.progressBar?.progress = 0
                }
                
            }
        }.store(in: &cancelables)
        
        
        viewModel.$totalStorage.sink { [weak self] totalStorage in
            DispatchQueue.main.async {
                self?.totalStorageLabel.text = "of \(totalStorage.formatBytesWithRoundOff())"
            }
        }.store(in: &cancelables)
        
        
        viewModel.$progress.sink { progress in
            DispatchQueue.main.async {
                self.progressView.setProgress(progress, animated: true)
                print("** \(progress * 100)%")
                
                self.progressView.isHidden = progress == 1
                self.progressLabel.isHidden = progress == 1
                
            }
        }.store(in: &cancelables)
    }
}
