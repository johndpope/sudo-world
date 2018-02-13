//
//  SudoNode.swift
//  ARWorld
//
//  Created by TSD040 on 2018-02-08.
//  Copyright © 2018 sudo-world. All rights reserved.
//

import UIKit
import ARKit

class SudoNode: Equatable {

    let nodeAssetType: NodeAssetType
    var fireBaseNode: FirebaseNode
    var assetNode: SCNNode
    var sceneNode: SCNNode
    
    var position: SCNVector3 {
        get {
            return sceneNode.position
        }
        set {
            sceneNode.position = newValue
            fireBaseNode.transform = sceneNode.transform
        }
    }
    
    var scale: SCNVector3 {
        get {
            return sceneNode.scale
        }
        set {
            sceneNode.scale = newValue
            fireBaseNode.transform = sceneNode.transform
        }
    }
    
    var rotation: SCNVector4 {
        get {
            return sceneNode.rotation
        }
        set {
            sceneNode.rotation = newValue
            fireBaseNode.transform = sceneNode.transform
        }
    }
    
    var transform: SCNMatrix4 {
        get {
            return sceneNode.transform
        }
        set {
            sceneNode.transform = newValue
            fireBaseNode.transform = sceneNode.transform
        }
    }
    
    var worldPosition: SCNVector3 {
        get {
            return sceneNode.worldPosition
        }
        set {
            sceneNode.worldPosition = newValue
            fireBaseNode.transform = sceneNode.transform
        }
    }
    
    var eulerAngles: SCNVector3 {
        get {
            return sceneNode.eulerAngles
        }
        set {
            sceneNode.eulerAngles = newValue
            fireBaseNode.transform = sceneNode.transform
        }
    }
    
    
    var id: String {
        return fireBaseNode.id
    }
    
    public init(fbNode: FirebaseNode) {
        self.fireBaseNode = fbNode
        self.nodeAssetType = (NodeAssetType(rawValue: fireBaseNode.type.rawValue) ?? NodeAssetType.blueBox)
        self.assetNode = self.nodeAssetType.initializeNode()!
        self.sceneNode = SCNNode()
        self.sceneNode.transform = fbNode.transform
        self.sceneNode.addChildNode(assetNode)
        
    }
    
    public init(sceneNode: SCNNode, type: NodeAssetType) {
        self.assetNode = sceneNode
        self.sceneNode = SCNNode()
        self.sceneNode.addChildNode(assetNode)
        self.nodeAssetType = type
        self.fireBaseNode = FirebaseManager.shared.insertNode(type: type, transform: sceneNode.transform)
    }
    
    func pushChanges() {
        FirebaseManager.shared.updateNode(node: fireBaseNode)
    }
    
    static func ==(lhs: SudoNode, rhs: SudoNode) -> Bool {
        return lhs.id == rhs.id
    }
}
