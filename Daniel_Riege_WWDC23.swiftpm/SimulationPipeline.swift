//
//  PhysicsSimulationExtension.swift
//  WWDC23
//
//  Created by Daniel Riege on 06.04.23.
//

import Foundation
import SceneKit

struct Obstacle {
    let robocar: RobocarModel
    let pathplanning: Pathplanning
}

struct AVPipelineStack {
    let pathplanning: Pathplanning
    let pidSpeedController: PIDController
}

/**
 This class attaches into the rendering pipeline of the main 3D View.
 
 All simulated objects in the world will get updated here coresponding to the values given by the SceneModel.
 This drives the main loop for our own simulation.
 */
class SimulationPipeline: NSObject, SCNSceneRendererDelegate {
    
    private var guiModel: GUIModel
    private var robocar: RobocarModel
    private var robocarSoftware: AVPipelineStack
    private var obstacles: [Obstacle]
    private var scene: WorldScene
    
    private var lastSimulationUpdate: TimeInterval
    private var resetSimFlag: Bool
    
    private var counter: Int
    
    private let maxPerceptionView: Float = 4.0
    
    init(guiModel: GUIModel, robocar: RobocarModel, robocarSoftware: AVPipelineStack, obstacles: [Obstacle], scene: WorldScene) {
        self.guiModel = guiModel
        self.robocar = robocar
        self.robocarSoftware = robocarSoftware
        self.obstacles = obstacles
        self.scene = scene
        self.resetSimFlag = false
        self.counter = 0
        self.lastSimulationUpdate = 0.0
        
        super.init()
        self.factory()
    }
    
    /// All needed objects are passed in the init. In the factory additional connections between objects after initalization are made.
    private func factory() {
        // Add ego robocar to scene
        self.scene.addRobocar(robocarNode: self.robocar.getAsNode())

        // Add obstacle robocar to scene
        for obstacle in obstacles {
            self.scene.addObstacle(node: obstacle.robocar.getAsNode())
        }
        
        //pathplanningSim.readPath()
    }
    
    private func simulateManualCarControl(dt: TimeInterval) {
        let throttleValue = guiModel.controlThrottle
        let steeringValue = guiModel.controlSteering
        
        self.robocar.step(speed: throttleValue, steering: steeringValue, dt: Float(dt))
        
        if counter % 10 == 0 {
            self.guiModel.addSpeedValue(value: robocar.getSpeed())
            self.guiModel.addSteeringValue(value: robocar.getSteeringAngle())
        }
        if counter % 2 == 0 {
            self.guiModel.setSpeed(speed: robocar.getSpeed())
            self.guiModel.setDashboardWheelAngle(steeringAngle: robocar.getSteeringAngle())
        }
    }
    
    private func resetSimulation() {
        self.counter = 0
        self.robocar.reset()
        self.robocarSoftware.pathplanning.reset()
        self.scene.removePath()
        self.scene.updateThirdPersonCameraPosition()
        for obstacle in obstacles {
            obstacle.robocar.reset()
            obstacle.pathplanning.reset()
        }
        self.guiModel.setSpeed(speed: 0)
        self.guiModel.setDashboardWheelAngle(steeringAngle: 0)
    }
    
    private func runAVPipeline(dt: TimeInterval) {
        
        // MARK: generate local path
        var localPath: Path? = nil
        // generate local path depending on choosen lane
        switch guiModel.driveOnLane {
        case .left:
            localPath = robocarSoftware.pathplanning.generateLocalPathOnLeftLane(currentPos: robocar.getPosition2D(), directionOfTravel: robocar.getOrientation(), heuristic: guiModel.intersectionHeuristic)
        default:
            localPath = robocarSoftware.pathplanning.generateLocalPath(currentPos: robocar.getPosition2D(), directionOfTravel: robocar.getOrientation(), heuristic: guiModel.intersectionHeuristic)
        }
        
        // using local path, calculate steering angle using controller
        if var localPath = localPath {
            guard localPath.nodes.count > 3 else {
                return
            }
            
            var speed = guiModel.controlThrottle * RobocarModel.maxSpeed
            
            // MARK: Determine speed and lane change
            // get distance to obstacle
            if let distanceToObstacle = getDistanceToObstacleOnPath(path: localPath, threshold: maxPerceptionView, pathThresholdAngle: 0.15, pathThreshold: 0.1) {
                // if we are in automatic overtake mode, we want to determine if we are close enough to engange lane change
                var didLaneChange = false
                if guiModel.driveOnLane == .automatic && distanceToObstacle < guiModel.minDistanceForOvertake {
                    // engange lane change by overwriting the local path
                    if let leftLocalPath = robocarSoftware.pathplanning.generateLocalPathOnLeftLane(currentPos: robocar.getPosition2D(), inAdvance: 8, directionOfTravel: robocar.getOrientation(), heuristic: guiModel.intersectionHeuristic) {
                        if localPath.nodes.count > 3 {
                            // we need to overwrite distanceToObstacle as well to check if lane is free
                            if let distanceToObstacleOnLeftLane = getDistanceToObstacleOnPath(path: leftLocalPath, threshold: maxPerceptionView, pathThresholdAngle: 0.15, pathThreshold: 0.1) {
                                if distanceToObstacleOnLeftLane > guiModel.minDistanceForOvertake {
                                    localPath = leftLocalPath
                                    didLaneChange = true
                                }
                            } else {
                                localPath = leftLocalPath
                                didLaneChange = true
                            }
                        }
                    }
                }
                
                if !didLaneChange {
                    // override speed with obstacle ahead
                    speed = min(speed, max(robocarSoftware.pidSpeedController.calculate(target: distanceToObstacle - guiModel.maxDistance,
                                                                                        previous: robocar.getSpeed()/36,
                                                                                        P: guiModel.P,
                                                                                        I: guiModel.I,
                                                                                        D: guiModel.D,
                                                                                        dt: dt), 0.0))
                    if counter % 10 == 0 {
                        self.guiModel.addDistanceValue(value: distanceToObstacle)
                    }
                }
            } else {
                if counter % 10 == 0 {
                    self.guiModel.addDistanceValue(value: .nan)
                }
            }
            
            self.scene.drawPath(path: localPath)
            
            // MARK: calculate steering angle
            let stanleyResult = StanleyController.getSteeringAngle(previousWaypoint: localPath.nodes[1],
                                                                   nextWaypoint: localPath.nodes[2],
                                                                   currentSpeed: robocar.getSpeed() / 36,
                                                                   currentTransform: robocar.getCurrentTransformFrontAxcle(),
                                                                   k: guiModel.stanleyGain)
            let steeringAngle = stanleyResult.steeringAngle
            let crossTrackError = stanleyResult.crossTrackError
            let headingError = stanleyResult.headingError
            
            self.robocar.step(speed: speed, steeringAngle: steeringAngle, dt: Float(dt))
            
            if counter % 10 == 0 {
                self.guiModel.addCrossTrackErrorValue(value: abs(crossTrackError))
                self.guiModel.addHeadingErrorValue(value: abs(headingError))
            }
            if counter % 2 == 0 {
                self.guiModel.setSpeed(speed: robocar.getSpeed())
                self.guiModel.setDashboardWheelAngle(steeringAngle: robocar.getSteeringAngle())
            }
        }
    }
    
    private func simulateObstacleDriving(obstacle: Obstacle, dt: TimeInterval) {
        // generate local path
        let localPath = obstacle.pathplanning.generateLocalPath(currentPos: obstacle.robocar.getPosition2D(), inAdvance: 4, directionOfTravel: obstacle.robocar.getOrientation())
        let stanleyResult = StanleyController.getSteeringAngle(previousWaypoint: localPath.nodes[1],
                                                               nextWaypoint: localPath.nodes[2],
                                                               currentSpeed: obstacle.robocar.getSpeed() / 36,
                                                               currentTransform: obstacle.robocar.getCurrentTransformFrontAxcle(),
                                                               k: 1.5)
        let steeringAngle = stanleyResult.steeringAngle
        obstacle.robocar.step(speed: 0.4, steeringAngle: steeringAngle, dt: Float(dt))
//        // set looking distance based on last used speed
//        let lookingDistance = obstacle.robocar.getSpeed() / 36 * Float(dt)
//         //get normalized vector which points from car position to next node
//        if let vectorToPath = obstacle.pathplanning.getVectorToPath(currentPos: obstacle.robocar.getPosition2D(),
//                                                                    directionOfTravel: obstacle.robocar.getOrientation(),
//                                                                    localPath: localPath,
//                                                                    distance: lookingDistance) {
//            // use the vector to drive the car
//            // bad practice since the car drives the local path very abrupt
//            obstacle.robocar.step(directionVector: vectorToPath, speed: 0.1, dt: Float(dt))
//        } else {
//            print("Looking distance is too far for local path...")
//        }
    }
    
    private func getDistanceToObstacleOnPath(path: Path, threshold: Float, pathThresholdAngle: Float, pathThreshold: Float) -> Float? {
        var distances = [Float]()
        for obstacle in obstacles {
            let vectorToObstacle = obstacle.robocar.getVectorFrom(position: robocar.getPosition2D())
            if Pathplanning.inDirection(directionOfTravel: robocar.getOrientation(), vectorToCheck: vectorToObstacle, maxAngle: 1.57) {
                let distance = simd_length(vectorToObstacle) - robocar.wheelbase
                if distance < threshold {
                    // check if obstacle is on path
                    let obstacleOrientation = obstacle.robocar.getOrientation()
                    let obstaclePosition = obstacle.robocar.getPosition2D()
                    for (index, _) in path.nodes.enumerated() {
                        if index < path.nodes.count-1 {
                            let p2 = path.nodes[index+1]
                            let p1 = path.nodes[index]
                            let directionOfNode = simd_float2(p2.x - p1.x, p2.z - p1.z)
//                            if Pathplanning.inDirection(directionOfTravel: obstacleOrientation, vectorToCheck: directionOfNode, maxAngle: pathThresholdAngle) {
                                let ce_num = (p2.x-p1.x) * (p1.z-obstaclePosition.y) - (p1.x-obstaclePosition.x) * (p2.z-p1.z)
                                let ce_de = sqrt(pow(p2.x-p1.x, 2) + pow(p2.z-p1.z, 2))
                                let crossTrackError = ce_num / ce_de
                                if abs(crossTrackError) < pathThreshold {
                                    distances.append(distance)
                                    continue
                                }
//                            }
                        }
                    }
                }
            }
        }
        return distances.min()
    }
    
    // MARK: - Rendering Pipeline Delegates
    // This delegates are used to drive the simulations and add additional logic to the Scene
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        if guiModel.perceptionView {
            self.scene.removeEnvironmentNodes()
            for obstacle in obstacles {
                obstacle.robocar.changeViewMode(boundingBoxView: true)
            }
            self.robocar.changeCameraViewMode(clippingMax: maxPerceptionView)
        } else {
            self.scene.addEnviornmentNodes()
            for obstacle in obstacles {
                obstacle.robocar.changeViewMode(boundingBoxView: false)
            }
            self.robocar.changeCameraViewMode(clippingMax: 30)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
        // set car parameters
        robocar.maxAcceleration = guiModel.maxAcceleration
        robocar.maxDeacceleration = guiModel.maxDeacceleration
        robocar.maxSteeringChange = guiModel.maxSteeringChange
        // control car
        if lastSimulationUpdate != 0 && guiModel.simRunning {
            let dt = time - lastSimulationUpdate
            if guiModel.currentScenario == ScenarioSelection.manualControl {
                self.simulateManualCarControl(dt: dt)
            } else {
                self.runAVPipeline(dt: dt)
            }
            self.scene.updateThirdPersonCameraPosition()
            
            for obstacle in obstacles {
                self.simulateObstacleDriving(obstacle: obstacle, dt: dt)
            }
            
            counter += 1
            if counter >= 10 {
                counter = 0
            }
            self.resetSimFlag = true
        }
        lastSimulationUpdate = time
        
        // reset simulation
        if !guiModel.simRunning && resetSimFlag == true {
            resetSimulation()
            resetSimFlag = false
        }
    }
}
