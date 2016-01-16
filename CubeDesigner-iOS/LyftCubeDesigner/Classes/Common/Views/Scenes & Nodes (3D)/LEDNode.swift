import SceneKit

private let LEDOffColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)

final class LEDNode: SCNNode {

    /// A boolean indicating if the node color was set or the led is "off"
    var colorIsSet: Bool { return self.color != nil }

    /// Sets color on the node's geometry
    var color: UIColor? {
        didSet {
            if oldValue != self.color {
                self.updateGemetryWithColor(self.color)
            }
        }
    }

    /// x, y, z coordinates on the LED Cube
    var coordinates: (x: Int, y: Int, z: Int)

    init(size: CGFloat, coordinates: (x: Int, y: Int, z: Int)) {
        self.coordinates = coordinates
        super.init()

        self.geometry = SCNBox(width: size, height: size, length: size, chamferRadius: size / 4.0)
        self.updateGemetryWithColor(self.color)
    }

    required init?(coder aDecoder: NSCoder) {
        self.coordinates = (0, 0, 0)
        super.init(coder: aDecoder)
        self.updateGemetryWithColor(self.color)
    }

    private func updateGemetryWithColor(color: UIColor?) {
        var cubeMaterial: SCNMaterial! = self.geometry?.materials.first
        if cubeMaterial == nil {
            cubeMaterial = SCNMaterial()
            self.geometry?.materials = [cubeMaterial]
        }

        cubeMaterial.diffuse.contents = color ?? LEDOffColor
    }
}
