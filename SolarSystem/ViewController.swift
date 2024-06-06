//
//  ViewController.swift
//  SolarSystem
//
//  Created by Quentin on 04/06/2024.
//

import UIKit
import SceneKit
import ARKit

class Planet {
    let node: SCNNode
    let orbitNode: SCNNode
    let speed: Float
    let distance: Float
    
    
    
    init(name: String, radius: CGFloat, speed: Float, distance: Float, sunPosition: SCNVector3) {
        node = SCNNode(geometry: SCNSphere(radius: radius))
        node.geometry?.firstMaterial?.diffuse.contents = UIImage(named: name)
        node.position = SCNVector3(x: distance, y: 0, z: 0)
        
        orbitNode = SCNNode()
        orbitNode.position = sunPosition
        orbitNode.addChildNode(node)
        
        self.speed = speed
        self.distance = distance
    }
    
    func addOrbitAnimation(durationMultiplier: Float) {
        let rotation = CABasicAnimation(keyPath: "rotation")
        rotation.toValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: Float(CGFloat.pi) * 2))
        rotation.duration = CFTimeInterval(10 * durationMultiplier / self.speed)
        rotation.repeatCount = .infinity
        orbitNode.addAnimation(rotation, forKey: "\(node.name ?? "planet")Orbit")
    }
}


class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    var isSystemDisplayed = false
    let anchorNode = SCNNode()
    
    func createPlanets(sunPosition: SCNVector3) -> [Planet] {
        return [
            Planet(name: "Mercury", radius: 0.1 * (4_880.0 / 1_392_700.0), speed: 47.87, distance: 0.1, sunPosition: sunPosition),
            Planet(name: "Venus", radius: 0.1 * (12_104.0 / 1_392_700.0), speed: 35.02, distance: 0.11, sunPosition: sunPosition),
            Planet(name: "Earth", radius: 0.1 * (12_742.0 / 1_392_700.0), speed: 29.78, distance: 0.13, sunPosition: sunPosition),
            Planet(name: "Mars", radius: 0.1 * (6_779.0 / 1_392_700.0), speed: 24.07, distance: 0.15, sunPosition: sunPosition),
            Planet(name: "Jupiter", radius: 0.1 * (139_820.0 / 1_392_700.0), speed: 13.07, distance: 0.17, sunPosition: sunPosition),
            Planet(name: "Saturn", radius: 0.1 * (116_460.0 / 1_392_700.0), speed: 9.68, distance: 0.19, sunPosition: sunPosition),
            Planet(name: "Uranus", radius: 0.1 * (50_724.0 / 1_392_700.0), speed: 6.80, distance: 0.21, sunPosition: sunPosition),
            Planet(name: "Neptune", radius: 0.1 * (49_244.0 / 1_392_700.0), speed: 5.43, distance: 0.23, sunPosition: sunPosition)
        ]
    }


    
    @IBOutlet weak var buttonSetPlanets: UIButton!
    @IBOutlet var sceneView: ARSCNView!
    
    @IBAction func setAnchorButton(_ sender: Any) {
        guard isSystemDisplayed == false else { return }
        isSystemDisplayed = true
        
        // Create the Sun
        let solarNode = SCNNode(geometry: SCNSphere(radius: 0.1))
        solarNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "Solar")
        
        // Check if there's a detected plane anchor
        if let planeAnchor = self.sceneView.session.currentFrame?.anchors.first(where: { $0 is ARPlaneAnchor }) as? ARPlaneAnchor {
            // Position the solar node at the center of the detected plane
            solarNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        } else {
            // If no plane anchor is detected, place the solar node at the origin
            solarNode.position = SCNVector3Zero
            print("origin")
        }
        
        sceneView.scene.rootNode.addChildNode(solarNode)
        
        // Create planets
        let planets = createPlanets(sunPosition: solarNode.position)
        
        for planet in planets {
            sceneView.scene.rootNode.addChildNode(planet.orbitNode)
            planet.addOrbitAnimation(durationMultiplier: 29.78) // Base speed for Earth
        }
        
        print("Solar node and planets added with rotation animations")
    }

    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        buttonSetPlanets.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.isAutoFocusEnabled = false
        configuration.planeDetection = [.horizontal]
        
        UIApplication.shared.isIdleTimerDisabled = true
        sceneView.autoenablesDefaultLighting = true
        configuration.isCollaborationEnabled = true
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()

    }
    
    // MARK: - ARSCNViewDelegate


    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Place du contenu uniquement pour les ancres détectées par la détection de plan.
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

        DispatchQueue.main.async {
            self.buttonSetPlanets.isEnabled = true
        }

        // Crée un node de géométrie plane pour visualiser le plan détecté
        let planeGeometry = SCNPlane(width: CGFloat(planeAnchor.planeExtent.width), height: CGFloat(planeAnchor.planeExtent.height))
        let planeNode = SCNNode(geometry: planeGeometry)
        planeNode.position = SCNVector3(planeAnchor.center.x, 1, planeAnchor.center.z)
        planeNode.eulerAngles.x = -.pi / 2 // Rotation du plan pour être horizontal

        // Applique un material semi-transparent au node du plan
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "Nebula")
        planeGeometry.materials = [material]
        node.addChildNode(planeNode)

        // Ajoute l'ancrage au milieu du plan
        anchorNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        node.addChildNode(anchorNode)
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if isSystemDisplayed == false {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

            // Met à jour la position de l'ancrage au milieu du plan
            anchorNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)

            // Met à jour la visualisation du node du plan
            for childNode in node.childNodes {
                if let planeGeometry = childNode.geometry as? SCNPlane {
                    planeGeometry.width = CGFloat(planeAnchor.planeExtent.width)
                    planeGeometry.height = CGFloat(planeAnchor.planeExtent.height)
                    childNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
                }
            }
        }
    }

    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user

    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required

    }
}
