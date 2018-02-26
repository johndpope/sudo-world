//
//  GlobalNode.swift
//  ARWorld
//
//  Created by TSD040 on 2018-02-25.
//  Copyright © 2018 sudo-world. All rights reserved.
//

import SceneKit

class GlobalNode: SCNNode {
    private let calibrationArrowNode = SCNNode()
    private var calibrationArrowGeometry = SCNBox(width: 0.3, height: 0.03, length: 0.03, chamferRadius: 0.01)
    
    override init() {
        super.init()
        calibrationArrowGeometry.firstMaterial = SCNMaterial.material(withDiffuse: UIColor.orange, respondsToLighting: false)
        calibrationArrowNode.geometry = calibrationArrowGeometry
        
        addChildNode(calibrationArrowNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setCalibrationArrowWidth(_ newWidth: Float) {
        calibrationArrowGeometry.width = CGFloat(newWidth)
        calibrationArrowNode.position = SCNVector3(x: newWidth / 2, y: 0, z: 0)
    }
}
