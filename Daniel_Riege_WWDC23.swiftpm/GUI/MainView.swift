import SwiftUI
import SceneKit

struct MainView: View {
    @State private var showIntro = true
    @StateObject var model: GUIModel
    
    private let rotationChangePublisher = NotificationCenter.default
            .publisher(for: UIDevice.orientationDidChangeNotification)
    
    var simulationPipeline: SimulationPipeline
    var scene: SCNScene
    
    var body: some View {
        ZStack {
            VStack {
                ZStack {
                    SceneKitView(scene: scene, simulationDelegate: simulationPipeline, onboardView: $model.onboardCamera)
                        .padding(.bottom, -35)
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                showIntro.toggle()
                            } label: {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 20))
                            }
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(15.0)
                            .shadow(radius: 5.0)
                            .offset(x: -20, y: 10)
                        }
                    }
                }
                switch model.currentScenario {
                case .manualControl:
                    ManualControlView(maxSpeed: $model.controlThrottle, steering: $model.controlSteering, maxAcceleration: $model.maxAcceleration, maxDeacceleration: $model.maxDeacceleration, maxSteeringChange: $model.maxSteeringChange, speeds: $model.speeds, steeringAngles: $model.steeringAngles)
                case .lateralControl:
                    LateralControlView(crossTrackErrors: $model.crossTrackErrors, headingErrors: $model.headingErrors, stanleyGain: $model.stanleyGain, speed: $model.controlThrottle, intersectionHeuristic: $model.intersectionHeuristic)
                case .longitudinalControl:
                    LongitudinalControlView(maxSpeed: $model.controlThrottle, P: $model.P, I: $model.I, D: $model.D, maxDistance: $model.maxDistance, distances: $model.distances)
                case .overtakeManeuver:
                    OvertakeControlView(driveOnLane: $model.driveOnLane, maxSpeed: $model.controlThrottle, maxDistance: $model.maxDistance, distances: $model.distances, minDistanceForOvertake: $model.minDistanceForOvertake)
                }
            }
            VStack {
                ZStack {
                    DashboardView(runningSim: $model.simRunning, currentSpeed: $model.currentSpeed, wheelAngle: $model.dashboardWheelAngle)
                    HStack{
                        Spacer()
                        CameraControlView(onboardCamera: $model.onboardCamera, perceptionView: $model.perceptionView)
                    }
                    HStack {
                        ScenarioView(scenarioSelection: $model.currentScenario, simRunning: $model.simRunning)
                        Spacer()
                    }
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showIntro) {
            OnboardView(showOnboard: $showIntro, onboardData: introData)
                .preferredColorScheme(.light)
        }
        .onReceive(rotationChangePublisher) { _ in
            changeOrientation(to: UIInterfaceOrientation.landscapeLeft)
        }
    }
    
    func changeOrientation(to orientation: UIInterfaceOrientation) {
            // tell the app to change the orientation
            UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        }
    
    private let introData: [OnboardData] = [
        OnboardData(id: 0, primaryText: "Welcome to this Playground App", secondaryText: "This playground app is all about autonomous driving. Learn how a self driving car works by tuning several parameters on the fly. In this Low Poly 3D world the car can keep its lane, follow a car ahead and overtake it. This simplified self driving software should give you a feel for the basics on what is coming in the next few years."),
        OnboardData(id: 1, primaryText: "About this Simulation", secondaryText: "Besides the simulated ego car and traffic, a few self driving software components are simulated as well:\n\n        Lane Detection: This component detects different road markings which is the basis for the following components. \n        Object Detection: This component detects other road users and determines their position and direction. \n        Path Planning: Given the lane detection a local path in the center of the lane is generated. \n        Trajectory Following: This components consists of different controllers which set the steering angle (lateral control) and the speed (longitudinal control) of the car. \n\nA visualization of these components can be viewed in the Perception view. The perspective can also be changed into the cars front camera, which is often used for lane detection and object detection in several real world autonomous cars. In this playground app you will tune parameters for the trajectoy following component and alter the decision making of the path planning algorithm.\n\nNote: There is no Collision Detection in this simulation."),
        OnboardData(id: 2, primaryText: "Get the Best Experience", secondaryText: "In order to get the most of this playground app, it is recommended to start in the manual control scenario which is the default one. For different tasks there are different scenarios. After getting a feel for the car control with its parameters, maybe change the camera view by clicking on the blue car on the top right and maybe change the view to Perception. \nAfter that you can start by tuning the lateral control (used for steering) to keep the car optimal in lane and play around with different intersection decision makings. \nThe next step could be to optimize the lateral control (used for speed) to keep a safe distance to the car ahead and make it a smooth ride. \nThe last step would be to play around with the overtake maneuver and tuning the parameter to engange a safe maneuver. \n\n Keep in mind that the changes will persist between scenarios.")
    ]
}

struct SceneKitView : UIViewRepresentable {
    var scene: SCNScene
    var simulationDelegate: SimulationPipeline
    @Binding var onboardView: Bool
    
    var scnView = SCNView()
    
    func makeUIView(context: Context) -> SCNView {
        scnView.scene = scene
        scnView.delegate = simulationDelegate
        scnView.rendersContinuously = true
        scnView.allowsCameraControl = false
        scnView.showsStatistics = false
        //scnView.debugOptions = .showBoundingBoxes
        return scnView
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
        if onboardView {
            scnView.pointOfView = scene.rootNode.childNode(withName: "front_camera", recursively: true)
        } else {
            scnView.pointOfView = scene.rootNode.childNode(withName: "third_person_camera", recursively: false)
        }
    }
}
