//
//  RoadGraph.swift
//  WWDC23
//
//  Created by Daniel Riege on 12.04.23.
//

import Foundation
import simd

/**
This represents a 2D node of a pathplanning path.
 */
struct RoadGraphNode: Equatable {
    let id: Int
    let x: Float
    let z: Float
    var from: [Int]?
    var to: [Int]?
    
    static func ==(lhs: RoadGraphNode, rhs: RoadGraphNode) -> Bool {
        return lhs.id == rhs.id
    }
}

struct RoadGraph {
    let nodes: [RoadGraphNode]
    
    public static func getRoadGraph(objFilename: String) -> RoadGraph {
        let objLines = RoadGraph.readObj(filename: objFilename)
        return RoadGraph.parseObjLines(lines: objLines)
    }
    
    private init(nodes: [RoadGraphNode]) {
        self.nodes = nodes
    }
    
    func getNode(id: Int) -> RoadGraphNode {
        return nodes[id]
    }
    
    func get3DTransform(node: RoadGraphNode, east: Bool) -> simd_float4x4 {
        var vectorEast: simd_float2? = nil
        var vectorWest: simd_float2? = nil
        if node.to != nil {
            let vecTo = simd_float2(nodes[node.to![0]].x - node.x, nodes[node.to![0]].z - node.z)
            if vecTo.x > 0 {
                vectorEast = simd_normalize(vecTo)
            } else {
                vectorWest = simd_normalize(vecTo)
            }
        }
        if node.from != nil {
            let vecFrom = simd_float2(nodes[node.from![0]].x - node.x, nodes[node.from![0]].z - node.z)
            if vecFrom.x > 0 {
                vectorEast = simd_normalize(vecFrom)
            } else {
                vectorWest = simd_normalize(vecFrom)
            }
        }
        if (east && vectorEast != nil) || (vectorEast != nil && vectorWest == nil) {
            let rows = [
                simd_float4(vectorEast!.x, 0, vectorEast!.y * -1, node.x),
                simd_float4(0, 1, 0, 0),
                simd_float4(vectorEast!.y, 0, vectorEast!.x, node.z),
                simd_float4(0, 0, 0, 1),
            ]
            return simd_float4x4(rows: rows)
        } else if (!east && vectorWest != nil) || (vectorWest != nil && vectorEast == nil) {
            let rows = [
                simd_float4(vectorWest!.x, 0, vectorWest!.y * -1, node.x),
                simd_float4(0, 1, 0, 0),
                simd_float4(vectorWest!.y, 0, vectorWest!.x, node.z),
                simd_float4(0, 0, 0, 1),
            ]
            return simd_float4x4(rows: rows)
        } else {
            return matrix_identity_float4x4
        }
    }
    
    func searchForNodes(origin: RoadGraphNode, directionVector: simd_float2, searchRadius: Float, maxDistance: Float) -> [RoadGraphNode] {
        var candidates = [RoadGraphNode]()
        for node in nodes {
            let vecToNode = simd_float2(node.x - origin.x, node.z-origin.z)
            // first check for length since this will reduce more search candidates than direction checking
            if simd_length(vecToNode) < maxDistance && node.id != origin.id {
                let angleBetweenVectors = atan2(directionVector.y * vecToNode.x - directionVector.x * vecToNode.y, directionVector.x * vecToNode.x + directionVector.y * vecToNode.y)
                if angleBetweenVectors < searchRadius && angleBetweenVectors > -searchRadius {
                    // node is a candidate
                    candidates.append(node)
                }
            }
        }
        return candidates
    }
    
//    func getNearestNode(currentPos: (Float, Float)) -> RoadGraphNode {
//
//        return nearestNode
//    }
    
    private static func parseObjLines(lines: [String]) -> RoadGraph {
        var graphNodes = [RoadGraphNode]()
        var idCnt = 0
        for line in lines {
            // obj files always start with vertex declaration
            // so we first create all the RoadGraphNodes and connect them later
            if line.first == "v" {
                let dirtyVertices = line.components(separatedBy: " ") // this array includes a "v"
                guard let x = Float(dirtyVertices[1]) else {
                    print("not a float: \(dirtyVertices[1])")
                    continue
                }
                guard let z = Float(dirtyVertices[3]) else {
                    print("not a float: \(dirtyVertices[3])")
                    continue
                }
                let node = RoadGraphNode(id: idCnt, x: x, z: z)
                graphNodes.append(node)
                idCnt += 1
            } else if line.first == "l" {
                // now we need to link them
                let links = line.components(separatedBy: " ")
                guard let origin = Int(links[1]) else {
                    print("not a int: \(links[1])")
                    continue
                }
                guard let destination = Int(links[2]) else {
                    print("not a int: \(links[2])")
                    continue
                }
                // set connection where origin goes to destination (to) on origin
                if graphNodes[origin-1].to == nil {
                    graphNodes[origin-1].to = [destination-1]
                } else {
                    graphNodes[origin-1].to!.append(destination-1)
                }
                
                // set connection where destination goes to origin (from) on destination
                // this is the reverse direction of the graph
                if graphNodes[destination-1].from == nil {
                    graphNodes[destination-1].from = [origin-1]
                } else {
                    graphNodes[destination-1].from!.append(origin-1)
                }
            }
        }
        
        return RoadGraph(nodes: graphNodes)
    }
    
    private static func readObj(filename: String) -> [String] {
        if let filePath = Bundle.main.path(forResource: filename, ofType: "obj") {
            do {
                let data = try String(contentsOfFile: filePath, encoding: .utf8)
                let lines = data.components(separatedBy: .newlines)
                return lines
            } catch {
                print(error)
            }
        }
        return []
    }
}
