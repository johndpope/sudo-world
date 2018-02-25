//
//  SCNNode + Extensions.swift
//  ARWorld
//
//  Created by TSD040 on 2018-02-09.
//  Copyright © 2018 sudo-world. All rights reserved.
//

import Foundation
import SceneKit

extension SCNNode {
    
    func shrinkAndRemove() {
        
        
        let animation = CABasicAnimation(keyPath: "scale")
        animation.fromValue = scale
        print("circle animation starting scale \(scale)")
        animation.toValue = SCNVector3Zero
        animation.duration = 0.1
        animation.isRemovedOnCompletion = true
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        
        let scnanimation = SCNAnimation.init(caAnimation: animation)
        scnanimation.animationDidStop = { (_,_,_) in
            self.removeFromParentNode()
        }
        
        let scnAnimationPlayer = SCNAnimationPlayer.init(animation: scnanimation)
        
        self.addAnimationPlayer(scnAnimationPlayer, forKey: "FadeOutPlayer")
        self.animationPlayer(forKey: "FadeOutPlayer")?.play()
        
    }
        
    
}
