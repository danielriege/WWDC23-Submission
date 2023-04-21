//
//  WorldScene.swift
//  WWDC23
//
//  Created by Daniel Riege on 10.04.23.
//

import Foundation
import SceneKit

/**
 This class represents the main scene used. The simulation pipeline will update the nodes in this scene with specified methods.
 */
class WorldScene: SCNScene {

    private let thirdPersonCamera: SCNNode
    private let thirdPersonCameraTransform: simd_float4x4
    private let firstPersonCamera: SCNNode
    private var robocar: SCNNode?
    private var obstacles: [SCNNode]
    private var segmentationNode: SCNNode
    private var roadGraphNode: SCNNode
    private var segmentationLights: [SCNNode]
    private var environmentNode: SCNNode
    private var showingEnvironmentNodes: Bool
    
    private var drawnPath: [SCNNode]
    private var lastPath: Path
    
    override init() {
        self.firstPersonCamera = SCNNode()
        self.thirdPersonCamera = SCNNode()
        self.environmentNode = SCNNode()
        self.segmentationNode = SCNNode()
        self.roadGraphNode = SCNNode()
        self.segmentationLights = [SCNNode(), SCNNode(), SCNNode()]
        self.obstacles = [SCNNode]()
        self.drawnPath = [SCNNode]()
        self.lastPath = Path()
        self.showingEnvironmentNodes = true
        self.thirdPersonCameraTransform = simd_mul(simd_float4x4(rows: [
            simd_float4(cos(-1.57), 0, sin(-1.57), -0.5),
            simd_float4(0, 1, 0, 0.7),
            simd_float4(-sin(-1.57), 0, cos(-1.57), 0),
            simd_float4(0, 0, 0, 1),
        ]), simd_float4x4(rows: [
            simd_float4(1, 0, 0, 0),
            simd_float4(0, cos(-0.5), -sin(-0.5), 0),
            simd_float4(0, sin(-0.5), cos(-0.5), 0),
            simd_float4(0, 0, 0, 1)
        ]))
        
        super.init()
        guard let world = SCNScene(named: "world.scn") else {
            fatalError("Could not find scene")
        }
        for node in world.rootNode.childNodes {
            self.rootNode.addChildNode(node)
        }
        environmentNode = self.rootNode.childNode(withName: "environment", recursively: false)!
        roadGraphNode = self.rootNode.childNode(withName: "segmentation", recursively: false)!
        
        thirdPersonCamera.constraints = []
        thirdPersonCamera.camera = SCNCamera()
        thirdPersonCamera.camera!.zNear = 0.001
        thirdPersonCamera.name = "third_person_camera"
        
        for segmentationLight in segmentationLights {
            segmentationLight.light = SCNLight()
            segmentationLight.light!.type = .omni
            segmentationLight.light!.color = UIColor.white
            segmentationLight.light!.intensity = 500
        }
        segmentationLights[0].position = SCNVector3(10, 5, 10)
        segmentationLights[1].position = SCNVector3(-10, 5, 0)
        segmentationLights[2].position = SCNVector3(10, 5, -10)
        
        let planeGeo = SCNPlane(width: 20, height: 10)
        let segmentationMaterial = SCNMaterial()
        segmentationMaterial.diffuse.contents = UIImage(named: "segmentation")
        segmentationMaterial.lightingModel = SCNMaterial.LightingModel.constant
        planeGeo.firstMaterial = segmentationMaterial
        segmentationNode = SCNNode(geometry: planeGeo)
        segmentationNode.eulerAngles = SCNVector3(-1.57, 0, 0)
        segmentationNode.position = SCNVector3(-3.63,-0.01,-0.57)
        
        // add all nodes to scene
        self.roadGraphNode.removeFromParentNode()
        self.rootNode.addChildNode(thirdPersonCamera)
    }
    
    func addRobocar(robocarNode: SCNNode) {
        self.robocar = robocarNode
        self.updateThirdPersonCameraPosition()
        self.rootNode.addChildNode(self.robocar!)
    }
    
    func updateThirdPersonCameraPosition() {
        if let robocar = self.robocar {
            var deltaTransform = robocar.simdTransform
            deltaTransform = simd_mul(deltaTransform, self.thirdPersonCameraTransform)
            
            self.thirdPersonCamera.simdTransform = deltaTransform
        }
    }
    
    func addObstacle(node: SCNNode) {
        self.obstacles.append(node)
        self.rootNode.addChildNode(node)
    }
    
    func drawPath(path: Path) {
        if lastPath != path {
            lastPath = path
            for nodePath in self.drawnPath {
                nodePath.removeFromParentNode()
            }
            self.drawnPath.removeAll()
            for index in 0..<path.nodes.count-1 {
                let origin = simd_float3(path.nodes[index].x, 0.005, path.nodes[index].z)
                let dest = simd_float3(path.nodes[index+1].x, 0.005, path.nodes[index+1].z)
                let node = WorldScene.line(from: origin, to: dest, width: 0.01, color: UIColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0))
                if !showingEnvironmentNodes {
                    self.rootNode.addChildNode(node)
                }
                self.drawnPath.append(node)
            }
        }
    }
    
    func removePath() {
        for nodePath in self.drawnPath {
            nodePath.removeFromParentNode()
        }
        self.drawnPath.removeAll()
    }
    
    func removeEnvironmentNodes() {
        if showingEnvironmentNodes {
            environmentNode.removeFromParentNode()
            self.rootNode.addChildNode(roadGraphNode)
            self.rootNode.addChildNode(segmentationNode)
            for segmentationLight in segmentationLights {
                self.rootNode.addChildNode(segmentationLight)
            }
            for nodePath in self.drawnPath {
                self.rootNode.addChildNode(nodePath)
            }
            showingEnvironmentNodes = false
        }
    }
    
    func addEnviornmentNodes() {
        if !showingEnvironmentNodes {
            self.rootNode.addChildNode(environmentNode)
            roadGraphNode.removeFromParentNode()
            self.segmentationNode.removeFromParentNode()
            for segmentationLight in segmentationLights {
                segmentationLight.removeFromParentNode()
            }
            for nodePath in self.drawnPath {
                nodePath.removeFromParentNode()
            }
            showingEnvironmentNodes = true
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func loadNodeFromSCN(scene: String, node: String) -> SCNNode {
        guard let scene_ = SCNScene(named: scene) else {
            fatalError("Could not load \(scene)")
        }
        
        guard let node_ = scene_.rootNode.childNode(withName: node, recursively: true) else {
            fatalError("Could not load \(node) from \(scene)")
        }
        return node_
    }
    
    static func getNode(node: String, from: SCNNode) -> SCNNode {
        guard let node_ = from.childNode(withName: node, recursively: true) else {
            fatalError("Could not find \(node)")
        }
        return node_
    }
    
    static func line(from : simd_float3, to : simd_float3, width : Float, color : UIColor) -> SCNNode {
        let vector = to - from,
        length = simd_length(vector)
        
        let cylinder = SCNCylinder(radius: CGFloat(width/2), height: CGFloat(length))
        cylinder.radialSegmentCount = 4
        cylinder.firstMaterial?.diffuse.contents = color
        
        let node = SCNNode(geometry: cylinder)
        
        node.simdPosition = (to + from) / 2
        node.eulerAngles = SCNVector3Make(Float(Double.pi/2), acos((to.z-from.z)/length), atan2((to.y-from.y), (to.x-from.x) ))
        
        return node
    }
    
    static func boundingBoxNode(from: SCNNode, color: UIColor) -> SCNNode {
        let boundingBoxNode = SCNNode()
        let boundingBox = from.boundingBox
        let width: Float = 0.01
        let nodes = [
            // base
            WorldScene.line(from: simd_float3(boundingBox.min.x, boundingBox.min.y, boundingBox.max.z),
                                           to: simd_float3(boundingBox.max.x, boundingBox.min.y, boundingBox.max.z),
                                           width: width, color: color),
            WorldScene.line(from: simd_float3(boundingBox.min.x, boundingBox.min.y, boundingBox.min.z),
                                           to: simd_float3(boundingBox.max.x, boundingBox.min.y, boundingBox.min.z),
                                           width: width, color: color),
            WorldScene.line(from: simd_float3(boundingBox.min.x, boundingBox.min.y, boundingBox.min.z),
                                           to: simd_float3(boundingBox.min.x, boundingBox.min.y, boundingBox.max.z),
                                           width: width, color: color),
            WorldScene.line(from: simd_float3(boundingBox.max.x, boundingBox.min.y, boundingBox.min.z),
                                           to: simd_float3(boundingBox.max.x, boundingBox.min.y, boundingBox.max.z),
                                           width: width, color: color),
            // top
            WorldScene.line(from: simd_float3(boundingBox.min.x, boundingBox.max.y, boundingBox.max.z),
                                           to: simd_float3(boundingBox.max.x, boundingBox.max.y, boundingBox.max.z),
                                           width: width, color: color),
            WorldScene.line(from: simd_float3(boundingBox.min.x, boundingBox.max.y, boundingBox.min.z),
                                           to: simd_float3(boundingBox.max.x, boundingBox.max.y, boundingBox.min.z),
                                           width: width, color: color),
            WorldScene.line(from: simd_float3(boundingBox.min.x, boundingBox.max.y, boundingBox.min.z),
                                           to: simd_float3(boundingBox.min.x, boundingBox.max.y, boundingBox.max.z),
                                           width: width, color: color),
            WorldScene.line(from: simd_float3(boundingBox.max.x, boundingBox.max.y, boundingBox.min.z),
                                           to: simd_float3(boundingBox.max.x, boundingBox.max.y, boundingBox.max.z),
                                           width: width, color: color),
            // sides
            WorldScene.line(from: simd_float3(boundingBox.min.x, boundingBox.min.y, boundingBox.min.z),
                                           to: simd_float3(boundingBox.min.x, boundingBox.max.y, boundingBox.min.z),
                                           width: width, color: color),
            WorldScene.line(from: simd_float3(boundingBox.max.x, boundingBox.min.y, boundingBox.min.z),
                                           to: simd_float3(boundingBox.max.x, boundingBox.max.y, boundingBox.min.z),
                                           width: width, color: color),
            WorldScene.line(from: simd_float3(boundingBox.max.x, boundingBox.min.y, boundingBox.max.z),
                                           to: simd_float3(boundingBox.max.x, boundingBox.max.y, boundingBox.max.z),
                                           width: width, color: color),
            WorldScene.line(from: simd_float3(boundingBox.min.x, boundingBox.min.y, boundingBox.max.z),
                                           to: simd_float3(boundingBox.min.x, boundingBox.max.y, boundingBox.max.z),
                                           width: width, color: color),
            ]
        for node in nodes {
            boundingBoxNode.addChildNode(node)
        }
        return boundingBoxNode
    }

    
}
