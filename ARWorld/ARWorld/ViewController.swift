//
//  ViewController.swift
//  ARWorld
//
//  Created by TSD044 on 2018-02-02.
//  Copyright © 2018 sudo-world. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var scene: SCNScene!
    
    var assetScene: SCNScene!
    
    var rootNode: SCNNode!
    
    var rootNodeAsset: SCNNode!
    
    var globalNode: SCNNode?
    
    var floor: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.debugOptions = [.showBoundingBoxes, .showLightExtents]

        scene = sceneView.scene
        rootNode = scene.rootNode

        assetScene = SCNScene(named: "art.scnassets/ship.scn")
        
        floor = FloorModel.initializeNode()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    

    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        if anchor is ARPlaneAnchor, globalNode == nil {
            globalNode = SCNNode()
            globalNode?.simdTransform = anchor.transform
            return globalNode
        }
        return nil
    }
    
    // MARK: IB Actions
    @IBAction func shipButtonTapped(_ sender: UIButton) {
        if let shipNode = assetScene.rootNode.childNode(withName: "ShipModel", recursively: false) {
            // TODO: shipNode.transform =
            globalNode?.addChildNode(shipNode)
        }
    }
    
    @IBAction func boxButtonTapped(_ sender: UIButton) {
        if let boxModel = assetScene.rootNode.childNode(withName: "BoxModel", recursively: false) {
            globalNode?.addChildNode(boxModel)
        }
    }
    
    
}
