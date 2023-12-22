//
//  SecretAlbumViewController.swift
//  CleanerApp
//
//  Created by manu on 15/11/23.
//

import UIKit
import MobileCoreServices
import PhotosUI

class SecretAlbumViewController: UIViewController{

    @IBOutlet weak var plusImageView: UIImageView!
    //MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    //MARK: - static func and variables
    static let identifier = "SecretAlbumViewController"
    static func customInit() -> SecretAlbumViewController{
        let vc = UIStoryboard.secretSpace.instantiateViewController(withIdentifier: identifier) as! SecretAlbumViewController
        return vc
    }
    
    //MARK: - IBActions
    @IBAction func addButtonPressed(){
        alertForLibraryAccess()
    }
    
    //MARK: - func
    func setup(){
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.whiteAndGray
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        plusImageView.dropShadow()
    }
    
    func alertForLibraryAccess(){
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let action = UIAlertAction(title: "Take photo or video", style: .default) { action in
            self.accessCamera()
        }
        
        let action2 = UIAlertAction(title: "Import photos or videos", style: .default) { action in
            self.accessLibrary()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertVC.addAction(action)
        alertVC.addAction(action2)
        alertVC.addAction(cancelAction)
        present(alertVC, animated: true)
    }
    
    func accessCamera(){
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            let myPickerViewController = UIImagePickerController()
            myPickerViewController.delegate = self
            myPickerViewController.sourceType = .camera
            myPickerViewController.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String]
            myPickerViewController.showsCameraControls = true
            self.present(myPickerViewController, animated: true)
        }
    }
    
    func accessLibrary(){
        var configuration = PHPickerConfiguration()
        configuration.preferredAssetRepresentationMode = .compatible
        configuration.selectionLimit = 0
        let vc = PHPickerViewController(configuration: configuration)
        vc.delegate = self
        present(vc, animated: true)
    }
    
    func dealWithVideo(_ result: PHPickerResult){
        
    }
    
    func dealWithImage(_ result: PHPickerResult){
        result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
            guard let image = object as? UIImage else { return }
            print(image)
        }
    }
}


extension SecretAlbumViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
}

extension SecretAlbumViewController: PHPickerViewControllerDelegate{
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        for result in results {
            if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier){
                
            }else if result.itemProvider.canLoadObject(ofClass: UIImage.self){
                dealWithImage(result)
            }
        }
        
       dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
    
}
