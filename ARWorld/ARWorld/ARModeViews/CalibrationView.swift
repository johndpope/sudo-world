//
//  CalibrationView.swift
//  ARWorld
//
//  Created by TSD040 on 2018-02-07.
//  Copyright © 2018 sudo-world. All rights reserved.
//

import UIKit

protocol CalibrationViewDelegate: class {
    func handleInitialCalibrationDrag(at screenCoordinates: CGPoint)
    func calibrationDone()
}

class CalibrationView: UIView {
  
    weak var delegate: CalibrationViewDelegate?

    @IBAction func calibrationButtonDonePressed(_ sender: Any) {
        delegate?.calibrationDone()
    }    
}

extension CalibrationView: ARModeView {
    
    func panGestureDidChange(_ gestureRecognizer: UIPanGestureRecognizer, screenCoordinates: CGPoint) {
        switch gestureRecognizer.state {
        case .began, .changed:
            delegate?.handleInitialCalibrationDrag(at: screenCoordinates)
            break
        case .ended, .cancelled:
            break
        default:
            break
        }
    }
    
    func tapGestureDidChange(_ gestureRecognizer: UITapGestureRecognizer, screenCoordinates: CGPoint) {
        
    }
    
    func rotationGestureDidChange(_ gestureRecognizer: UIRotationGestureRecognizer) {
        
    }
    
    func pinchGestureDidChange(_ gestureRecognizer: UIPinchGestureRecognizer) {
        
    }
}
