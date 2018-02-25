//
//  NodeAnimationCreator.swift
//  ARWorld
//
//  Created by TSD040 on 2018-02-25.
//  Copyright © 2018 sudo-world. All rights reserved.
//

import SceneKit

struct NodeAnimationCreator {
    // MARK: - Selecting an object for editing
    // bounces the object, and adds a white circle below
    static func bouncingAnimation() -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "pivot")
        animation.fromValue = SCNMatrix4Identity
        animation.toValue = SCNMatrix4Translate(SCNMatrix4Identity, 0, -0.2, 0)
        animation.duration = 1.2
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        return animation
    }
    
    static func editingCircleScaledToFit(maxSize: Float) -> SCNNode {
        func editingCircle() -> SCNNode {
            let rootNode = SCNScene(named: "art.scnassets/EditingCircle.scn")!.rootNode
            let circle = rootNode.childNode(withName: "editingCircle", recursively: false)!
            return circle
        }
        
        let circle = editingCircle()
        circle.scale = SCNVector3(maxSize, 0, maxSize)
        return circle
    }
    
    // MARK: - Deselecting an object for editing
    // drops the object onto the circle, and shrinks the circle until it disapears
    static func droppingAnimation(startingValue: SCNMatrix4) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "pivot")
        animation.fromValue = SCNMatrix4Translate(SCNMatrix4Identity, 0, -0.2, 0)
        animation.toValue = SCNMatrix4Identity
        animation.duration = 0.1
        animation.isRemovedOnCompletion = true
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        return animation
    }
}

extension SCNNode {
    func shrinkAndRemove() {
        let animation = CABasicAnimation(keyPath: "scale")
        animation.fromValue = scale
        print("circle animation starting scale \(scale)")
        animation.toValue = SCNVector3Zero
        animation.duration = 0.1
        animation.isRemovedOnCompletion = true
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        
        let scnanimation = SCNAnimation(caAnimation: animation)
        scnanimation.animationDidStop = { (_,_,_) in
            self.removeFromParentNode()
        }
        
        let scnAnimationPlayer = SCNAnimationPlayer(animation: scnanimation)
        
        self.addAnimationPlayer(scnAnimationPlayer, forKey: "FadeOutPlayer")
        self.animationPlayer(forKey: "FadeOutPlayer")?.play()
    }
}
