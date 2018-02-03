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
    case gong = "gong"
    case vase = "vase"
    case arjun = "arjun"
    case greenBall = "greenBall"
    case lowPolyTree = "lowPolyTree"
    case orange = "orange"
    case dragon = "dragon"
    
    static func assetTypesForMenu() -> [NodeAssetType] {
        return [.wolf, .gong, .vase, .arjun, .greenBall, .lowPolyTree, .orange, .dragon]
    }
    
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
        case .gong:
            return createNodeFromAsset(assetName: "gong", assetExtension: "dae")
        case .vase:
            return createNodeFromAsset(assetName: "vase", assetExtension: "dae")
        case .blueBox:
            return NodeCreator.blueBox
        case .arjun:
            return createNodeFromAsset(assetName: "arjun", assetExtension: "dae")
        case .greenBall:
            return createNodeFromAsset(assetName: "greenBall", assetExtension: "dae")
        case .lowPolyTree:
            return createNodeFromAsset(assetName: "lowPolyTree", assetExtension: "dae")
        case .orange:
            return createNodeFromAsset(assetName: "orange", assetExtension: "dae")
        case .dragon:
            return createNodeFromAsset(assetName: "dragon", assetExtension: "dae")

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
    
    func menuImage() -> UIImage {
        switch self {
        case .wolf:
            return #imageLiteral(resourceName: "menuWolf")
        case .blueBox:
            return #imageLiteral(resourceName: "menuBlueBox")
        case .gong:
            return #imageLiteral(resourceName: "menuGong")
        case .vase:
            return #imageLiteral(resourceName: "menuVase")
        case .arjun:
            return #imageLiteral(resourceName: "menuArjun")
        case .greenBall:
            return #imageLiteral(resourceName: "menuGreenBall")
        case .lowPolyTree:
            return #imageLiteral(resourceName: "menuLowPolyTree")
        case .orange:
            return #imageLiteral(resourceName: "menuOrange")
        case .dragon:
            return #imageLiteral(resourceName: "menuDragon")
        }
    }
}

struct RootScene {
    static var shared = RootScene()
    let rootNode = SCNScene(named: "art.scnassets/ship.scn")!.rootNode
}

