//
//  ModelLibrary.swift
//  ARWorld
//
//  Created by TSD044 on 2018-02-02.
//  Copyright © 2018 sudo-world. All rights reserved.
//

import Foundation
import SceneKit

protocol ModelType {
    static func initializeNode() -> SCNNode?
}

extension ModelType {
    static func initializeNode() -> SCNNode? {
        return RootScene.shared.rootNode.childNode(withName: className(), recursively: false)
    }

    static func className() -> String {
        return String(describing: self)
    }
    
}

struct RootScene {
    static var shared = RootScene()
    let rootNode = SCNScene(named: "art.scnassets/ship.scn")!.rootNode
}

struct GlobalOriginNodeModel: ModelType {
    
}

struct FloorModel: ModelType {
    
}

