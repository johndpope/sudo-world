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
    func didRemoveNode(id: String)
}

struct FirebaseManager {

    static var shared = FirebaseManager.init()
    let db: DatabaseReference = Database.database().reference()

    static let modelsTableName = "models"
    static let modelsTable_typeColumn = "type"
    static let modelsTable_transformColumn = "transform"

    func testDB() {
        observeOnDelegate(nil)
        var node = insertNode(type: NodeAssetType.blueBox, transform: SCNMatrix4Identity)
        node.transform.m12 = 1234
        updateNode(node: node)
        deleteNode(node: node)
    }

    func insertNode(type: NodeAssetType, transform: SCNMatrix4)-> SceneNode {
        let key = db.child(FirebaseManager.modelsTableName).childByAutoId().key
//        let post = [
//            "id": key,
//            FirebaseManager.modelsTable_typeColumn: type.rawValue,
//            FirebaseManager.modelsTable_transformColumn: transform
//            ]
//        db.child(FirebaseManager.modelsTableName).childByAutoId().setValue(post)


        db.child(FirebaseManager.modelsTableName)
            .child(key)
            .child(FirebaseManager.modelsTable_typeColumn)
            .setValue(type.rawValue)

        db.child(FirebaseManager.modelsTableName)
            .child(key)
            .child(FirebaseManager.modelsTable_transformColumn)
            .setValue(FirebaseManager.transformToArray(transform: transform))

        return SceneNode(id: key, type: type, transform: transform)
    }

    func updateNode(node: SceneNode){
        db.child(FirebaseManager.modelsTableName)
            .child(node.id)
            .child(FirebaseManager.modelsTable_typeColumn)
            .setValue(node.type.rawValue)

        db.child(FirebaseManager.modelsTableName)
            .child(node.id)
            .child(FirebaseManager.modelsTable_transformColumn)
            .setValue(FirebaseManager.transformToArray(transform: node.transform))
    }

    func deleteNode(node: SceneNode){
        db.child(FirebaseManager.modelsTableName).child(node.id).removeValue()
    }

    func observeOnDelegate(_ delegate: FirebaseManagerDelegate?){
        //TODO: block might be out of scope
        db.child(FirebaseManager.modelsTableName).observe(.childAdded, with: { (snapshot) -> Void in
            if let nodeData = snapshot.value as? [String : AnyObject], let type = nodeData[FirebaseManager.modelsTable_typeColumn] as? String, let transform = nodeData[FirebaseManager.modelsTable_transformColumn] as? [Float] {
                delegate?.didAddNode(
                    node: SceneNode(
                        id: snapshot.key,
                        type: NodeAssetType.getType(typeName: type),
                        transformAsArray: transform))
            }
        })

        db.child(FirebaseManager.modelsTableName).observe(.childChanged, with: { (snapshot) -> Void in
            if let nodeData = snapshot.value as? [String : AnyObject] {
                delegate?.didChangeNode(
                    node: SceneNode(
                        id: snapshot.key,
                        type: NodeAssetType.getType(typeName: nodeData[FirebaseManager.modelsTable_typeColumn] as! String),
                        transformAsArray: nodeData[FirebaseManager.modelsTable_transformColumn] as! [Float]))
            }
        })

        db.child(FirebaseManager.modelsTableName).observe(.childRemoved, with: { (snapshot) -> Void in
            delegate?.didRemoveNode(id: snapshot.key)
        })
    }

    func getCurrentDatabase(didGetNodes: @escaping ([SceneNode]?) -> Void) {
        db.child(FirebaseManager.modelsTableName).observeSingleEvent(of: .value, with: {(snapshot) in
            if let databaseSnapshot = snapshot.value as? [String : [String : AnyObject]] {
                didGetNodes(FirebaseManager.getSceneNodes(databaseSnapshot: databaseSnapshot) )
            }
        })
    }

    static func transformToArray(transform: SCNMatrix4) -> Array<Float>{
        //Ready transform as matrix
        return [
            transform.m11, transform.m12, transform.m13, transform.m14,
            transform.m21, transform.m22, transform.m23, transform.m24,
            transform.m31, transform.m32, transform.m33, transform.m34,
            transform.m41, transform.m42, transform.m43, transform.m44
        ]
    }

    static func arrayToTransform(transformAsArray: Array<Float>) -> SCNMatrix4{
        //Ready transform as matrix
        return SCNMatrix4(m11: transformAsArray[0], m12: transformAsArray[1], m13: transformAsArray[2], m14: transformAsArray[3],
                          m21: transformAsArray[4], m22: transformAsArray[5], m23: transformAsArray[6], m24: transformAsArray[7],
                          m31: transformAsArray[8], m32: transformAsArray[9], m33: transformAsArray[10], m34: transformAsArray[11],
                          m41: transformAsArray[12], m42: transformAsArray[13], m43: transformAsArray[14], m44: transformAsArray[15])
    }

    static func getSceneNodes(databaseSnapshot: [String : [String : AnyObject]]) -> Array<SceneNode> {
        var listOfSceneNodes: Array<SceneNode> = Array()

        let models = databaseSnapshot
        for (modelID, modelData) in models {
            let modelDataAsDictionary = modelData
            if let nodeType = modelDataAsDictionary[FirebaseManager.modelsTable_typeColumn] as? String, let nodeTransform = modelDataAsDictionary[FirebaseManager.modelsTable_transformColumn] as? NSArray, let transformArray = nodeTransform as? Array<Float> {
                listOfSceneNodes.append(SceneNode(id: modelID, type: NodeAssetType.getType(typeName: nodeType), transformAsArray: transformArray))
            }
        }
        return listOfSceneNodes
    }
}


struct SceneNode {
    var id: String
    var type: NodeAssetType
    var transform: SCNMatrix4

    init(id: String, type: NodeAssetType, transformAsArray: Array<Float>) {
        self.id = id
        self.type = type
        self.transform = FirebaseManager.arrayToTransform(transformAsArray: transformAsArray)
    }

    init(id: String, type: NodeAssetType, transform: SCNMatrix4) {
        self.id = id
        self.type = type
        self.transform = transform
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
