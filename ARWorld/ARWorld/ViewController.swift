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
    case settingObjects
}

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var floorAnchor: ARPlaneAnchor? // The floor the user uses to calibrate at the start
    var globalNode = GlobalNodeClass() // Anchored on start of the real life arrow
    var hitTestPlane = SCNNode()
    var panGesture: UIPanGestureRecognizer!

    var currentNodeBeingAdded: SCNNode?
    
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
                
            case .settingObjects:
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

        resetNodes()
    }
    
    func resetNodes() {
        hitTestPlane.isHidden = true
        globalNode.isHidden = true

        sceneView.scene.rootNode.addChildNode(globalNode)
//        globalNode.resizeTo(min: .zero, max: .zero)
        
        mode = .waitingForAnchorLocation
        floorAnchor = nil
        
        globalNode.addChildNode(hitTestPlane)
        globalNode.addChildNode(axisNode)
    }
    
    func configSceneView(sceneView: ARSCNView) {
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.debugOptions  = [.showConstraints, .showLightExtents, ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
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
    
    @objc dynamic func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch mode {
        case .waitingForAnchorLocation:
            findStartingLocation(gestureRecognizer)
        case .draggingAnchorDirection:
            handleInitialCalibrationDrag(gestureRecognizer)
        case .settingObjects:
            break
        }
    }
    
    var axisNode = NodeCreator.createAxesNode(quiverLength: 0.7, quiverThickness: 1)
    
    func findStartingLocation(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began, .changed:
            // Use real-world ARKit coordinates to determine where to start drawing
            let touchPos = gestureRecognizer.location(in: sceneView)
            let hit = realWorldHit(at: touchPos)
            if let startPos = hit.position, let plane = hit.planeAnchor {
                
                // Once the user hits a usable real-world plane, switch into line-dragging mode
                globalNode.isHidden = false
                globalNode.position = startPos
                floorAnchor = plane
                mode = .draggingAnchorDirection
//
//                let newNode = NodeCreator.orangeBox
//                globalNode.addChildNode(newNode)
//                newNode.transform = SCNMatrix4MakeTranslation(startPos.x, startPos.y, startPos.z)
                
//                axisNode.transform = SCNMatrix4Identity

            }
        default:
            break
        }
    }
    
    func handleInitialCalibrationDrag(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .changed:
//            print("gesture rec CHANGED")

            let touchPos = gestureRecognizer.location(in: sceneView)
            if let hitTestlocationInWorld = scenekitHit(at: touchPos, within: hitTestPlane) {
//                // This drags a line out that determines the box's width and its orientation:
//                // The box's front will face 90 degrees clockwise out from the line being dragged.
                let delta = globalNode.position - hitTestlocationInWorld
                let distance = delta.length

                let angleInRadians = atan2(delta.z, delta.x)

                self.globalNode.setAttachedGeometryWidth(endpointInWorld: hitTestlocationInWorld, newWidth: distance)
                
//                print("touch pos \(hitTestlocationInWorld)")
                
                
               globalNode.rotation = SCNVector4(x: 0, y: 1, z: 0, w: -(angleInRadians + Float.pi))
                
//                globalNode.transform = SCNMatrix4Translate(globalNode.transform, delta.x, delta.y, delta.z)
                
                print("new global position \(globalNode.position)")
            }
        case .ended, .cancelled:
            print("gesture rec ENDED OR CANCELED")

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
    
    func realWorldHit(at screenPos: CGPoint) -> (position: SCNVector3?, planeAnchor: ARPlaneAnchor?, hitAPlane: Bool) {
        
        // -------------------------------------------------------------------------------
        // 1. Always do a hit test against exisiting plane anchors first.
        //    (If any such anchors exist & only within their extents.)
        
        let planeHitTestResults = sceneView.hitTest(screenPos, types: .existingPlaneUsingExtent)
        if let result = planeHitTestResults.first {
            
            let planeHitTestPosition = SCNVector3.positionFromTransform(result.worldTransform)
            let planeAnchor = result.anchor
            
            // Return immediately - this is the best possible outcome.
            return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
        }
        
        // -------------------------------------------------------------------------------
        // 2. Collect more information about the environment by hit testing against
        //    the feature point cloud, but do not return the result yet.
        
        var featureHitTestPosition: SCNVector3?
        var highQualityFeatureHitTestResult = false
        
        let highQualityfeatureHitTestResults = sceneView.hitTestWithFeatures(screenPos, coneOpeningAngleInDegrees: 18, minDistance: 0.2, maxDistance: 2.0)
        
        if !highQualityfeatureHitTestResults.isEmpty {
            let result = highQualityfeatureHitTestResults[0]
            featureHitTestPosition = result.position
            highQualityFeatureHitTestResult = true
        }
        
        // -------------------------------------------------------------------------------
        // 4. If available, return the result of the hit test against high quality
        //    features if the hit tests against infinite planes were skipped or no
        //    infinite plane was hit.
        
        if highQualityFeatureHitTestResult {
            return (featureHitTestPosition, nil, false)
        }
        
        // -------------------------------------------------------------------------------
        // 5. As a last resort, perform a second, unfiltered hit test against features.
        //    If there are no features in the scene, the result returned here will be nil.
        
        let unfilteredFeatureHitTestResults = sceneView.hitTestWithFeatures(screenPos)
        if !unfilteredFeatureHitTestResults.isEmpty {
            let result = unfilteredFeatureHitTestResults[0]
            return (result.position, nil, false)
        }
        
        return (nil, nil, false)
    }
    
    
    
    // MARK: - ARSCNViewDelegate
    

    // Override to create and configure nodes for anchors added to the view's session.
//    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
//        guard let planeAnchor = anchor as? ARPlaneAnchor else { return nil }
//
//
//
//    }
    
//    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
//    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        print("didAdd \(node.position)")

        let planeNode: SCNNode
//        if globalNode == nil {
//            planeNode = NodeCreator.greenPlane(anchor: planeAnchor)
//            globalNode = planeNode
//        } else {
            planeNode = NodeCreator.bluePlane(anchor: planeAnchor)
//        }

        // ARKit owns the node corresponding to the anchor, so make the plane a child node.
        node.addChildNode(planeNode)
    }

    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        print("didUpdate \(node.pivot)")

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
        
//        let oldPivot = node.pivot
//        node.pivot = SCNMatrix4Translate(oldPivot, -planeAnchor.center.x, -planeAnchor.center.y, -planeAnchor.center.z)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {//
        print("didRemove \(node.position)")
    }
    
    // MARK: IB Actions
    @IBAction func boxButtonTapped(_ sender: UIButton) {
        let newBox = NodeCreator.orangeBox
        newBox.position = SCNVector3(0.1, 0.1, 0.1)
        globalNode.addChildNode(newBox)
        
        let newBox2 = NodeCreator.greenBox
//        newBox2.position = SCNVector3(, 0.1, 0.1)
        globalNode.addChildNode(newBox2)
    }
    
    @IBAction func resetButtonTapped(_ sender: Any) {
        self.restartSession()
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


struct SceneNodeData {
    var name: String
    var transform: SCNMatrix4
}
