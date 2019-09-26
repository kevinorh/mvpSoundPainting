/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The sample app's main view controller.
*/

import UIKit
import RealityKit
import ARKit
import Combine

class ViewController: UIViewController, ARSessionDelegate {

    @IBOutlet var arView: ARView!
    @IBOutlet weak var messageLabel: MessageLabel!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var labely: UILabel!
    @IBOutlet weak var labelz: UILabel!
    @IBOutlet weak var labelSpeed: UILabel!
    
    // The 3D character to display.
    var character: BodyTrackedEntity?
    var characterOffset: SIMD3<Float> = [1, 0, 0] // Offset the character by one meter to the left
    let characterAnchor = AnchorEntity()
    
    // A tracked raycast which is used to place the character accurately
    // in the scene wherever the user taps.
    var placementRaycast: ARTrackedRaycast?
    var tapPlacementAnchor: AnchorEntity?
    
    var lastHandPosition: [Float] = [0,0,0]
    var count = 0;
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        arView.session.delegate = self
        
        // If the iOS device doesn't support body tracking, raise a developer error for
        // this unhandled case.
        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("This feature is only supported on devices with an A12 chip")
        }

        // Run a body tracking configration.
        let configuration = ARBodyTrackingConfiguration()
        arView.session.run(configuration)
        
        arView.scene.addAnchor(characterAnchor)
        
        // Asynchronously load the 3D character.
        var cancellable: AnyCancellable? = nil
        cancellable = Entity.loadBodyTrackedAsync(named: "character/robot").sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error: Unable to load model: \(error.localizedDescription)")
                }
                cancellable?.cancel()
        }, receiveValue: { (character: Entity) in
            if let character = character as? BodyTrackedEntity {
                // Scale the character to human size
                character.scale = [0.3, 0.3, 0.3]
                self.character = character
                cancellable?.cancel()
            } else {
                print("Error: Unable to load model as BodyTrackedEntity")
            }
        })
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }
            var handPosition = simd_make_float3((bodyAnchor.skeleton.modelTransform(for: ARSkeleton.JointName.rightHand)?.columns.3)!);
            label.text = "x: \(handPosition.x*100)";
            labely.text = "y: \(handPosition.y*100)";
            labelz.text = "z: \(handPosition.z*100)";
            if(count == 30){
            var speed = pow(handPosition.x - lastHandPosition[0],2)+pow(handPosition.y - lastHandPosition[1],2)+pow(handPosition.z - lastHandPosition[2],2);
                //pow((handPosition.x - lastHandPosition[0]), 2) + pow( handPosition.x - lastHandPosition[1], 2) + pow(handPosition.x - lastHandPosition[2], 2)
            labelSpeed.text = "speed: \(sqrtf(speed)*60)"
            print(sqrtf(speed)*60)
                count = 0
            }
            lastHandPosition = [handPosition.x , handPosition.y , handPosition.z]
            characterOffset = handPosition;
            // Update the position of the character anchor's position.
            let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
            characterAnchor.position = bodyPosition + characterOffset
            // Also copy over the rotation of the body anchor, because the skeleton's pose
            // in the world is relative to the body anchor's rotation.
            characterAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation
   
            if let character = character, character.parent == nil {
                // Attach the character to its anchor as soon as
                // 1. the body anchor was detected and
                // 2. the character was loaded.
                characterAnchor.addChild(character)
            }
        }
        count += 1
    }
}
