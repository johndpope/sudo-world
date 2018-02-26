//
//  GesturesContainer.swift
//  ARWorld
//
//  Created by TSD040 on 2018-02-25.
//  Copyright © 2018 sudo-world. All rights reserved.
//

import UIKit

/// Set userInteractionEnabled to false if you want that location to be recognized by the gesture recognizer
protocol GesturesContainerDelegate {
    func panGestureDidChange(_ gestureRecognizer: UIPanGestureRecognizer, screenCoordinates: CGPoint)
    func tapGestureDidChange(_ gestureRecognizer: UITapGestureRecognizer, screenCoordinates: CGPoint)
    func rotationGestureDidChange(_ gestureRecognizer: UIRotationGestureRecognizer)
    func pinchGestureDidChange(_ gestureRecognizer: UIPinchGestureRecognizer)
}

class GesturesContainer: UIView {
    
    var delegate: (GesturesContainerDelegate & UIView)?
    
    init() {
        super.init(frame: CGRect.zero)
                
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        addGestureRecognizer(panRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapRecognizer)

        let rotationRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation))
        rotationRecognizer.delegate = self
        addGestureRecognizer(rotationRecognizer)

        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        pinchRecognizer.delegate = self
        addGestureRecognizer(pinchRecognizer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let delegateView = delegate?.hitTest(point, with: event) {
            let delegateHasInteractiveSubview = delegateView !== delegate
//            print("should hittest touch delegateHasInteractiveView \(delegateHasInteractiveSubview)")

            if delegateHasInteractiveSubview {
//                print("should hittest touch delegate \(delegateView)")
                return delegateView
            } else {
//                print("should hittest touch self (delegate has no subview at this point)")
                return super.hitTest(point, with: event)
            }
        }
        
//        print("should hittest touch self")
        return  super.hitTest(point, with: event)
    }
    
    @objc private func handlePan(_ sender: UIPanGestureRecognizer) {
        let screenCoordinates = sender.location(in: self)
        delegate?.panGestureDidChange(sender, screenCoordinates: screenCoordinates)
    }
    
    @objc private func handleTap(_ sender: UITapGestureRecognizer) {
        let screenCoordinates = sender.location(in: self)
        delegate?.tapGestureDidChange(sender, screenCoordinates: screenCoordinates)
    }
    @objc private func handleRotation(_ sender: UIRotationGestureRecognizer) {
        delegate?.rotationGestureDidChange(sender)
    }
    
    @objc private func handlePinch(_ sender: UIPinchGestureRecognizer) {
        delegate?.pinchGestureDidChange(sender)
    }
}

extension GesturesContainer: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer is UIRotationGestureRecognizer && otherGestureRecognizer is UIPinchGestureRecognizer
    }
}

//class PassthroughView: UIView {
//    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
//        let view = super.hitTest(point, with: event)
//        return view == self ? nil : view
//    }
//}
