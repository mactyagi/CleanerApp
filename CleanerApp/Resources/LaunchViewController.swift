//
//  LaunchViewController.swift
//  CleanerApp
//
//  Created by Manu on 18/02/24.
//

import UIKit

class LaunchViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        animateImage()
        goToTabVC()
        
        // Do any additional setup after loading the view.
    }
    
    func goToTabVC(){
        // Note: This UIKit launch flow is now handled by SwiftUI (RootView + LaunchView)
        // This function is kept for backward compatibility but is no longer used
        // The SwiftUI App entry point (CleanerApp.swift) now manages the app launch
    }
    
    func animateImage() {
            // Set initial properties for animation
            imageView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            imageView.alpha = 0.0
            
            // Animate the image using keyframe animation
            UIView.animateKeyframes(withDuration: 2.0, delay: 0, options: [.calculationModeCubic], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                    // Animation: Scale up and fade in
                    self.imageView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                    self.imageView.alpha = 1.0
                }
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                    // Animation: Scale down and fade out
                    self.imageView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                    self.imageView.alpha = 0.0
                }
            }, completion: { _ in
                // Optionally, you can repeat the animation
                 self.animateImage()
            })
        }
}
