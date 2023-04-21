//
//  PathplanningSim.swift
//  WWDC23
//
//  Created by Daniel Riege on 11.04.23.
//

import Foundation
import simd

/**
 A path is a collection of RoadGraphNodes.
 
 These RoadGraphNodes do not need to have connections to other node since path is directed. The Path goes from index 0 to n.
 */
struct Path: Equatable {
    let nodes: [RoadGraphNode]
    
    init(nodes: [RoadGraphNode]) {
        self.nodes = nodes
    }
    
    init() {
        self.nodes = [RoadGraphNode]()
    }
    
    static func ==(lhs: Path, rhs: Path) -> Bool {
        return lhs.nodes == rhs.nodes
    }
}

enum PathplanningIntersectionHeuristic: String, CaseIterable {
    case left = "Left"
    case right = "Right"
    case middle = "Middle"
}

enum PathplanningOnLane: String, CaseIterable {
    case left = "Left"
    case right = "Right"
    case automatic = "Automatic"
}

/**
 Component for a car to generate local paths on a graph given the start node (based on position of car).
 */
class Pathplanning {
    
    private let graph: RoadGraph
    private var path: [RoadGraphNode]
    private let startNode: RoadGraphNode
    /// origin node of the current edge where the vehicle is
    private var currentNode: RoadGraphNode
    private var cachedNodesOnLeftSide: [Int: RoadGraphNode] // key: id if current node; value: pseudo current node on left side
    
    init(graph: RoadGraph, startNode: RoadGraphNode) {
        self.graph = graph
        self.startNode = startNode
        self.currentNode = startNode
        self.path = [RoadGraphNode]()
        self.cachedNodesOnLeftSide = [Int: RoadGraphNode]()
    }
    
    private func getNextNodeInDirection(origin: RoadGraphNode, directionOfTravel: simd_float2, heuristic: PathplanningIntersectionHeuristic, maxAngle: Float = 1.57) -> RoadGraphNode? {
        // first we need to check in which direction we have to look for next node
        if let toNodesId = origin.to {
            let nextNodeId = chooseNodeFrom(nodeIds: toNodesId, heuristic: heuristic)
            if Pathplanning.inDirection(directionOfTravel: directionOfTravel, origin: origin, dest: graph.getNode(id: nextNodeId), maxAngle: maxAngle) {
                // choose node with heuristic
                let nodeToAdd = graph.getNode(id: nextNodeId)
                return nodeToAdd
            } else {
                for alternativeNodeId in toNodesId {
                    if Pathplanning.inDirection(directionOfTravel: directionOfTravel, origin: origin, dest: graph.getNode(id: alternativeNodeId), maxAngle: maxAngle) {
                        // choose node with heuristic
                        let nodeToAdd = graph.getNode(id: alternativeNodeId)
                        return nodeToAdd
                    }
                }
            }
        }
        
        if let fromNodesId = origin.from {
            let nextNodeId = chooseNodeFrom(nodeIds: fromNodesId, heuristic: heuristic)
            if Pathplanning.inDirection(directionOfTravel: directionOfTravel, origin: origin, dest: graph.getNode(id: nextNodeId), maxAngle: maxAngle) {
                let nodeToAdd = graph.getNode(id: nextNodeId)
                return nodeToAdd
            } else {
                for alternativeNodeId in fromNodesId {
                    if Pathplanning.inDirection(directionOfTravel: directionOfTravel, origin: origin, dest: graph.getNode(id: alternativeNodeId), maxAngle: maxAngle) {
                        // choose node with heuristic
                        let nodeToAdd = graph.getNode(id: alternativeNodeId)
                        return nodeToAdd
                    }
                }
            }
        }
        return nil
    }
    
    private func updateCurrentNode(currentPos: simd_float2, directionOfTravel: simd_float2, heuristic: PathplanningIntersectionHeuristic) {
        var inDirection = false
        var lastNode = currentNode
        guard var oneAheadOfLast = getNextNodeInDirection(origin: currentNode, directionOfTravel: directionOfTravel, heuristic: heuristic) else {
            print("Error: There is no next node in direction!")
            return
        }
        var vecCarToOneAheadOfLast = simd_float2(oneAheadOfLast.x-currentPos.x, oneAheadOfLast.z-currentPos.y)
        while !inDirection {
            if !Pathplanning.inDirection(directionOfTravel: directionOfTravel, vectorToCheck: vecCarToOneAheadOfLast, maxAngle: 1.57) {
                if let nextNode = getNextNodeInDirection(origin: oneAheadOfLast, directionOfTravel: directionOfTravel, heuristic: heuristic) {
                    lastNode = oneAheadOfLast
                    oneAheadOfLast = nextNode
                    vecCarToOneAheadOfLast = simd_float2(oneAheadOfLast.x-currentPos.x, oneAheadOfLast.z-currentPos.y)
                } else {
                    print("Error: There is no next node in direction!")
                    return
                }
            } else {
                inDirection = true
            }
        }
        self.currentNode = lastNode
    }
    
    func generateLocalPath(currentPos: simd_float2, inAdvance: Int = 8, directionOfTravel: simd_float2, heuristic: PathplanningIntersectionHeuristic = .middle, origin: RoadGraphNode? = nil) -> Path {
        var firstNode = origin
        if origin == nil {
            // check if currentNode is still valid
            updateCurrentNode(currentPos: currentPos, directionOfTravel: directionOfTravel, heuristic: heuristic)
            firstNode = self.currentNode
        }
        
        var localPath = [firstNode!] // local path always starts at current node
        var directionToLook = directionOfTravel
        for _ in 0..<inAdvance {
            if let nextNode = getNextNodeInDirection(origin: localPath.last!, directionOfTravel: directionToLook, heuristic: heuristic) {
                directionToLook = simd_float2(nextNode.x-localPath.last!.x, nextNode.z-localPath.last!.z)
                localPath.append(nextNode)
            } else {
                break
            }
        }
        return Path(nodes: localPath)
    }
    
    func generateLocalPathOnLeftLane(currentPos: simd_float2, inAdvance: Int = 8, directionOfTravel: simd_float2, heuristic: PathplanningIntersectionHeuristic = .middle) -> Path? {
        // check if currentNode is still valid
        updateCurrentNode(currentPos: currentPos, directionOfTravel: directionOfTravel, heuristic: heuristic)
        
        // check if we maybe have cached node
        if let cachedNodeLeftSide = self.cachedNodesOnLeftSide[self.currentNode.id] {
            return generateLocalPath(currentPos: currentPos, inAdvance: inAdvance, directionOfTravel: directionOfTravel, heuristic: heuristic, origin: cachedNodeLeftSide)
        } else {
            // get direction of current node to check for node on other lane
            if let nextNodeFromCurrent = getNextNodeInDirection(origin: self.currentNode, directionOfTravel: directionOfTravel, heuristic: heuristic) {
                let directionOfCurrentNode = simd_normalize(simd_float2(nextNodeFromCurrent.x - currentNode.x, nextNodeFromCurrent.z - currentNode.z))
                let normalLeft = simd_float2(directionOfCurrentNode.y, -directionOfCurrentNode.x)
                // search for Candiates on left side
                let leftDiagonal = simd_float2(0.70710678 * normalLeft.x + 0.70710678 * normalLeft.y, -0.70710678 * normalLeft.x + 0.70710678 * normalLeft.y) // x: x * cos(θ) - y sin(θ) y: x sin(θ) + y cos(θ)
                var choosenPath: [RoadGraphNode]? = nil
                var lowestDistance: Float = 2
                let searchedNodes = graph.searchForNodes(origin: currentNode, directionVector: leftDiagonal, searchRadius: 0.75, maxDistance: lowestDistance)
                for nodeToCheck in searchedNodes {
                    // now we have some possible nodes on left lane but we need to make sure they are not connected to current node (e.g. on our path)
                    var localPath = [nodeToCheck]
                    var directionToLook = directionOfCurrentNode
                    for index in 0..<inAdvance+1 {
                        let maxAngle: Float = (index == 0) ? 0.6 : 1.57
                        if let nextNode = getNextNodeInDirection(origin: localPath.last!, directionOfTravel: directionToLook, heuristic: heuristic, maxAngle: maxAngle) {
                            if nextNode.id != currentNode.id {
                                directionToLook = simd_float2(nextNode.x-localPath.last!.x, nextNode.z-localPath.last!.z)
                                localPath.append(nextNode)
                            } else {
                                break
                            }
                        } else {
                            break
                        }
                    }
                    if localPath.count >= choosenPath?.count ?? 2 {
                        let distanceFromFirst = simd_length(simd_float2(currentNode.x - localPath[0].x, currentNode.z - localPath[0].z))
                        if distanceFromFirst < lowestDistance {
                            choosenPath = localPath
                            lowestDistance = distanceFromFirst
                        }
                    }
                }
                if var localPath = choosenPath {
                    // now we have a node on left side!
                    // we want to cache it to be faster on next round
                    localPath.remove(at: 0)
                    self.cachedNodesOnLeftSide[self.currentNode.id] = localPath[0]
                    return Path(nodes: localPath)
                } else {
                    return generateLocalPath(currentPos: currentPos, inAdvance: inAdvance, directionOfTravel: directionOfTravel, heuristic: heuristic, origin: self.currentNode)
                }
            }
        }
        return nil
    }
    
    /**
     Calculates a vector to the next node on the local path using the distance as a max threshold.
     
     If the distance is greater than the next node on local path, the node after that will be checked.
     
     - parameter currentPos: current position used as base for vector
     - parameter directionOfTravel: normalized vector which shows in the direction this method should look into
     - parameter localPath: local path used for searching
     - parameter distance: threshold as minimum distance to the vector returned
     */
    func getVectorToPath(currentPos: simd_float2, directionOfTravel: simd_float2,  localPath: Path, distance: Float) -> simd_float2? {
        for node in localPath.nodes {
            if node.id != self.currentNode.id {
                let vectorToNode = simd_float2(node.x - currentPos.x, node.z - currentPos.y)
                if distance < simd_length(vectorToNode) &&
                    Pathplanning.inDirection(directionOfTravel: directionOfTravel, vectorToCheck: vectorToNode, maxAngle: 1.57) {
                    let normalized = simd_normalize(vectorToNode)
                    return normalized
                }
            }
        }
        return nil
    }
    
    func reset() {
        self.currentNode = startNode
    }
    
    private func chooseNodeFrom(nodeIds: [Int], heuristic: PathplanningIntersectionHeuristic) -> Int {
        switch heuristic {
        case .middle:
            return nodeIds[0]
        case .right:
            return nodeIds.last!
        case .left:
            return nodeIds[Int(nodeIds.count/2)]
        }
    }
    
    static func inDirection(directionOfTravel: simd_float2, vectorToCheck: simd_float2, maxAngle: Float) -> Bool {
        let angleBetweenVectors = atan2(directionOfTravel.y * vectorToCheck.x - directionOfTravel.x * vectorToCheck.y, directionOfTravel.x * vectorToCheck.x + directionOfTravel.y * vectorToCheck.y)
        if angleBetweenVectors < maxAngle && angleBetweenVectors > -maxAngle {
            return true
        } else {
            return false
        }
    }
    
    static func inDirection(directionOfTravel: simd_float2, origin: RoadGraphNode, dest: RoadGraphNode, maxAngle: Float) -> Bool {
        let vectorBetweenNodes = simd_float2(dest.x-origin.x, dest.z-origin.z)
        return Pathplanning.inDirection(directionOfTravel: directionOfTravel, vectorToCheck: vectorBetweenNodes, maxAngle: maxAngle)
    }
}
