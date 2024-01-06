//
//  BaseViewController.swift
//  CleanerApp
//
//  Created by Manu on 05/01/24.
//

import UIKit
import Combine
import CoreData


class BaseViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    
    var fetchResultViewController: NSFetchedResultsController<CustomAsset>!
    var predicate: NSPredicate!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        LoadSaveData()
    }
    
    
    class func customInit() -> BaseViewController{
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BaseViewController") as! BaseViewController
        return vc
    }
    
    
    func setupCollectionView(){
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: PhotoCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: PhotoCollectionViewCell.identifier)
        collectionView.collectionViewLayout = GridCollectionViewFlowLayout(columns: 2, topLayoutMargin: 10, bottomLayoutMargin: 0, leftLayoutMargin: 0, spacing: 10, direction: .vertical, isLayoutForCell: false)
    }
    
    func LoadSaveData(){
        if fetchResultViewController == nil{
            let request = CustomAsset.fetchRequest()
            let sort = NSSortDescriptor(key: "creationDate", ascending: true)
            request.sortDescriptors = [sort]
            
            if let predicate{
                request.predicate = predicate
            }
            
            fetchResultViewController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: CoreDataManager.shared.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
            
            fetchResultViewController.delegate = self
            
            do{
                try fetchResultViewController.performFetch()
            } catch{
                print(error)
            }
        }
    }

}


extension BaseViewController: UICollectionViewDataSource{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchResultViewController.sections?.count ?? 0
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResultViewController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.identifier, for: indexPath) as! PhotoCollectionViewCell
        
        let object = fetchResultViewController.object(at: indexPath)
        print(object)
        
        cell.configureNewCell(asset: object)
        return cell
    }
}

extension BaseViewController: NSFetchedResultsControllerDelegate{
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates(nil)
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        switch type{
            
        case .insert:
            collectionView?.insertSections(indexSet)
        case .delete:
            collectionView?.deleteSections(indexSet)
        default:
            break
        }
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            collectionView?.insertItems(at: [newIndexPath!])
        case .delete:
            collectionView?.deleteItems(at: [indexPath!])
        case .move:
            collectionView?.moveItem(at: indexPath!, to: newIndexPath!)
        case .update:
            collectionView?.reloadItems(at: [indexPath!])
        @unknown default:
            break
        }
    }
    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView?.performBatchUpdates(nil, completion: nil)
    }
}
