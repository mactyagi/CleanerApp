//
//  CircularProgressView.swift
//  CleanerApp
//
//  Created by Manu on 29/01/24.
//
import UIKit

class CircularProgressBarView: UIView {
    private let progressLayer = CAShapeLayer()
    private let percentageLabel = UILabel()
    var progress: Float = 0{
        didSet{
            var percentage = 0
            if progress > 0{
                percentage = Int((progress / 1) * 100)
            }
            
            if progress > 1 {
               percentage = 100
            }
            percentageLabel.text = "\(percentage)%"
            progressLayer.strokeEnd = CGFloat(progress)
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    func setup() {
        self.backgroundColor = UIColor.clear
        let centerPoint = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        let circularPath = UIBezierPath(arcCenter: centerPoint, radius: bounds.width / 2 - 10, startAngle: -.pi / 2, endAngle: 3 * .pi / 2, clockwise: true)

        progressLayer.path = circularPath.cgPath
        progressLayer.strokeColor = UIColor.darkBlue.cgColor
        progressLayer.fillColor = (UIColor(named: "lightGray") ?? UIColor.lightGray2).cgColor
        progressLayer.lineWidth = 6
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0

        layer.addSublayer(progressLayer)
        
        percentageLabel.translatesAutoresizingMaskIntoConstraints = false
        percentageLabel.textAlignment = .center
        percentageLabel.textColor = .black
        percentageLabel.font = UIFont(name: "AvenirNext-Bold", size: 20.0)
        addSubview(percentageLabel)
        NSLayoutConstraint.activate([
            percentageLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
            percentageLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10),
            percentageLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            percentageLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10)
        ])
    }

    func setProgress(_ progress: Float) {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = progressLayer.strokeEnd
        animation.toValue = progress
        animation.duration = 0.5
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        progressLayer.strokeEnd = CGFloat(progress)
        progressLayer.add(animation, forKey: "progressAnimation")
        
        self.progress = progress
    }
}
