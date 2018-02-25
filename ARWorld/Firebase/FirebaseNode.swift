//
//  FirebaseNode.swift
//  ARWorld
//
//  Created by TSD040 on 2018-02-25.
//  Copyright © 2018 sudo-world. All rights reserved.
//

import SceneKit

struct FirebaseNode {
    var id: String
    var type: NodeAssetType
    var transform: SCNMatrix4
    
    init(id: String, type: NodeAssetType, transformAsArray: Array<Float>) {
        self.id = id
        self.type = type
        self.transform = FirebaseManager.arrayToTransform(transformAsArray)
    }
    
    init(id: String, type: NodeAssetType, transform: SCNMatrix4) {
        self.id = id
        self.type = type
        self.transform = transform
    }
}

extension FirebaseNode : Equatable {
    static func ==(lhs: FirebaseNode, rhs: FirebaseNode) -> Bool {
        if(lhs.id != rhs.id){
            return false
        }
        if(lhs.type == rhs.type){
            return false
        }
        if(SCNMatrix4EqualToMatrix4(lhs.transform, rhs.transform)){
            return false
        }
        return true
    }
}
