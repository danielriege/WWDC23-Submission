//
//  MainApp.swift
//  
//
//  Created by Daniel Riege on 06.04.23.
//

import SwiftUI
import SceneKit

@main
struct MainApp: App {
    var scene: WorldScene
    var robocar: RobocarModel
    var robocarSoftware: AVPipelineStack
    var guiModel: GUIModel
    var simulationPipeline: SimulationPipeline
    
    init() {
        let graph = RoadGraph.getRoadGraph(objFilename: "road_graph")
        self.scene = WorldScene()
        self.guiModel = GUIModel()
        
        let robocarStartNode = graph.getNode(id: 140)
        self.robocar = RobocarModel(transform: graph.get3DTransform(node: robocarStartNode, east: true))
        self.robocarSoftware = AVPipelineStack(pathplanning: Pathplanning(graph: graph, startNode: robocarStartNode),
                                               pidSpeedController: PIDController())
        
        let obstacle1Origin = graph.getNode(id: 0)
        let obstacle1 = Obstacle(robocar: RobocarModel(transform: graph.get3DTransform(node: obstacle1Origin, east: true), color: CGColor(red: 0.0, green: 0.0, blue: 0.7, alpha: 1.0)),
                                 pathplanning: Pathplanning(graph: graph, startNode: obstacle1Origin))
        
        let obstacle2Origin = graph.getNode(id: 160)
        let obstacle2 = Obstacle(robocar: RobocarModel(transform: graph.get3DTransform(node: obstacle2Origin, east: true), color: CGColor(red: 0.7, green: 0.0, blue: 0.0, alpha: 1.0)),
                                 pathplanning: Pathplanning(graph: graph, startNode: obstacle2Origin))
    
        self.simulationPipeline = SimulationPipeline(guiModel: guiModel, robocar: robocar, robocarSoftware: robocarSoftware, obstacles: [obstacle1, obstacle2], scene: scene)
    }
    
    var body: some Scene {
        WindowGroup {
            MainView(model: self.guiModel, simulationPipeline: simulationPipeline, scene: self.scene)
                .preferredColorScheme(.light)
        }
    }
}
