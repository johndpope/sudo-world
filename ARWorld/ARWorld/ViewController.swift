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

enum InteractionMode {
    case waitingForAnchorLocation
    case draggingAnchorDirection
    case waitingForSettingNewObject
//    case draggingNewObject
}

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var menuCollectionView: MenuCollectionView!
    
    var floorAnchor: ARPlaneAnchor? // The floor the user uses to calibrate at the start
    var globalNode = GlobalNodeClass() // Anchored on start of the real life arrow
    var hitTestPlane = SCNNode()
    var panGesture: UIPanGestureRecognizer!
    var tapGesture: UITapGestureRecognizer!

    var currentNodeTypeBeingAdded: NodeAssetType = .box
    
    var allSceneNodes: [SceneNode]?
    var allMenuAssets = [NodeAssetType]()

    var allNodesDisplayed = [SCNNode]() // Populated from firebase
    
    var mode: InteractionMode = .waitingForAnchorLocation {
        didSet {
            switch mode {
            case .waitingForAnchorLocation:
                hitTestPlane.isHidden = true

            case  .draggingAnchorDirection:
                hitTestPlane.isHidden = false
                hitTestPlane.position = .zero
                hitTestPlane.boundingBox.min = SCNVector3(x: -1000, y: 0, z: -1000)
                hitTestPlane.boundingBox.max = SCNVector3(x: 1000, y: 0, z: 1000)
                
            case .waitingForSettingNewObject:
                break
            }
        }
    }
    
    var configuration: ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        return configuration
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configSceneView(sceneView: sceneView)
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        sceneView.addGestureRecognizer(panGesture)
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        sceneView.addGestureRecognizer(tapGesture)
        FirebaseManager.shared.getCurrentDatabase { (sceneNodes) in
            self.allSceneNodes = sceneNodes
        }
        resetNodes()
        
        menuCollectionView.menuCollectionDelegate = self
    }
    
    func resetNodes() {
        hitTestPlane.isHidden = true
        globalNode.isHidden = true

        sceneView.scene.rootNode.addChildNode(globalNode)
        
        mode = .waitingForAnchorLocation
        floorAnchor = nil

        globalNode.addChildNode(hitTestPlane)
        globalNode.addChildNode(axisNode)
    }

    func configSceneView(sceneView: ARSCNView) {
        sceneView.delegate = self
//        sceneView.showsStatistics = true
        sceneView.debugOptions  = [.showConstraints, ARSCNDebugOptions.showFeaturePoints]
        // ARSCNDebugOptions.showWorldOrigin
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    // MARK: - Touch handling
    
    var isCollectionViewActionEnabled = true
    
    @objc dynamic func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        switch mode {
        case .waitingForAnchorLocation:
            break
        case .draggingAnchorDirection:
            break
        case .waitingForSettingNewObject:
            isCollectionViewActionEnabled = false
            setObject(gestureRecognizer)
            isCollectionViewActionEnabled = true
            break
        }
    }
    
    @objc dynamic func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch mode {
        case .waitingForAnchorLocation:
            findStartingLocation(gestureRecognizer)
        case .draggingAnchorDirection:
            handleInitialCalibrationDrag(gestureRecognizer)
        case .waitingForSettingNewObject:
            break
        }
    }

    // setting the objects
    func setObject(_ gestureRecognizer: UITapGestureRecognizer) {
        let touchPos = gestureRecognizer.location(in: sceneView)
        let hit = realWorldHit(at: touchPos)
        
        if let worldToHitTest = hit.transformInWorld {
            
            if let clonedNode = currentNodeTypeBeingAdded.initializeNode() {
                print("adding node \(currentNodeTypeBeingAdded)")
                let globalNodeToWorld = SCNMatrix4Invert(globalNode.transform)
                let globalNodeToHitTest = SCNMatrix4Mult(worldToHitTest, globalNodeToWorld)
                
                clonedNode.transform = globalNodeToHitTest
                globalNode.addChildNode(clonedNode)
                addSCNNodeToAllSceneNodes(node: clonedNode)
            }

        }
    }

    func addSCNNodeToAllSceneNodes(node: SCNNode) {
        if let name = node.name {
            let sceneNode = FirebaseManager.shared.insertNode(type: currentNodeTypeBeingAdded, transform: node.transform)
            allSceneNodes?.append(sceneNode)
        }
    }
    
    var axisNode = NodeCreator.createAxesNode(quiverLength: 0.7, quiverThickness: 1)
    
    func findStartingLocation(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began, .changed:
            // Use real-world ARKit coordinates to determine where to start drawing
            let touchPos = gestureRecognizer.location(in: sceneView)
            let hit = realWorldHit(at: touchPos)
            if let hitTransformInWorld = hit.transformInWorld, let plane = hit.planeAnchor {
                // Once the user hits a usable real-world plane, switch into line-dragging mode
                globalNode.isHidden = false
                globalNode.transform = hitTransformInWorld
                floorAnchor = plane
                mode = .draggingAnchorDirection
            }
        default:
            break
        }
    }
    
    func handleInitialCalibrationDrag(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .changed:
            
            let touchPos = gestureRecognizer.location(in: sceneView)
            if let hitTestlocationInWorld = scenekitHit(at: touchPos, within: hitTestPlane) {
                let delta = globalNode.position - hitTestlocationInWorld
                let distance = delta.length
                let angleInRadians = atan2(delta.z, delta.x)
                self.globalNode.setAttachedGeometryWidth(endpointInWorld: hitTestlocationInWorld, newWidth: distance)
               globalNode.rotation = SCNVector4(x: 0, y: 1, z: 0, w: -(angleInRadians + Float.pi))
            }
        case .ended, .cancelled:
            print("gesture rec ENDED OR CANCELED")

            // TODO if we have time
            // Check that the length is around the same length as our physical arrow
//            if abs(globalNode.boundingBox.max.x - globalNode.boundingBox.min.x) >= globalNode.minLabelDistanceThreshold {
//                // If the box ended up with a usable width, switch to length-dragging mode.
//                mode = .draggingInitialLength
//            } else {
//                // Otherwise, give up on this drag and start again.
//                resetBox()
//            }
        default:
            break
        }
    }
    
    
    // MARK: Hit Test
    
    func scenekitHit(at screenPos: CGPoint, within rootNode: SCNNode) -> SCNVector3? {
        let hits = sceneView.hitTest(screenPos, options: [
            .boundingBoxOnly: true,
            .firstFoundOnly: true,
            .rootNode: rootNode,
            .ignoreChildNodes: true
            ])
        
        return hits.first?.worldCoordinates
    }
    
    func realWorldHit(at screenPos: CGPoint) -> (transformInWorld: SCNMatrix4?, planeAnchor: ARPlaneAnchor?, hitAPlane: Bool) {
        
        // -------------------------------------------------------------------------------
        // 1. Always do a hit test against exisiting plane anchors first.
        //    (If any such anchors exist & only within their extents.)
        
        let planeHitTestResults = sceneView.hitTest(screenPos, types: .existingPlaneUsingExtent)
        if let result = planeHitTestResults.first {
            
//            let planeHitTestPosition = SCNVector3.positionFromTransform(result.worldTransform)
            let planeAnchor = result.anchor
            
            // Return immediately - this is the best possible outcome.
            return (SCNMatrix4(result.worldTransform), planeAnchor as? ARPlaneAnchor, true)
        }
        
        // -------------------------------------------------------------------------------
        // 2. Collect more information about the environment by hit testing against
        //    the feature point cloud, but do not return the result yet.
        
        var featureHitTestTransform: SCNMatrix4?
        var highQualityFeatureHitTestResult = false
        
        let highQualityfeatureHitTestResults = sceneView.hitTestWithFeatures(screenPos, coneOpeningAngleInDegrees: 18, minDistance: 0.2, maxDistance: 2.0)
        
        if !highQualityfeatureHitTestResults.isEmpty {
            let result = highQualityfeatureHitTestResults[0]
            
            let sketchyResult = SCNMatrix4MakeTranslation(result.position.x, result.position.y, result.position.z)
            
            featureHitTestTransform = sketchyResult
            highQualityFeatureHitTestResult = true
        }
        
        // -------------------------------------------------------------------------------
        // 4. If available, return the result of the hit test against high quality
        //    features if the hit tests against infinite planes were skipped or no
        //    infinite plane was hit.
        
        if highQualityFeatureHitTestResult {
            return (featureHitTestTransform, nil, false)
        }
        
        // -------------------------------------------------------------------------------
        // 5. As a last resort, perform a second, unfiltered hit test against features.
        //    If there are no features in the scene, the result returned here will be nil.
        
        let unfilteredFeatureHitTestResults = sceneView.hitTestWithFeatures(screenPos)
        if !unfilteredFeatureHitTestResults.isEmpty {
            let result = unfilteredFeatureHitTestResults[0]
            
            let sketchyResult = SCNMatrix4MakeTranslation(result.position.x, result.position.y, result.position.z)

            return (sketchyResult, nil, false)
        }
        
        return (nil, nil, false)
    }
    
    
    
    // MARK: - ARSCNViewDelegate
    

    // Override to create and configure nodes for anchors added to the view's session.
//    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
//        guard let planeAnchor = anchor as? ARPlaneAnchor else { return nil }
//    }
    
//    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
//    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        print("didAdd \(node.position)")

        let planeNode = NodeCreator.bluePlane(anchor: planeAnchor)
        
        // ARKit owns the node corresponding to the anchor, so make the plane a child node.
        node.addChildNode(planeNode)
    }

    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

        // Update size of the geometry associated with Plane nodes
        if let plane = node.childNodes.first?.geometry as? SCNPlane {
            plane.updateSize(toMatch: planeAnchor)
        }
        
//        if planeAnchor == floorAnchor {
//            let oldPos = node.position
//            let newPos = SCNVector3.positionFromTransform(planeAnchor.transform)
//            let delta = newPos - oldPos
//            globalNode.position += delta
//        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {//
        print("didRemove \(node.position)")
    }
    
    // MARK: IB Actions
    @IBAction func resetButtonTapped(_ sender: Any) {
        self.restartSession()
    }

    // calibration finishes
    @IBAction func calibrationCompleteButton(_ sender: Any) {
        if mode == .draggingAnchorDirection {
            print("waitingForSettingNewObject MODE")
            mode = .waitingForSettingNewObject

            displayAllInitialNodes()
            FirebaseManager.shared.observeOnDelegate(self)
        }
    }

    func displayAllInitialNodes() {
        if let allSceneNodes = self.allSceneNodes {
            for sceneNode in allSceneNodes {
                let nodeAssetType = NodeAssetType(rawValue: sceneNode.type.rawValue)!
                if let node = nodeAssetType.initializeNode() {
                    node.transform = sceneNode.transform
                    globalNode.addChildNode(node)
                }
            }
        }
    }
    
    private func restartSession() {
        self.sceneView.session.pause()
        self.sceneView.scene.rootNode.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
        }
        
        resetNodes()

        self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

//    // place a model at the hit test result location
//    private func placeModel(modelType: String, assetExtension: String, hitTestInWorld: SCNMatrix4) {
//        // Get transform of result
//        // Define hitTestInWorld as it means hitTestInWorldCoordinate, etc
//
//        //        let hitTestInWorld = position
//
//        let globalNodeInWorld = g!.worldTransform
//
//        let globalNodeInWorld_Inv = SCNMatrix4Invert(globalNodeInWorld)
//
//        let hitTestInGlobalNode = matrix_float4x4(SCNMatrix4Mult(hitTestInWorld, globalNodeInWorld_Inv))
//
//        let
//
//        // Get position from transform (4th column of transformation matrix)
//        //        let hitTestInGlobalNode_Position = SCNVector3Make(hitTestInGlobalNode.columns.3.x, hitTestInGlobalNode.columns.3.y, hitTestInGlobalNode.columns.3.z)
//
//        let hitTestInGlobalNode_Position = SCNVector3Make(hitTestInGlobalNode.columns.3.x, hitTestInGlobalNode.columns.3.y, hitTestInGlobalNode.columns.3.z)
//
//
//        // Add box
//        let modelNode = createNodeFromAsset(assetType: modelType, assetExtension: assetExtension, position: hitTestInGlobalNode_Position)!
//
//        globalNode?.addChildNode(modelNode)
//    }

//    private func createNodeFromAsset(assetType: String, assetExtension: String, transform: SCNMatrix4) -> SCNNode? {
//
//        guard let url = Bundle.main.url(forResource: "art.scnassets/\(assetType)", withExtension: assetExtension) else {
//            NSLog("Could not find door scene")
//            return nil
//        }
//        guard let node = SCNReferenceNode(url: url) else { return nil }
//
//        node.load()
//
//        // Position scene
//        node.name = currentNodeTypeBeingAdded.rawValue
//        node.transform = transform
//
//        return node
//    }
}

extension ViewController: MenuCollectionViewDelegate {
    func didTapCell(assetType: NodeAssetType) {
        currentNodeTypeBeingAdded = assetType
    }
}

extension ViewController: FirebaseManagerDelegate {
    func didAddNode(node: SceneNode) {
        // add node on the scene
        self.allSceneNodes?.append(node)
        if let nodeAssetType = NodeAssetType(rawValue: node.type.rawValue),
            let newNode = nodeAssetType.initializeNode(){
            globalNode.addChildNode(newNode)
        }
    }
    
    func didChangeNode(node: SceneNode) {
        // change node on the scene
        
    }

    func didRemoveNode(id: String) {
        // remove node on the scene
    }
}
