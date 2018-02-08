//
//  WaitingForAnchorLocationView.swift
//  ARWorld
//
//  Created by TSD040 on 2018-02-07.
//  Copyright © 2018 sudo-world. All rights reserved.
//

import UIKit

protocol WaitingForAnchorLocationViewDelegate: class {
    func panGestureBeganOrChanged(screenCoordinates: CGPoint)
}

extension WaitingForAnchorLocationViewDelegate {
    func panGestureBeganOrChanged(screenCoordinates: CGPoint) {}
}

class WaitingForAnchorLocationView: UIView {

    @IBOutlet weak var view: UIView!
    
    weak var delegate: WaitingForAnchorLocationViewDelegate?
    
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//
//        let _ = Bundle.main.loadNibNamed(String(describing: WaitingForAnchorLocationView.self), owner: self, options: nil)![0] as! UIView
//        self.view.frame = self.bounds
//        self.addSubview(self.view)
//    }

    @IBAction func handlePagGesture(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began, .changed:
            delegate?.panGestureBeganOrChanged(screenCoordinates: sender.location(in: view))
        default:
            break
        }
    }
}
