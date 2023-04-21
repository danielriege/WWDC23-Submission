//
//  Robocar.swift
//  WWDC23
//
//  Created by Daniel Riege on 06.04.23.
//

import Foundation
import SceneKit

/**
 This class simulates the robocar with all its behaviour and control
 */
class RobocarModel {
    static let maxSteeringAngle: Float = 30.0 // deg
    var maxSteeringChange: Float = 90 // deg per second
    var maxAcceleration: Float = 1 // m/s^2
    var maxDeacceleration: Float = 3 // m/s^2
    static let maxSpeed: Float = 2.7 // m/s
    let wheelbase: Float
    let trackWidth: Float
    
    private var currentSpeed: Float // in m/s
    private var currentSteeringAngle: Float
    private var translatePivot: simd_float4x4 // vehicle with one steering axis always pivots around the center of rear axis, so we translate the pivot point
    private var transform: simd_float4x4
    
    private let root: SCNNode
    private let chassis: SCNNode
    private let body: SCNNode
    private let front_left: SCNNode
    private let front_right: SCNNode
    private let rear_left: SCNNode
    private let rear_right: SCNNode
    private let front_camera: SCNNode
    
    private let boundingBox: SCNNode
    private var boundingBoxViewMode: Bool
    
    init(transform: simd_float4x4? = nil, color: CGColor? = nil) {
        root = SCNNode()
        chassis = WorldScene.loadNodeFromSCN(scene: "robocar.scn", node: "chassis")
        body = WorldScene.getNode(node: "robocar", from: chassis)
        front_right = WorldScene.getNode(node: "front_right", from: chassis)
        front_left = WorldScene.getNode(node: "front_left", from: chassis)
        rear_right = WorldScene.getNode(node: "rear_right", from: chassis)
        rear_left = WorldScene.getNode(node: "rear_left", from: chassis)
        front_camera = WorldScene.getNode(node: "front_camera", from: chassis)
        self.root.addChildNode(chassis)
        
        // create bounding box
        boundingBox = WorldScene.boundingBoxNode(from: root, color: UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0))
        boundingBoxViewMode = false
        
        wheelbase = front_right.position.z - rear_right.position.z
        trackWidth = front_right.position.x - front_left.position.x
        
        translatePivot = RobocarModel.createYAxisRotation(angle: -1.57)
        translatePivot[3,2] = rear_right.position.z
        root.simdPivot = translatePivot
        
        front_right.pivot = SCNMatrix4Rotate(SCNMatrix4Identity, 1.57, 0, 0, 1)
        front_left.pivot = SCNMatrix4Rotate(SCNMatrix4Identity, 1.57, 0, 0, 1)
        
        front_camera.camera!.fieldOfView = 90
        
        currentSpeed = 0
        currentSteeringAngle = 0
        if let transform = transform {
            self.transform = transform
        } else {
            self.transform = matrix_identity_float4x4
        }
        self.transform[3,1] = 0.065 // translate on y axis
        
        // set color of robocar body if provided
        if let color = color {
            let newMaterial = SCNMaterial()
            newMaterial.diffuse.contents = color
            body.geometry?.firstMaterial = newMaterial
        }
        
        reset()
    }
    
    func reset() {
        currentSpeed = 0
        currentSteeringAngle = 0
        
        root.simdTransform = transform
        self.setRotationOfWheels(leftAngle: 0, rightAngle: 0)
    }
    
    /**
     Simulates car kinematic using control parameters.
     
     Use this method if you want to simulate the car kinematics using steering and speed value.
     
     - parameter speed: The speed of the vehicle as duty cycle, e.g. in the range [0,1] where 1 is cars max speed
     - parameter steering: steering angle of the car in range [-1,1] where -1 is left with max steering angle
     - parameter dt: time period since last simulation step where this method was called
     */
    func step(speed: Float, steering: Float, dt: Float) {
        let steeringAngle = steering * RobocarModel.maxSteeringAngle
        let speedValue = speed * RobocarModel.maxSpeed
        step(speed: speedValue, steeringAngle: steeringAngle, dt: dt)
    }
    
    func step(speed: Float, steeringAngle: Float, dt: Float) {
        // calculate speed
        let speedChange = min(max(speed-currentSpeed, -maxDeacceleration * dt), maxAcceleration * dt)
        currentSpeed += speedChange
        // calculate new steering angle
        let newSteeringAngle = min(max(steeringAngle, -RobocarModel.maxSteeringAngle), RobocarModel.maxSteeringAngle)
        let maxSteeringDt = maxSteeringChange * dt
        let steeringChange = min(max(newSteeringAngle-currentSteeringAngle,-maxSteeringDt),maxSteeringDt) // bounding delta steering
        currentSteeringAngle += steeringChange
        // calculating delta transform
        var deltaTransform = matrix_identity_float4x4
        
        let vxn: Float = 1.0
        let vzn: Float = 0.0
        
        if currentSteeringAngle == 0 {
            deltaTransform[3,0] = currentSpeed * dt // x
            
            self.setRotationOfWheels(leftAngle: 0, rightAngle: 0)
        } else {
            let radius = wheelbase / tan(currentSteeringAngle
                                         * .pi / 180)
            let ang_vel = currentSpeed / radius
            let dyaw = -ang_vel * dt // delta yaw
            
            // normalvector
            let nx = vzn
            let nz = -vxn
            
            // translation into turning point
            var T = matrix_identity_float4x4
            T[3,0] = nx * radius
            T[3,2] = nz * radius
            // rotation around y axis given dyaw
            let R = RobocarModel.createYAxisRotation(angle: dyaw)
            deltaTransform = simd_mul(T.inverse,simd_mul(R, T))
            
            let ackermannAngles = self.calculateAckermannSteering(turningRadius: radius)
            self.setRotationOfWheels(leftAngle: ackermannAngles.0, rightAngle: ackermannAngles.1)
        }
        root.simdTransform = simd_mul(root.simdTransform, deltaTransform)
    }
    
    /**
     Simulates the car kinematics using a direction.
     
     Since this method only uses one vector, the orientation of the vehicle will be set into the direction of this vector. Therefore it is advised to only make small vector changes in between simulation changes.
     
     - parameter directionVector: normalized vector for the new direction of travel
     - parameter speed: The speed of the vehicle as duty cycle, e.g. in the range [0,1] where 1 is cars max speed
     - parameter dt: time period since last simulation step where this method was called
     */
    func step(directionVector: simd_float2, speed: Float, dt: Float) {
        let newSpeed = speed * RobocarModel.maxSpeed
        let speedChange = min(max(newSpeed-currentSpeed, -maxDeacceleration * dt), maxAcceleration * dt)
        currentSpeed += speedChange
        
        let currentDirection = simd_float2(root.simdTransform[0,0], root.simdTransform[0,2])
        var dyaw = atan2(currentDirection.y * directionVector.x - currentDirection.x * directionVector.y, currentDirection.x * directionVector.x + currentDirection.y * directionVector.y)
        if dyaw.isNaN {
            dyaw = 0
        }
        
        var deltaTransform = RobocarModel.createYAxisRotation(angle: dyaw)
        deltaTransform[3,0] = currentSpeed * dt
        
        root.simdTransform = simd_mul(root.simdTransform, deltaTransform)
    }
    
    func changeViewMode(boundingBoxView: Bool) {
        if boundingBoxView && !boundingBoxViewMode {
            boundingBoxViewMode = true
            self.chassis.removeFromParentNode()
            self.root.addChildNode(boundingBox)
        } else if !boundingBoxView && boundingBoxViewMode{
            boundingBoxViewMode = false
            self.boundingBox.removeFromParentNode()
            self.root.addChildNode(chassis)
        }
    }
    
    func changeCameraViewMode(clippingMax: Float) {
        self.front_camera.camera!.zFar = Double(clippingMax)
    }
    
    func getPosition2D() -> simd_float2 {
        return simd_float2(root.position.x, root.position.z)
    }
    
    func getOrientation() -> simd_float2 {
        return simd_float2(root.simdTransform[0,0], root.simdTransform[0,2])
    }
    
    func getCurrentTransform() -> simd_float4x4 {
        return root.simdTransform
    }
    
    func getCurrentTransformFrontAxcle() -> simd_float4x4 {
        var T = matrix_identity_float4x4
        T[3,0] = self.wheelbase
        return simd_mul(root.simdTransform, T)
    }
    
    func getVectorFrom(position: simd_float2) -> simd_float2 {
        let ownPosition = self.getPosition2D()
        return simd_float2(ownPosition.x-position.x, ownPosition.y-position.y)
    }
    
    func getDistanceFrom(position: simd_float2) -> Float {
        return simd_length(getVectorFrom(position: position))
    }
    
    /**
     Calculates the rotation of the front wheels in an ackermann fashion.
     
     Just for visual purpose.
     
     - returns: Tuple with rotation in radians  for left, right wheel respectively
     */
    private func calculateAckermannSteering(turningRadius: Float) -> (Float, Float) {
        let left = atan(self.wheelbase/(turningRadius-(self.trackWidth/2))) * -1
        let right = atan(self.wheelbase/(turningRadius+(self.trackWidth/2))) * -1
        return (left, right)
    }
    
    private func setRotationOfWheels(leftAngle: Float, rightAngle: Float) {
        self.front_left.eulerAngles = SCNVector3(x: 0, y: leftAngle, z: 0)
        self.front_right.eulerAngles = SCNVector3(x: 0, y: rightAngle, z: 0)
    }
    
    /**
     Returns the speed in kph in 1:1 environment.
     
     Since the model 1:10, the speed has to be scaled up by 10 to get a realistic feel.
     */
    func getSpeed() -> Float {
        return currentSpeed * 36
    }
    
    func getSteeringAngle() -> Float {
        return currentSteeringAngle
    }
    
    func getAsNode() -> SCNNode {
        return root
    }
    
    private static func createYAxisRotation(angle: Float) -> simd_float4x4 {
        let rows = [
            simd_float4(cos(angle), 0, sin(angle), 0),
            simd_float4(0, 1, 0, 0),
            simd_float4(-sin(angle), 0, cos(angle), 0),
            simd_float4(0, 0, 0, 1),
        ]
        return simd_float4x4(rows: rows)
    }
}
