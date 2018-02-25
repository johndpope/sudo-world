//
//  EditingModeView.swift
//  ARWorld
//
//  Created by TSD040 on 2018-02-07.
//  Copyright © 2018 sudo-world. All rights reserved.
//

import UIKit

protocol EditingModeViewDelegate: class {
    func didTap(screenCoordinates: CGPoint)
    func editPanDidBegin(screenCoordinates: CGPoint)
    func editPanDidChange(screenCoordinates: CGPoint)
    func editPanDidEnd(screenCoordinates: CGPoint)
    func pinchDidBegin(scale: CGFloat)
    func pinchDidChange(scale: CGFloat)
    func pinchDidEnd(scale: CGFloat)
    func rotationDidBegin(rotation: CGFloat)
    func rotationDidChange(rotation: CGFloat)
    func rotationDidEnd(rotation: CGFloat)
    func doneButtonPressed()
    func trashButtonPressed()
}

extension EditingModeViewDelegate {
    func didTap(screenCoordinates: CGPoint) {}
    func editPanDidBegin(screenCoordinates: CGPoint) {}
    func editPanDidChange(screenCoordinates: CGPoint) {}
    func editPanDidEnd(screenCoordinates: CGPoint) {}
    func pinchDidBegin(scale: CGFloat) {}
    func pinchDidChange(scale: CGFloat) {}
    func pinchDidEnd(scale: CGFloat) {}
    func rotationDidBegin(rotation: CGFloat) {}
    func rotationDidChange(rotation: CGFloat) {}
    func rotationDidEnd(rotation: CGFloat) {}
}

class EditingModeView: UIView {

    @IBOutlet weak var view: UIView!
    @IBOutlet weak var rotationGestureRecognizer: UIRotationGestureRecognizer!
    @IBOutlet weak var pinchGestureRecognizer: UIPinchGestureRecognizer!
    @IBOutlet weak var panGestureRecognizer: UIPanGestureRecognizer!
    @IBOutlet weak var tapGestureRecognizer: UITapGestureRecognizer!
    
    
    weak var delegate: EditingModeViewDelegate?
    
    var previousRotation: CGFloat? // set to nil when editing completes
    
    @IBAction func doneButtonPressed(_ sender: UIButton) {
        delegate?.doneButtonPressed()
    }
    
    @IBAction func TrashButtonPressed(_ sender: UIButton) {
        delegate?.trashButtonPressed()
    }
    
    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
        delegate?.didTap(screenCoordinates: sender.location(in: view))
    }
    
    @IBAction func handleRotationGesture(_ sender: UIRotationGestureRecognizer) {
        print("rotation gesture received")
        switch sender.state {
        case .began:
            tapGestureRecognizer.isEnabled = false
//            pinchGestureRecognizer.isEnabled = false
            panGestureRecognizer.isEnabled = false
            previousRotation = sender.rotation
            delegate?.rotationDidBegin(rotation: sender.rotation)
            break
        case .changed:
            delegate?.rotationDidChange(rotation: sender.rotation)
            break
        case .ended, .cancelled:
            delegate?.rotationDidEnd(rotation: sender.rotation)
            tapGestureRecognizer.isEnabled = true
//            pinchGestureRecognizer.isEnabled = true
            panGestureRecognizer.isEnabled = true
            break
        default:
            break
        }
    }
    
    @IBAction func handlePinchGesture(_ sender: UIPinchGestureRecognizer) {
        switch sender.state {
        case .began:
            tapGestureRecognizer.isEnabled = false
//            rotationGestureRecognizer.isEnabled = false
            panGestureRecognizer.isEnabled = false
            delegate?.pinchDidBegin(scale: sender.scale)
            break
        case .changed:
            delegate?.pinchDidChange(scale: sender.scale)
            break
        case .ended, .cancelled:
            delegate?.pinchDidEnd(scale: sender.scale)
            tapGestureRecognizer.isEnabled = true
//            rotationGestureRecognizer.isEnabled = true
            panGestureRecognizer.isEnabled = true
            break
        default:
            break
        }
    }
    
    @IBAction func handlePan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            tapGestureRecognizer.isEnabled = false
            pinchGestureRecognizer.isEnabled = false
            rotationGestureRecognizer.isEnabled = false
            delegate?.editPanDidBegin(screenCoordinates: sender.location(in: view))
            break
        case .changed:
            delegate?.editPanDidChange(screenCoordinates: sender.location(in: view))
            break
        case .ended, .cancelled:
            delegate?.editPanDidEnd(screenCoordinates: sender.location(in: view))
            tapGestureRecognizer.isEnabled = true
            pinchGestureRecognizer.isEnabled = true
            rotationGestureRecognizer.isEnabled = true
            break
        default:
            break
        }
    }
    
}
