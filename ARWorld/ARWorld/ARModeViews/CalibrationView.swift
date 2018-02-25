//
//  CalibrationView.swift
//  ARWorld
//
//  Created by TSD040 on 2018-02-07.
//  Copyright © 2018 sudo-world. All rights reserved.
//

import UIKit

protocol CalibrationViewDelegate: class {
    func calibrationPanGestureBegan(screenCoordinates: CGPoint)
    func calibrationPanGestureChanged(screenCoordinates: CGPoint)
    func calibrationPanGestureEndedOrCancelled(ScreenCoordinates: CGPoint)
    func calibrationDone()
}

extension CalibrationViewDelegate {
    func calibrationPanGestureBegan(screenCoordinates: CGPoint) {}
    func calibrationPanGestureChanged(screenCoordinates: CGPoint) {}
    func calibrationPanGestureEndedOrCancelled(ScreenCoordinates: CGPoint) {}
    func calibtarionDone() {}
}

class CalibrationView: UIView {

    @IBOutlet weak var view: UIView!
    @IBOutlet weak var panGestureRecognizer: UIPanGestureRecognizer!
  
    weak var delegate: CalibrationViewDelegate?
    
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        
//        let _ = Bundle.main.loadNibNamed(String(describing: CalibrationView.self), owner: self, options: nil)![0] as! UIView
//        self.view.frame = self.bounds
//        self.addSubview(self.view)
//    }
    
    func loadViewFromNib() -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: CalibrationView.self), bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
        
    @IBAction func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            delegate?.calibrationPanGestureBegan(screenCoordinates: sender.location(in: view))
            break
        case .changed:
            delegate?.calibrationPanGestureChanged(screenCoordinates: sender.location(in: view))
            break
        case .ended, .cancelled:
            delegate?.calibrationPanGestureEndedOrCancelled(ScreenCoordinates: sender.location(in: view))
            break
        default:
            break
        }
    }

    @IBAction func calibrationButtonDonePressed(_ sender: Any) {
        delegate?.calibrationDone()
    }
    
    
}
