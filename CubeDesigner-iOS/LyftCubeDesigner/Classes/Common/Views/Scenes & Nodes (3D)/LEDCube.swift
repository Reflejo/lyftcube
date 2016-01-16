import SceneKit

protocol LEDCubeDelegate: class {

    /**
     This method is called when the frame changed (and it's loaded).

     - parameter frame:         The frame after the change
     - parameter isAnimating:   A boolean indicating if the frame change was product of an animtion
     */
    func frameDidChange(frame: Int, isAnimating: Bool)
}

final class LEDCube: SCNNode {

    private weak var playTimer: NSTimer?

    /// We'll send all Cube events if a delegate is set.
    weak var delegate: LEDCubeDelegate?

    /// The animation struct holding all the frames with colors
    var animation = Animation(name: "Unsaved") {
        didSet { self.loadColors(self.animation.frames[self.frame].colors) }
    }

    /// Helper to access only the child nodes that are LEDNode(s)
    var ledNodes: [LEDNode] { return self.childNodes.flatMap { $0 as? LEDNode } }

    /// A boolean indicating whether there is an animation playing.
    var isPlaying: Bool { return self.playTimer?.valid == true }

    /// The number of frames on the current animation
    var framesCount: Int { return self.animation.frames.count }

    /// The current animation frame
    var frame = 0 {
        didSet {
            if oldValue == self.frame {
                return
            }

            self.loadColors(self.animation.frames[self.frame].colors)
            self.delegate?.frameDidChange(self.frame, isAnimating: self.isPlaying)
        }
    }

    init(elementsCount: Int = 8, size: CGFloat = 0.60, side: Float = 10.5) {
        super.init()

        let space = side / Float(elementsCount)

        // Add 8 x 8 x 8 boxes.
        for x in 0 ..< elementsCount {
            for y in 0 ..< elementsCount {
                for z in 0 ..< elementsCount {
                    let cubeNode = LEDNode(size: size, coordinates: (x, y, z))
                    cubeNode.position = SCNVector3(
                        x: Float(x) * space, y: Float(y) * space, z: Float(z) * space)
                    self.addChildNode(cubeNode)
                }
            }
        }

        // Add first frame
        self.animation.frames.append(LEDCubeFrame())
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /**
     Toggles between play and stop actions on the animation.
     */
    func togglePlay() {
        if self.isPlaying {
            self.playTimer?.invalidate()
        } else {
            self.playFrame(0)
        }
    }

    /**
     Removes the last animation frame and sets the current frame as needed.
     */
    func removeLastFrame() {
        if self.animation.frames.count > 1 {
            self.frame = min(self.frame, self.animation.frames.count - 2)
            self.animation.frames.removeLast()
        }
    }

    /**
     Creates an empty state and appends it to the frames array
     */
    func appendFrame() {
        self.animation.frames.append(LEDCubeFrame())
    }

    /**
     Sets a color on the given node, this method will also keep this change in the frames array.

     - parameter node:  The node to be modified
     - parameter color: The color to set on the node
     */
    func setLEDColor(node: LEDNode, color: UIColor?) {
        let (x, y, z) = node.coordinates
        node.color = color
        self.animation.frames[self.frame].colors[x][y][z] = color
    }

    // MARK: - Private helpers

    private func playFrame(frame: Int) {
        self.frame = frame

        let interval = self.animation.frames[frame].duration * 1.5
        self.playTimer = NSTimer.scheduledTimerWithTimeInterval(interval) { [weak self] _ in
            self?.playFrame(frame + 1 >= self?.animation.frames.count ? 0 : frame + 1)
        }
    }

    private func colors() -> [[[UIColor?]]] {
        let x = [UIColor?](count: 8, repeatedValue: nil)
        let y = [[UIColor?]](count: 8, repeatedValue: x)
        var colors = [[[UIColor?]]](count: 8, repeatedValue: y)

        for node in self.ledNodes {
            let (x, y, z) = node.coordinates
            colors[x][y][z] = node.color
        }

        return colors
    }
    
    private func loadColors(colors: [[[UIColor?]]]) {
        for node in self.ledNodes {
            let (x, y, z) = node.coordinates
            node.color = colors[x][y][z]
        }
    }
}
