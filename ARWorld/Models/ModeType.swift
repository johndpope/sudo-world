//
//  ModelLibrary.swift
//  ARWorld
//
//  Created by TSD044 on 2018-02-02.
//  Copyright © 2018 sudo-world. All rights reserved.
//

import Foundation
import SceneKit


enum NodeAssetType: String {
    case wolf = "wolf"
    case blueBox = "blueBox"
    
    static func getType(typeName: String) -> NodeAssetType {
        switch typeName {
        case NodeAssetType.wolf.rawValue:
            return NodeAssetType.wolf
        default:
            return NodeAssetType.blueBox
        }
    }
    
    func initializeNode() -> SCNNode? {
        switch self {
        case .wolf:
            return createNodeFromAsset(assetName: "wolf", assetExtension: "dae")
        case .blueBox:
            return NodeCreator.blueBox
        }
    }
    
    func createNodeFromAsset(assetName: String, assetExtension: String) -> SCNNode? {
        guard let url = Bundle.main.url(forResource: "art.scnassets/\(assetName)", withExtension: assetExtension) else {
            return nil
        }
        guard let node = SCNReferenceNode(url: url) else { return nil }
        node.load()
        return node
    }
    
    //    func className() -> String {
    //        return String(describing: self)
    //    }
}

struct RootScene {
    static var shared = RootScene()
    let rootNode = SCNScene(named: "art.scnassets/ship.scn")!.rootNode
}

