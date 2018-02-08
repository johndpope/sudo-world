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
    case normal
    case editing
//    case draggingNewObject
}

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var modeViewContainer: UIView!
    
    
    var floorAnchor: ARPlaneAnchor? // The floor the user uses to calibrate at the start
    var globalNode = GlobalNodeClass() // Anchored on start of the real life arrow
    var hitTestPlane = SCNNode()
    var panGesture: UIPanGestureRecognizer!
    var tapGesture: UITapGestureRecognizer!

    var editingNode: SudoNode?
    
//    var allSceneNodes: [FirebaseNode]?
    var allMenuAssets = [NodeAssetType]()

//    var allNodesDisplayed = [SCNNode]() // Populated from firebase
    var previousRotation: CGFloat? = nil
    var nodes = [SudoNode]()
    
    
    var mode: InteractionMode = .waitingForAnchorLocation {
        didSet {
            switch mode {
            case .waitingForAnchorLocation:
                hitTestPlane.isHidden = true
                let newView = WaitingForAnchorLocationView.initFromNib() as! WaitingForAnchorLocationView
                newView.delegate = self
                setContainerViewToView(newView)

            case  .draggingAnchorDirection:
                let newView = CalibrationView.initFromNib() as! CalibrationView
                newView.delegate = self
                setContainerViewToView(newView)
                hitTestPlane.isHidden = false
                hitTestPlane.position = .zero
                hitTestPlane.boundingBox.min = SCNVector3(x: -1000, y: 0, z: -1000)
                hitTestPlane.boundingBox.max = SCNVector3(x: 1000, y: 0, z: 1000)
                
            case .normal:
                self.hitTestPlane.isHidden = true
                let newView = NormalModeView.initFromNib() as! NormalModeView
                newView.delegate = self
                setContainerViewToView(newView)
                break
            case .editing:
                let newView = EditingModeView.initFromNib() as! EditingModeView
                newView.delegate = self
                setContainerViewToView(newView)
                break
            }
        }
    }
    
    private func setContainerViewToView(_ view: UIView) {
        for view in modeViewContainer.subviews {
            view.removeFromSuperview()
        }
        self.modeViewContainer.addSubview(view)
    }
    
    
    var configuration: ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        return configuration
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configSceneView(sceneView: sceneView)
        
        FirebaseManager.shared.getCurrentDatabase { (fbNodes) in
            if let fbNodes = fbNodes {
                self.nodes = fbNodes.map({SudoNode(fbNode: $0)})
            }
        }
        resetNodes()
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

    // setting the objects
    func setObject(asset: NodeAssetType) -> SudoNode? {
        let hit = realWorldHit(at: CGPoint(x: view.bounds.midX, y: 2 * (view.bounds.height / 3)))
        
        if let worldToHitTest = hit.transformInWorld {
            
            if let clonedNode = asset.initializeNode() {
                let globalNodeToWorld = SCNMatrix4Invert(globalNode.transform)
                let globalNodeToHitTest = SCNMatrix4Mult(worldToHitTest, globalNodeToWorld)
                
                clonedNode.transform = globalNodeToHitTest
                let sudoNode = SudoNode(sceneNode: clonedNode, type: asset)
                addNodeToNodes(node: sudoNode)
                return sudoNode
            }
        }
        return nil
    }
    
    var axisNode = NodeCreator.createAxesNode(quiverLength: 0.7, quiverThickness: 1)
    
    func findStartingLocation(location: CGPoint) {
        // Use real-world ARKit coordinates to determine where to start drawing
        let touchPos = location
        let hit = realWorldHit(at: touchPos)
        if let hitTransformInWorld = hit.transformInWorld, let plane = hit.planeAnchor {
            // Once the user hits a usable real-world plane, switch into line-dragging mode
            globalNode.isHidden = false
            globalNode.transform = hitTransformInWorld
            floorAnchor = plane
            mode = .draggingAnchorDirection
        }
    }
    
    func handleInitialCalibrationDrag(location: CGPoint) {
        
        let touchPos = location
        if let hitTestlocationInWorld = scenekitHit(at: touchPos, within: hitTestPlane) {
            let delta = globalNode.position - hitTestlocationInWorld
            let distance = delta.length
            let angleInRadians = atan2(delta.z, delta.x)
            self.globalNode.setAttachedGeometryWidth(endpointInWorld: hitTestlocationInWorld, newWidth: distance)
            globalNode.rotation = SCNVector4(x: 0, y: 1, z: 0, w: -(angleInRadians + Float.pi))
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
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {//
        print("didRemove \(node.position)")
    }

    // calibration finishes
    func addAllNodesToGlobalNode() {
        for node in nodes {
            globalNode.addChildNode(node.sceneNode)
        }
    }
    
    func addNodeToNodes(node: SudoNode) {
        nodes.append(node)
        globalNode.addChildNode(node.sceneNode)
    }
    
    private func restartSession() {
        self.sceneView.session.pause()
        self.sceneView.scene.rootNode.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
        }
        
        resetNodes()

        self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
}

extension ViewController: FirebaseManagerDelegate {
    func didAddNode(node: FirebaseNode) {
        // add node on the scene
        let sudoNode = SudoNode(fbNode: node)
        if !nodes.contains(sudoNode) {
            addNodeToNodes(node: sudoNode)
        }
    }
    
    func didChangeNode(node: FirebaseNode) {
        didRemoveNode(id: node.id)
        let newSudoNode = SudoNode(fbNode: node)
        addNodeToNodes(node: newSudoNode)
    }

    func didRemoveNode(id: String) {
        let ids = nodes.map({$0.id})
        if let index = ids.index(of: id) {
            let oldNode = nodes[index]
            oldNode.sceneNode.removeFromParentNode()
            nodes.remove(at: index)
        }
    }
}

extension ViewController: WaitingForAnchorLocationViewDelegate {
    
    func panGestureBeganOrChanged(screenCoordinates: CGPoint) {
        findStartingLocation(location: screenCoordinates)
    }
    
}

extension ViewController: CalibrationViewDelegate {
    
    func calibrationPanGestureBegan(screenCoordinates: CGPoint) {
        handleInitialCalibrationDrag(location: screenCoordinates)
    }
    
    func calibrationPanGestureChanged(screenCoordinates: CGPoint) {
        handleInitialCalibrationDrag(location: screenCoordinates)
    }
    
    func calibrationDone() {
        mode = .normal
        addAllNodesToGlobalNode()
        FirebaseManager.shared.observeOnDelegate(self)
        globalNode.geometry = nil
    }
    
    
}

extension ViewController: NormalModeViewDelegate {
    func didRecieveTap(screenLocation: CGPoint) {
        let hit = sceneView.hitTest(screenLocation, options: nil)
        
        for hitTestResult in hit {
            if let parentNode = findNode(targetNode: hitTestResult.node, in: nodes) {
                self.editingNode = parentNode
                print("Hit Test Result: \(editingNode.debugDescription)")
                mode = .editing
            }
            return
        }
    }
    
    func resetRequested() {
        restartSession()
    }
    
    func didSelectNewNodeToInsert(assetType: NodeAssetType) {
        if let newNode = setObject(asset: assetType) {
            editingNode = newNode
            mode = .editing
        }
    }
    
    /// Find the same instance of target node or its parent
    func findNode(targetNode: SCNNode, in nodes: [SudoNode]) -> SudoNode? {
        for node in nodes {
            if let _ = findNode(targetNode: targetNode, in: [node.sceneNode]) {
                return node
            }
        }
        return nil
    }
    
    func findNode(targetNode: SCNNode, in nodes: [SCNNode]) -> SCNNode? {
        return nodes.filter {
            return $0 === targetNode || findNode(targetNode: targetNode, in: $0.childNodes) != nil
        }.first
    }
}

extension ViewController: EditingModeViewDelegate {
    
    func editPanDidChange(screenCoordinates: CGPoint) {
        if let hitTestTransformInWorld = realWorldHit(at: screenCoordinates).transformInWorld {
            let hitTestPositionInWorld = SCNVector3(hitTestTransformInWorld.m41, hitTestTransformInWorld.m42, hitTestTransformInWorld.m43)
            editingNode?.worldPosition = hitTestPositionInWorld
        }
    }
    
    func pinchDidChange(scale: CGFloat) {
        editingNode?.scale = SCNVector3(scale, scale, scale)
    }
    
    func rotationDidBegin(rotation: CGFloat) {
        previousRotation = rotation
    }
    
    func rotationDidChange(rotation: CGFloat) {
        guard let previousRotation = previousRotation else {
            return
        }
        
        let rotationDelta = rotation - previousRotation
        print("rotation with angle \(rotationDelta)")
        
        if let node = editingNode {
            node.eulerAngles.setAxis(.y, to: node.eulerAngles.y + Float(rotationDelta) * Constants.Transformation.rotationFactor)
        }
        self.previousRotation = rotation
    }
    
    func rotationDidEnd(rotation: CGFloat) {
        previousRotation = nil
    }
    
    func doneButtonPressed() {
        editingNode?.pushChanges()
        editingNode = nil
        mode = .normal
    }
    
    func trashButtonPressed() {
        if let node = editingNode {
            node.sceneNode.removeFromParentNode()
            FirebaseManager.shared.deleteNode(node: node.fireBaseNode)
        }
        editingNode = nil
        mode = .normal
    }
    
    
}
