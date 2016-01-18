import SceneKit
import SpriteKit

protocol LEDCubeViewDelegate: class {

    /**
     This method will be called when a touch slides over a LED Node.

     - parameter LED:  The (first) LED node containing the point where the finger is
     - parameter cube: The LEDCube where the event occurred
     */
    func didHoverLED(LED: LEDNode, onLEDCube cube: LEDCube)

    /**
     This method will be called when a tap is recognized over a LED Node.

     - parameter LED:  The (first) LED node containing the point where the finger is
     - parameter cube: The LEDCube where the event occurred
     */
    func didTapLED(LED: LEDNode, onLEDCube cube: LEDCube)

    /**
     This method will be called when a swipe (on any direction) is recognized over the cube.

     - parameter cube:      The LEDCube where the event occurred
     - parameter direction: The direction of the swipe (Down, Up, Left, Right)
     */
    func didSwipeOnLEDCube(cube: LEDCube, direction: UISwipeGestureRecognizerDirection)

    /**
     This method will be called when the pan gesture is ended.

     - parameter cube: The LEDCube where the event occurred
     */
    func panDidEndOnLEDCube(cube: LEDCube)
}

final class LEDCubeView: SCNView {

    /// When set, this object will received all node events (touches, pan)
    weak var actionDelegate: LEDCubeViewDelegate?

    /// A boolean indicating if panning edits the cube (otherwise it'll orbit the camera)
    var panEditsCube: Bool = false

    /// Shortcut to access a strongly typed LEDCubeScene
    var LEDScene: LEDCubeScene { return self.scene as! LEDCubeScene }

    private var lastTouchPoint: CGPoint?
    private lazy var lastAngle: SCNVector3 = self.LEDScene.cameraOrbit.eulerAngles

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.scene = LEDCubeScene()
        self.configureGestures()
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        self.lastTouchPoint = touches.first?.locationInView(self)
    }

    // MARK: - Private helpers

    private func activeLEDAtPoint(point: CGPoint) -> LEDNode? {
        let options = [SCNHitTestBackFaceCullingKey: false, SCNHitTestRootNodeKey: self.LEDScene.cube]
        let result = self.hitTest(point, options: options).filter {
            ($0.node as? LEDNode)?.opacity >= CGFloat(1.0 - FLT_EPSILON)
        }

        return result.first?.node as? LEDNode
    }

    private func configureGestures() {
        let directions: [String: UISwipeGestureRecognizerDirection] = [
            "handleSwipeLeftGesture:": .Left, "handleSwipeRightGesture:": .Right,
            "handleSwipeUpGesture:": .Up, "handleSwipeDownGesture:": .Down,
        ]

        for (selector, direction) in directions {
            let swipeGesture = UISwipeGestureRecognizer(target: self, action: Selector(selector))
            swipeGesture.numberOfTouchesRequired = 2
            swipeGesture.direction = direction
            self.addGestureRecognizer(swipeGesture)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: "tapGesture:")
        self.addGestureRecognizer(tapGesture)

        let tapAndPanGesture = DoubleTapThenSwipeGestureRecognizer(target: self, action: "tapAndPanGesture:")
        self.addGestureRecognizer(tapAndPanGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: "handlePanGesture:")
        panGesture.maximumNumberOfTouches = 1
        self.addGestureRecognizer(panGesture)
    }
}

// MARK: - Gestures implementation

extension LEDCubeView {

    @objc
    private func handleSwipeLeftGesture(pan: UISwipeGestureRecognizer) {
        self.actionDelegate?.didSwipeOnLEDCube(self.LEDScene.cube, direction: .Left)
    }

    @objc
    private func handleSwipeRightGesture(pan: UISwipeGestureRecognizer) {
        self.actionDelegate?.didSwipeOnLEDCube(self.LEDScene.cube, direction: .Right)
    }

    @objc
    private func handleSwipeUpGesture(pan: UISwipeGestureRecognizer) {
        self.actionDelegate?.didSwipeOnLEDCube(self.LEDScene.cube, direction: .Up)
    }

    @objc
    private func handleSwipeDownGesture(pan: UISwipeGestureRecognizer) {
        self.actionDelegate?.didSwipeOnLEDCube(self.LEDScene.cube, direction: .Down)
    }

    @objc
    private func tapGesture(tap: UITapGestureRecognizer) {
        let point = tap.locationInView(self)
        if let LED = self.activeLEDAtPoint(point) {
            self.actionDelegate?.didTapLED(LED, onLEDCube: self.LEDScene.cube)
        }
    }

    @objc
    private func handlePanGesture(pan: UIPanGestureRecognizer) {
        if !self.panEditsCube {
            return self.tapAndPanGesture(pan)
        }

        if pan.state == .Began, let point = self.lastTouchPoint, LED = self.activeLEDAtPoint(point) {
            self.actionDelegate?.didHoverLED(LED, onLEDCube: self.LEDScene.cube)
        }

        let point = pan.locationInView(self)
        if let LED = self.activeLEDAtPoint(point) {
            self.actionDelegate?.didHoverLED(LED, onLEDCube: self.LEDScene.cube)
        }

        if pan.state == .Ended {
            self.actionDelegate?.panDidEndOnLEDCube(self.LEDScene.cube)
        }
    }

    @objc
    private func tapAndPanGesture(tapAndPan: UIPanGestureRecognizer) {
        switch tapAndPan.state {
            case .Changed, .Began:
                let translation = tapAndPan.translationInView(self)
                let yAngle = self.lastAngle.y - Float(translation.x / 200)
                let xAngle = self.lastAngle.x - Float(translation.y / 200)
                self.LEDScene.cameraOrbit.eulerAngles.y = max(min(yAngle, 3.14), -3.14)
                self.LEDScene.cameraOrbit.eulerAngles.x = max(min(xAngle, 1.5), -1.5)

            case .Ended:
                self.lastAngle = self.LEDScene.cameraOrbit.eulerAngles

            default:
                break
        }
    }
}

