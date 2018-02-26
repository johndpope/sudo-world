//
//  WaitingForAnchorLocationView.swift
//  ARWorld
//
//  Created by TSD040 on 2018-02-07.
//  Copyright © 2018 sudo-world. All rights reserved.
//

import UIKit

protocol WaitingForAnchorLocationViewDelegate: class {
    func setGlobalNode(worldHitTestAt: CGPoint)
}

class WaitingForAnchorLocationView: UIView {

    @IBOutlet weak var view: UIView!
    
    weak var delegate: WaitingForAnchorLocationViewDelegate?
}

extension WaitingForAnchorLocationView: ARModeView {
    func panGestureDidChange(_ gestureRecognizer: UIPanGestureRecognizer, screenCoordinates: CGPoint) {
        delegate?.setGlobalNode(worldHitTestAt: screenCoordinates)
    }
    
    func tapGestureDidChange(_ gestureRecognizer: UITapGestureRecognizer, screenCoordinates: CGPoint) {
    }
    
    func rotationGestureDidChange(_ gestureRecognizer: UIRotationGestureRecognizer) {
    }
    
    func pinchGestureDidChange(_ gestureRecognizer: UIPinchGestureRecognizer) {
    }
}
