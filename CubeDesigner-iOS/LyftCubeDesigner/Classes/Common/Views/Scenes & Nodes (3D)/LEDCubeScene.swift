import SceneKit
import SpriteKit

private let kCubeSideLength: Float = 10.4

final class LEDCubeScene: SCNScene {

    /// The LED Cube handles animations and LEDs state(s).
    var cube = LEDCube(side: kCubeSideLength)

    /// Currently selected panel
    var selectedPanel = 0

    /// The panel containing the camera, by moving this panel we "orbit" the cube
    var cameraOrbit: SCNNode!

    override init() {
        super.init()
        let center = -(kCubeSideLength - 1) / 2.0
        self.cube.position = SCNVector3(x: center, y: center, z: center)
        self.rootNode.addChildNode(self.cube)

        self.addCameraOrbit()

        let omniLight = SCNLight()
        omniLight.type = SCNLightTypeOmni

        let lightNode = SCNNode()
        lightNode.light = omniLight
        lightNode.position = SCNVector3(x: -3, y: 5, z: 3)
        
        self.rootNode.addChildNode(lightNode)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /**
     Select the given panel on the cube and deselect others if `deselectOthers` is true.

     - parameter panel:      The panel index to be selected range is [0, 7]
     - parameter horizontal: Whether we should select an horizontal panel (false) or a vertical (true)
     */
    func selectCubesAtPanel(panel: Int?, horizontal: Bool = false) {
        let panel = panel.map { min(max($0, 0), 7) }

        self.selectedPanel = panel ?? self.selectedPanel
        for node in self.cube.ledNodes {
            let (x, y, _) = node.coordinates
            let shouldSelected = (x == panel && !horizontal) || (y == panel && horizontal) || node.colorIsSet
            node.opacity = shouldSelected ? 1.0 : 0.1
        }
    }

    // MARK: - Private helpers

    private func addCameraOrbit() {
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 7
        camera.zFar = 100

        let ambientLight = SCNLight()
        ambientLight.type = SCNLightTypeAmbient
        ambientLight.color = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)

        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.light = ambientLight
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)

        self.cameraOrbit = SCNNode()
        self.cameraOrbit.addChildNode(cameraNode)
        self.cameraOrbit.eulerAngles.y = Float(-2 * M_PI) * 0.06
        self.cameraOrbit.eulerAngles.x = Float(-M_PI) * 0.06

        self.rootNode.addChildNode(self.cameraOrbit)
    }
}
