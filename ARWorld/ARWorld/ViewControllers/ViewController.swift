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


class ViewController: UIViewController {

    // MARK: - UIViews
    
    @IBOutlet var sceneView: ARSCNView!
    var gesturesContainer = GesturesContainer()
    var modeViewContainer = UIView()

    // MARK: - Nodes in the scene
    
    var floorAnchor: ARPlaneAnchor? // The floor the user uses to calibrate at the start
    var hitTestPlane = SCNNode()
    
    var globalNode = GlobalNode() // Anchored to position and direction of the real life arrow
    var nodes = [SudoNode]()
    
    var editingNode: SudoNode? {
        didSet {
            // Remove old animation
            if let oldNode = oldValue {
                oldNode.assetNode.removeAnimation(forKey: "SelectionBouncingAnimation")
                oldNode.assetNode.addAnimation(NodeAnimationCreator.droppingAnimation(startingValue: oldNode.assetNode.pivot), forKey: "DroppingAnimation")
                
                if let circle = oldNode.sceneNode.childNode(withName: "editingCircle", recursively: true) {
                    circle.shrinkAndRemove()
                }
            }

            // Add new animation
            if let newNode = editingNode {
                newNode.assetNode.addAnimation(NodeAnimationCreator.bouncingAnimation(), forKey: "SelectionBouncingAnimation")
                newNode.sceneNode.addChildNode(NodeAnimationCreator.editingCircleScaledToFit(maxSize: 0.5))
            }
        }
    }
    
    // MARK: - Mode-Related Variables
    
    var initialEditingScale: CGFloat = 1
    var previousRotation: CGFloat? = nil
    
    var hitTestPlaneForPanning = SCNNode()
    var initialNodePosition: SCNVector3? = nil
    
    var mode: InteractionMode = .waitingForAnchorLocation {
        didSet {
            switch mode {
            case .waitingForAnchorLocation:
                hitTestPlane.isHidden = true
                
                let newView: WaitingForAnchorLocationView = WaitingForAnchorLocationView.initFromNib()
                newView.delegate = self
                gesturesContainer.delegate = newView
                
                setContainerViewToView(newView)

            case  .draggingAnchorDirection:
                
                let newView: CalibrationView = CalibrationView.initFromNib()
                newView.delegate = self
                gesturesContainer.delegate = newView

                setContainerViewToView(newView)
                
                hitTestPlane.isHidden = false
                hitTestPlane.position = .zero
                hitTestPlane.boundingBox.min = SCNVector3(x: -1000, y: 0, z: -1000)
                hitTestPlane.boundingBox.max = SCNVector3(x: 1000, y: 0, z: 1000)
                
            case .normal:
                self.hitTestPlane.isHidden = true
                let newView: NormalModeView = NormalModeView.initFromNib()
                newView.delegate = self
                gesturesContainer.delegate = newView
                
                setContainerViewToView(newView)
                break
                
            case .editing:
                let newView: EditingModeView = EditingModeView.initFromNib()
                newView.delegate = self
                gesturesContainer.delegate = newView

                setContainerViewToView(newView)
                break
            }
        }
    }
    
    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configSceneView(sceneView: sceneView)

        // Mode View
        view.addSubview(modeViewContainer)
        modeViewContainer.constrainEdges(to: view)

        // Gestures container
        view.addSubview(gesturesContainer)
        gesturesContainer.constrainEdges(to: view)        
        
        // Firebase
        FirebaseManager.shared.getCurrentDatabase { fbNodes in
            if let fbNodes = fbNodes {
                self.nodes = fbNodes.map { SudoNode(fbNode: $0) }
            }
        }
        resetNodes()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    // MARK: - Setup
    
    private func configSceneView(sceneView: ARSCNView) {
        sceneView.delegate = self
        //        sceneView.showsStatistics = true
        sceneView.debugOptions  = [.showConstraints, ARSCNDebugOptions.showFeaturePoints]
        // ARSCNDebugOptions.showWorldOrigin
    }
    
    private func resetNodes() {
        hitTestPlane.isHidden = true
        globalNode.isHidden = true

        sceneView.scene.rootNode.addChildNode(globalNode)
        
        mode = .waitingForAnchorLocation
        floorAnchor = nil

        globalNode.addChildNode(hitTestPlane)
        
        let axisNode = NodeCreator.createAxesNode(quiverLength: 0.7, quiverThickness: 1)
        globalNode.addChildNode(axisNode)
    }
    
    private func setContainerViewToView(_ view: UIView) {
        for view in modeViewContainer.subviews {
            view.removeFromSuperview()
        }
        modeViewContainer.addSubview(view)
        view.constrainEdges(to: modeViewContainer)
    }
    
    // MARK: - Set Object
    
    private func newSudoNode(assetType: NodeAssetType, worldHitTestAt screenCoordinates: CGPoint) -> SudoNode? {
        let hit = sceneView.realWorldHit(at: screenCoordinates)
        guard let hitTestInWorld = hit.transformInWorld else { return nil }
        
        let worldInGlobal = SCNMatrix4Invert(globalNode.transform)
        let hitTestInGlobal = SCNMatrix4Mult(hitTestInWorld, worldInGlobal)
        
        return SudoNode(nodeAssetType: assetType, nodeInGlobal: hitTestInGlobal)
    }
    
    // MARK: - Appending New Nodes

    private func addToNodesAndGlobalNode(node: SudoNode) {
        nodes.append(node)
        globalNode.addChildNode(node.sceneNode)
    }
    
    private func addToGlobalNode(nodes: [SudoNode]) {
        for node in nodes {
            globalNode.addChildNode(node.sceneNode)
        }
    }
    
    // MARK: - Session
    
    private func restartSession() {
        self.sceneView.session.pause()
        self.sceneView.scene.rootNode.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
        }
        
        resetNodes()

        self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    private var configuration: ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        return configuration
    }
}

extension ViewController: ARSCNViewDelegate {
    
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
}

extension ViewController: FirebaseManagerDelegate {
    
    func didAddNode(node: FirebaseNode) {
        let sudoNode = SudoNode(fbNode: node)
        if !nodes.contains(sudoNode) {
            addToNodesAndGlobalNode(node: sudoNode)
        }
    }
    
    func didChangeNode(node: FirebaseNode) {
        didRemoveNode(id: node.id)
        let newSudoNode = SudoNode(fbNode: node)
        addToNodesAndGlobalNode(node: newSudoNode)
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
    
    func setGlobalNode(worldHitTestAt screenCoordinates: CGPoint) {
        let hit = sceneView.realWorldHit(at: screenCoordinates)
        if let hitTestInWorld = hit.transformInWorld, let plane = hit.planeAnchor {
            globalNode.isHidden = false
            globalNode.transform = hitTestInWorld
            floorAnchor = plane
            
            // Once the user hits a usable real-world plane, switch into line-dragging mode
            mode = .draggingAnchorDirection
        }
    }
}

extension ViewController: CalibrationViewDelegate {
    
    func handleInitialCalibrationDrag(at screenCoordinates: CGPoint) {
        if let hitTestInWorld = sceneView.sceneHitTest(at: screenCoordinates, within: hitTestPlane) {
            let globalNodeInWorld = globalNode.position
            
            let delta = globalNodeInWorld - hitTestInWorld
            globalNode.setCalibrationArrowWidth(delta.length)
            let angleInRadians = atan2(delta.z, delta.x)
            globalNode.rotation = SCNVector4(x: 0, y: 1, z: 0, w: -(angleInRadians + Float.pi))
        }
    }
    
    func calibrationDone() {
        mode = .normal
        
        // self.nodes are are fetched in viewDidLoad
        addToGlobalNode(nodes: nodes)
        
        FirebaseManager.shared.observeOnDelegate(self)
        globalNode.geometry = nil
    }
}

extension ViewController: NormalModeViewDelegate {
    
    func selectSudoNodeForEditing(screenCoordinates: CGPoint) {
        let hit = sceneView.hitTest(screenCoordinates, options: nil)
        
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
        let screenCoordinates = CGPoint(x: view.bounds.midX, y: 2 * (view.bounds.height / 3))
        if let newNode = newSudoNode(assetType: assetType, worldHitTestAt: screenCoordinates) {
            addToNodesAndGlobalNode(node: newNode)
            editingNode = newNode
            mode = .editing
        }
    }
    
    /// Find the same instance of target node or its parent
    private func findNode(targetNode: SCNNode, in nodes: [SudoNode]) -> SudoNode? {
        for node in nodes {
            if let _ = findNode(targetNode: targetNode, in: [node.sceneNode]) {
                return node
            }
        }
        return nil
    }
    
    private func findNode(targetNode: SCNNode, in nodes: [SCNNode]) -> SCNNode? {
        return nodes.filter {
            return $0 === targetNode || findNode(targetNode: targetNode, in: $0.childNodes) != nil
        }.first
    }
}

extension ViewController: EditingModeViewDelegate {
    // Tap
    func editTapped(screenCoordinates: CGPoint) {
        if let hitTestInWorld = sceneView.realWorldHit(at: screenCoordinates).transformInWorld {
            let hitTestPositionInWorld = SCNVector3(hitTestInWorld.m41, hitTestInWorld.m42, hitTestInWorld.m43)
            editingNode?.worldPosition = hitTestPositionInWorld
        }
    }

    // Pan TODO pan only along a flat plane.
    func editPanDidBegin(screenCoordinates: CGPoint) {
//        if let editingNode = editingNode {
//
//            // Save the first plane we hit
//            let plane = SCNPlane(width: 5, height: 5)
//            plane.firstMaterial?.diffuse.contents = #colorLiteral(red: 0.0499236755, green: 0.9352593591, blue: 0.0003146826744, alpha: 0.6324111729)
//
//            let planeNode = SCNNode()
//            planeNode.geometry = plane
//            planeNode.worldPosition = editingNode.worldPosition
//            // SCNPlanes are vertically oriented in their local coordinate space.
//            // Rotate it to match the horizontal orientation of the ARPlaneAnchor.
//            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
//            planeNode.addChildNode(NodeCreator.blueBox())
//            globalNode.addChildNode(planeNode)
//            hitTestPlaneForPanning = planeNode // TODO: This isn't visible?
//
//
//            // intial node position
//            initialNodePosition = editingNode.sceneNode.worldPosition
//        }
    }
    
    func editPanDidChange(screenCoordinates: CGPoint) {
        if let hitTestInWorld = sceneView.realWorldHit(at: screenCoordinates).transformInWorld {
            let hitTestPositionInWorld = SCNVector3(hitTestInWorld.m41, hitTestInWorld.m42, hitTestInWorld.m43)
            editingNode?.worldPosition = hitTestPositionInWorld
        }
    }
    
    func editPanDidEnd(screenCoordinates: CGPoint) {
        initialNodePosition = nil
    }

    // Pinch
    func pinchDidBegin(scale: CGFloat) {
        initialEditingScale = CGFloat(editingNode?.scale.x ?? 1)
        let newScale = initialEditingScale * scale
        editingNode?.scale = SCNVector3(newScale, newScale, newScale)
//         print("PINCH BEGIN with factor \(scale)")
    }
    
    func pinchDidChange(scale: CGFloat) {
        let newScale = initialEditingScale * scale
        editingNode?.scale = SCNVector3(newScale, newScale, newScale)
        print("scaling with factor \(newScale)")
    }
    
    func pinchDidEnd(scale: CGFloat) {
        let newScale = initialEditingScale * scale
        editingNode?.scale = SCNVector3(newScale, newScale, newScale)
        initialEditingScale = 1
    }
    
    // Rotate
    func rotationDidBegin(rotation: CGFloat) {
//        print("ROTATION BEGIN with rotation \(rotation)")

        if let node = editingNode {
            node.eulerAngles.setAxis(.y, to: node.eulerAngles.y + Float(rotation) * Constants.Transformation.rotationFactor)
        }
        
//        previousRotation = rotation
    }
    
    func rotationDidChange(rotation: CGFloat) {
//        guard let previousRotation = previousRotation else {
//            return
//        }
        
//        let rotationDelta = rotation - previousRotation
//        print("rotation with angle \(rotationDelta)")
//
//        if let node = editingNode {
//            node.eulerAngles.setAxis(.y, to: node.eulerAngles.y + Float(rotationDelta) * Constants.Transformation.rotationFactor)
//        }
//        self.previousRotation = rotation
        
        
        
        if let node = editingNode {
            node.eulerAngles.setAxis(.y, to: node.eulerAngles.y + Float(rotation))// * Constants.Transformation.rotationFactor)
        }
//        self.previousRotation = rotation
    }
    
    func rotationDidEnd(rotation: CGFloat) {
//        previousRotation = nil
    }
    
    // Buttons
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
