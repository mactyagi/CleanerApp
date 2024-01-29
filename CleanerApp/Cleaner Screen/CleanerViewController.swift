//
//  CleanerViewController.swift
//  CleanerApp
//
//  Created by Manu on 23/12/23.
//

import UIKit
import Combine
import EventKit
class CleanerViewController: UIViewController {

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
    
    
        //MARK: - Variables
    private var cancelables: Set<AnyCancellable> = []
    private var viewModel: CleanerViewModel!
    
    //MARK: - View Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupViewModel()
        setupTapOnView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationAndTabBar(isScreenVisible: true)
        viewModel.startUpdatingDeivceInfo()
        viewModel.updateData()
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupNavigationAndTabBar(isScreenVisible: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.stopUpdatingDeviceInfo()
        setupNavigationAndTabBar(isScreenVisible: false)
    }
    
    
    
    //MARK: - static functions
    static func customInit() -> CleanerViewController{
        let vc = UIStoryboard.main.instantiateViewController(identifier: "CleanerViewController") as! CleanerViewController
        return vc
    }
   
    
    
    //MARK: - setup Functions
    func setupNavigationAndTabBar(isScreenVisible flag: Bool){
        navigationController?.navigationBar.isHidden = flag
        self.tabBarController?.tabBar.isHidden = !flag
    }
    
    func setupView(){
        scrollView.bounces = false
        infoImageView.makeCornerRadiusCircle()
        addCornerRadius(10, views: EventView, contactCountView, mediaMemoryView)
        addCornerRadius(15, views: deviceInfoItemsView, progressMainView, calenderView, contactsView, photosView, howToCleanUpView)
        addCornerRadius(20, views: smartCleaningView)
        
        setupIcons()
        let customFont = UIFont(name: "Avenir Next Demi Bold", size: 18.0)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: customFont!], for: .normal)
    }
    
    func setupIcons(){
        wifiIconView.imageView.image = UIImage(systemName: "wifi")!
        wifiIconView.contentView.backgroundColor = .systemTeal
        
        cpuIconView.imageView.image = UIImage.cpuIcon
        cpuIconView.contentView.backgroundColor = .systemPurple
        
        ramIconView.contentView.backgroundColor = .systemIndigo
        
        calenderIconView.imageView.image = UIImage(systemName: "calendar")
        calenderIconView.contentView.backgroundColor = .systemPink
        
        contactIconView.imageView.image = UIImage(systemName: "person.fill")
        contactIconView.contentView.backgroundColor = .systemPurple
        
        photosIconView.contentView.backgroundColor = .systemGreen
        photosIconView.imageView.image = UIImage(systemName: "photo.fill")
        
    }
    
    func addCornerRadius(_ radius: CGFloat, views: UIView ...){
        views.forEach { $0.layer.cornerRadius = radius }
    }
    
    
    func setupTapOnView(){
        let calendarTapGesture = UITapGestureRecognizer(target: self, action: #selector(calendarViewTapped))
        calenderView.addGestureRecognizer(calendarTapGesture)
        
        let galleryItemTapGesture = UITapGestureRecognizer(target: self, action: #selector(photoAndVideoTapped))
        photosView.addGestureRecognizer(galleryItemTapGesture)
    }
    
    @objc func calendarViewTapped(){
        navigationController?.pushViewController(CalendarViewController.customInit(), animated: true)
    }
    
    @objc func contactViewTapped(){
        
    }
    
    @objc func photoAndVideoTapped(){
        navigationController?.pushViewController(MediaViewController.customInit(), animated: true)
    }
    
}



// MARK: - Set subscribers and View Model
extension CleanerViewController{
    
    func setupViewModel(){
        let deviceManager = DeviceInfoManager()
        let eventStore = EKEventStore()
        viewModel = CleanerViewModel(deviceInfoManager: deviceManager, eventStore: eventStore)
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
        
        viewModel.$PhotosAndVideosCount.sink { [weak self] count in
            DispatchQueue.main.async {
                self?.mediaItemLabel.text = "Items: \(count)"
            }
            
        }.store(in: &cancelables)
        
        viewModel.$PhotosAndVideosSize.sink { [weak self] size in
            DispatchQueue.main.async {
                self?.mediaMemoryLabel.text = size.formatBytes()
            }
        }.store(in: &cancelables)
    }
}
