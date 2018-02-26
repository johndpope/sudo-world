//
//  UIViewExtensions.swift
//  ARWorld
//
//  Created by TSD044 on 2018-02-02.
//  Copyright © 2018 sudo-world. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    static var cornerRadius: CGFloat = 30
    
    func addCornerRadius() {
        self.layer.cornerRadius = UIView.cornerRadius
        self.layer.masksToBounds = true
    }
    
    func addGrayDiagonalShading() {
        let greenTint = #colorLiteral(red: 0.2510820436, green: 1, blue: 0.8285764853, alpha: 1)
        let topLeftColor = greenTint.withAlphaComponent(0.3)
        let bottomRightColor = UIColor.white.withAlphaComponent(0)
        
        let gradient = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.startPoint = CGPoint.zero
        gradient.endPoint = CGPoint(x: 0.8, y: 0.8)
        gradient.colors = [topLeftColor.cgColor, bottomRightColor.cgColor]
        self.layer.insertSublayer(gradient, at: 0)
    }
    
    func addTopHighlight() {
        let topColor = UIColor.white.withAlphaComponent(0.8).cgColor
        let bottomColor = UIColor.white.withAlphaComponent(0).cgColor
        let height: CGFloat = 12
        
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: height)
        gradient.startPoint = CGPoint.zero
        gradient.endPoint = CGPoint(x: 0, y: 1.0)
        gradient.colors = [topColor, bottomColor]
        self.layer.insertSublayer(gradient, at: 0)
    }
    
    func addBottomShadow() {
        let topColor = UIColor.white.withAlphaComponent(0).cgColor
        let bottomColor = UIColor.black.withAlphaComponent(0.2).cgColor
        let height: CGFloat = 12
        
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: self.bounds.height - height, width: self.bounds.width, height: height)
        gradient.startPoint = CGPoint(x: 0, y: 1)
        gradient.endPoint = CGPoint(x: 0, y: 0.4)
        gradient.colors = [bottomColor, topColor]
        self.layer.insertSublayer(gradient, at: 0)
    }
}
