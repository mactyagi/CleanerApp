//
//  CleanerViewController.swift
//  CleanerApp
//
//  Created by Manu on 23/12/23.
//

import UIKit

class CleanerViewController: UITableViewController {

    //MARK: - IBOutlets
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
    
    
    //MARK: - View Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    
    //MARK: - setup Functions
    func setupView(){
        infoImageView.makeCircle()
        addCornerRadius(10, views: EventView, contactCountView, mediaMemoryView)
        addCornerRadius(15, views: deviceInfoItemsView, progressMainView, calenderView, contactsView, photosView, howToCleanUpView)
        addCornerRadius(20, views: smartCleaningView)
        
        setupIcons()
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
}



// MARK: - Table view data source
extension CleanerViewController{
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }
}
