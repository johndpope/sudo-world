//
//  RealTimeDB.swift
//  ARWorld
//
//  Created by TSD021 on 2018-02-02.
//  Copyright © 2018 sudo-world. All rights reserved.
//

import Foundation
import FirebaseDatabase
import SceneKit

protocol FirebaseManagerDelegate: class {
    func didAddNode(node: SceneNode)
    func didChangeNode(node: SceneNode)

}

struct FirebaseManager {

    static var shared = FirebaseManager.init()
    let db: DatabaseReference = Database.database().reference()

    static let modelsTableName = "models"
    static let modelsTable_typeColumn = "type"
    static let modelsTable_transformColumn = "transform"

    weak var delegate: FirebaseManagerDelegate?

    func testDB(){
        //set observer
        observeData(listener: {(snapshot) in
            if let databaseSnapshot = snapshot.value as? [String : [String : AnyObject]] {
                FirebaseManager.getSceneNodes(databaseSnapshot: databaseSnapshot)
            }
        })

        //write test
        updateNode(type: NodeAssetType.box, transform: SCNMatrix4Identity)
    }

    static func getSceneNodes(databaseSnapshot: [String : [String : AnyObject]]) -> Array<SceneNode>{
        var listOfSceneNodes: Array<SceneNode> = Array()

        if let models = databaseSnapshot["models"] {
            for (modelID, modelData) in models {
                let modelDataAsDictionary = modelData as? [String : AnyObject]
                let nodeType = modelDataAsDictionary![FirebaseManager.modelsTable_typeColumn] as? String
                let nodeTransform = modelDataAsDictionary![FirebaseManager.modelsTable_transformColumn] as? NSArray
                listOfSceneNodes.append(SceneNode(id: modelID, type: NodeAssetType.getType(typeName: nodeType!), transformAsArray: nodeTransform as! Array<Float>))
            }
        }

        return listOfSceneNodes
    }

    func updateNode(type: NodeAssetType, transform: SCNMatrix4){

        //Ready transform as matrix
        let transformAsArray: Array<Float> = [
            transform.m11, transform.m12, transform.m13, transform.m14,
            transform.m21, transform.m22, transform.m23, transform.m24,
            transform.m31, transform.m32, transform.m33, transform.m34,
            transform.m41, transform.m42, transform.m43, transform.m44
        ]

        //Ready uuid and write to db
        let uuid = NSUUID().uuidString
        db.child(FirebaseManager.modelsTableName).child(uuid).child(FirebaseManager.modelsTable_typeColumn).setValue(type.rawValue)
        db.child(FirebaseManager.modelsTableName).child(uuid).child(FirebaseManager.modelsTable_transformColumn).setValue(transformAsArray)
    }

    func observeData(listener : ((DataSnapshot) -> Void)!){
        db.observe(DataEventType.value, with: listener)
    }

}

struct SceneNode {
    var id: String
    var type: NodeAssetType
    var transform: SCNMatrix4

    init(id: String, type: NodeAssetType, transformAsArray: Array<Float>) {
        self.id = id
        self.type = type
        self.transform = SCNMatrix4(m11: transformAsArray[0], m12: transformAsArray[1], m13: transformAsArray[2], m14: transformAsArray[3],
                                    m21: transformAsArray[4], m22: transformAsArray[5], m23: transformAsArray[6], m24: transformAsArray[7],
                                    m31: transformAsArray[8], m32: transformAsArray[9], m33: transformAsArray[10], m34: transformAsArray[11],
                                    m41: transformAsArray[12], m42: transformAsArray[13], m43: transformAsArray[14], m44: transformAsArray[15])
    }
}

extension SceneNode : Equatable {
    static func ==(lhs: SceneNode, rhs: SceneNode) -> Bool {
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

enum NodeAssetType: String {
    case plane = "plane"
    case box = "box"

    static func getType(typeName: String) -> NodeAssetType {
        switch typeName {
            case NodeAssetType.plane.rawValue:
                return NodeAssetType.plane
            default:
                return NodeAssetType.box
        }
    }
}


