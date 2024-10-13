//
//  CalenderViewController.swift
//  CleanerApp
//
//  Created by Manu on 24/12/23.
//

import UIKit
import EventKit
import Combine
class CalendarViewController: UIViewController {

    //MARK: - IBOutlet
    @IBOutlet weak var deleteButtonSuperView: UIView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var settingView: UIView!
    
    @IBOutlet weak var settingMainLabel: UILabel!
    @IBOutlet weak var settingNoteLabel: UILabel!
    //MARK: - Properties
    var viewModel: CalendarViewModel!
    private var cancelables: Set<AnyCancellable> = []
    private var rightBarButtonItem: UIBarButtonItem!
    private var deleteButtonGradientLayer = CAGradientLayer()
    //MARK: - lifecycles
    override func viewDidLoad() {
        super.viewDidLoad()
        logEvent(Event.CalendarScreen.loaded.rawValue, parameter: nil)
        setupViewModel()
        configureRightBarButton()
        setupViews()
        configureTitle()
        setupTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logEvent(Event.CalendarScreen.appear.rawValue, parameter: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationAndTabBar(isScreenVisible: false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        logEvent(Event.CalendarScreen.disappear.rawValue, parameter: nil)
    }
    
    //MARK: - override functions
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            self.deleteButtonGradientLayer.colors = [UIColor.systemBackground.withAlphaComponent(0).cgColor,
                                   UIColor.systemBackground.withAlphaComponent(1).cgColor]
        }
    }

    //MARK: - static function and properties
    static func customInit() -> Self{
        UIStoryboard.calendar.instantiateViewController(withIdentifier: Self.className) as! Self
    }
    
    @IBAction func deleteButtonPressed(_ sender: UIButton) {
        logEvent(Event.CalendarScreen.deleteButtonPressed.rawValue, parameter: ["count": viewModel.totalSelectedCount])
        DeleteAlert()
    }
    
  
    @IBAction func goToSettingButtonPressed(){
        logEvent(Event.CalendarScreen.goToSettingButtonPressed.rawValue, parameter: nil)
        let url = URL(string:UIApplication.openSettingsURLString)
            if UIApplication.shared.canOpenURL(url!){
                UIApplication.shared.open(url!, options: [:], completionHandler: nil)
            }
    }
    
    @IBAction func SegmentControlButtonPressed(_ sender: UISegmentedControl) {
        viewModel.updateValueFor(segment: SegmentType(rawValue: sender.selectedSegmentIndex)!)
    }
    
    //MARK: - setup Functions
    func setupSegmentControl(){
        
    }
    func setupViews(){
        deleteButton.makeCornerRadiusCircle()

        
        deleteButtonGradientLayer.colors = [UIColor.systemBackground.withAlphaComponent(0).cgColor,
                                            UIColor.systemBackground.withAlphaComponent(1).cgColor]
                 
        deleteButtonGradientLayer.locations = [0, 1]
        deleteButtonGradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        deleteButtonGradientLayer.endPoint = CGPoint(x: 0, y: 0.5)

        deleteButtonGradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: deleteButtonSuperView.bounds.height)

        // Add the gradient layer to the view's layer
        deleteButtonSuperView.layer.insertSublayer(deleteButtonGradientLayer, at: 0)

    }
    func setupTableView(){
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableHeaderView = headerView
        tableView.sectionHeaderTopPadding = 0
        tableView.register(UINib(nibName: CalendarTableViewCell.identifier, bundle: nil), forCellReuseIdentifier: CalendarTableViewCell.identifier)
        tableView.register(UINib(nibName: ReminderTableViewCell.identifier, bundle: nil), forCellReuseIdentifier: ReminderTableViewCell.identifier)
    }
    
    func setupViewModel(){
        let eventStore = EKEventStore()
        viewModel = CalendarViewModel(eventStore: eventStore)
        setSubscribers()
        viewModel.updateValueFor(segment: SegmentType(rawValue: segmentControl.selectedSegmentIndex)!)
    }

    
    func configureRightBarButton(){
        let rightBarButton = UIBarButtonItem(title: ConstantString.selectAll.rawValue, style: .plain, target: self, action: #selector(rightBarButtonPressed))
        navigationItem.rightBarButtonItem = rightBarButton
    }
    
    func configureTitle(){
        let titleLabel = UILabel()
        titleLabel.text = self.title
        titleLabel.textColor = UIColor.label // Customize the color as needed
        titleLabel.font = UIFont.avenirNext(ofSize: 17, weight: .bold) // Adjust the font size as needed
        titleLabel.sizeToFit()
        navigationItem.titleView = titleLabel
        navigationItem.largeTitleDisplayMode = .never
    }
    
    @objc func rightBarButtonPressed(){
        viewModel.selectAndDeselectAll()
    }
    
    func DeleteAlert(){
        let typeName = viewModel.currentSegementType.rawValue == 0 ? ConstantString.calendar.rawValue : ConstantString.reminder.rawValue
        let singularOrPurlarEvent = viewModel.totalSelectedCount > 1 ? ConstantString.events.rawValue : ConstantString.event.rawValue

        let alertVC = UIAlertController(title: "Allow to Delete \(viewModel.totalSelectedCount) \(singularOrPurlarEvent)?", message: "\(singularOrPurlarEvent) will be removed from the \(typeName)", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: ConstantString.cancel.rawValue, style: .cancel) { action in
            self.setupCancelEvent()
        }
        let deleteAction = UIAlertAction(title:ConstantString.delete.rawValue, style: .destructive) { _ in
            self.viewModel.deleteData()
        }
        
        alertVC.addAction(cancelAction)
        alertVC.addAction(deleteAction)
        
        self.present(alertVC, animated: true)
    }
    
    func setupCancelEvent(){
        switch viewModel.currentSegementType{
        case .Calendar:
            logEvent(Event.CalendarScreen.eventDeleteCancel.rawValue, parameter: nil)
        case .Reminder:
            logEvent(Event.CalendarScreen.reminderDeleteCancel.rawValue, parameter: nil)
        }
    }
}


//MARK: - TableView Data Source and Delegate
extension CalendarViewController: UITableViewDataSource, UITableViewDelegate{
    func numberOfSections(in tableView: UITableView) -> Int {
        segmentControl.selectedSegmentIndex == 0 ? viewModel.allEvents.count : viewModel.allReminder.count
        
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        segmentControl.selectedSegmentIndex == 0 ? viewModel.allEvents[section].events.count : viewModel.allReminder[section].reminders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch viewModel.currentSegementType{
        case .Calendar:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: CalendarTableViewCell.identifier, for: indexPath) as? CalendarTableViewCell else{ return UITableViewCell() }
            let event = viewModel.allEvents[indexPath.section].events[indexPath.row]
            cell.configureCell(event: event)
            return cell
        case .Reminder:
            guard let reminderCell = tableView.dequeueReusableCell(withIdentifier: ReminderTableViewCell.identifier, for: indexPath) as? ReminderTableViewCell else { return UITableViewCell()}
            let reminder = viewModel.allReminder[indexPath.section].reminders[indexPath.row]
            reminderCell.configureCell(reminder: reminder)
            return reminderCell
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch viewModel.currentSegementType{
        case .Calendar:
            viewModel.allEvents[indexPath.section].events[indexPath.row].isSelected.toggle()
        case .Reminder:
            viewModel.allReminder[indexPath.section].reminders[indexPath.row].isSelected.toggle()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 30))
        let label = UILabel(frame: CGRect(x: 15, y: 0, width: view.frame.width - 30, height: view.frame.height))
        switch viewModel.currentSegementType{
        case .Calendar:
            label.text = viewModel.allEvents[section].year
        case .Reminder:
            label.text = viewModel.allReminder[section].year
        }
        label.textColor = .label
        label.font = UIFont.avenirNext(ofSize: 17, weight: .bold)
        view.addSubview(label)
        view.backgroundColor = UIColor.lightGrayAndDarkGray2
        return view
    }
}

extension CalendarViewController{
    func setSubscribers(){
        viewModel.$allEvents
            .sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
            .store(in: &cancelables)
        
        viewModel.$allReminder
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }
            .store(in: &cancelables)
        
        viewModel.$isSelectedAll
            .sink { [weak self] isSelectedAll in
            DispatchQueue.main.async {
                self?.navigationItem.rightBarButtonItem?.title = isSelectedAll ? ConstantString.deSelectAll.rawValue : ConstantString.selectAll.rawValue
            }
        }
            .store(in: &cancelables)
        
        viewModel.$totalSelectedCount
            .sink { [weak self] count in
                DispatchQueue.main.async {
                    let eventStr = count > 1 ? ConstantString.events.rawValue : ConstantString.event.rawValue

                    if self!.viewModel.allEvents.isEmpty {
                        self?.title = ""
                    } else {
                        self?.title = "\(count) \(eventStr) \(ConstantString.selected.rawValue)"
                    }
                    self?.configureTitle()
                    self?.deleteButton.backgroundColor = count > 0 ? .darkBlue : .darkGray2
                    self?.deleteButton.isEnabled = count > 0
                }
        }
            .store(in: &cancelables)
        
        viewModel.$totalCount
            .sink { [weak self] count in
                DispatchQueue.main.async {
                    self?.navigationItem.rightBarButtonItem?.isEnabled = count > 0
                }
            }
            .store(in: &cancelables)
        
        viewModel.$isAuthorized.sink { [weak self] isAuthorized in
            DispatchQueue.main.async {
                self?.settingView.isHidden = isAuthorized
                self?.headerView.frame.size.height = isAuthorized ? 100 : 320
                self?.deleteButton.isHidden = !isAuthorized
//                self?.navigationItem.rightBarButtonItem?.isEnabled = isAuthorized
                self?.tableView.reloadData()
                if !isAuthorized{
                    self?.title = ""
                    self?.configureTitle()
                }
            }
        }
        .store(in: &cancelables)
        
        
        viewModel.$unAuthorizedNote.sink { [weak self] note in
            DispatchQueue.main.async {
                self?.settingNoteLabel.text = note
            }
        }
        .store(in: &cancelables)
        
        
        viewModel.$unAuthorizedTitle.sink { [weak self] title in
            DispatchQueue.main.async {
                self?.settingMainLabel.text = title
            }
            
        }
        .store(in: &cancelables)
        
        viewModel.$showLoader.sink { showLoader in
            DispatchQueue.main.async {
                showLoader ? self.view.activityStartAnimating() : self.view.activityStopAnimating()
            }
        }
        .store(in: &cancelables)
    }
}

enum SegmentType: Int,CaseIterable{
    case Calendar = 0
    case Reminder    
}
