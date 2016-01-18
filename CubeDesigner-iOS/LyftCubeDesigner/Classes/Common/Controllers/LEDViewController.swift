import UIKit
import SceneKit
import SCLAlertView
import SVProgressHUD
import ClosureKit

private enum ShowState {
    case Active, None
}

final class LEDViewController: UIViewController {

    @IBOutlet private var sceneView: LEDCubeView!
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var frameLabel: UILabel!
    @IBOutlet private var durationButton: UIButton!
    @IBOutlet private var colorButton: UIButton!
    @IBOutlet private var slider: UISlider!

    private weak var frameLabelAnimationTimer: NSTimer?

    private var showState = ShowState.Active
    private var cube: LEDCube { return self.sceneView.LEDScene.cube }
    private var isPanCleaning: Bool?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.slider.setThumbImage(UIImage(named: "Slider Knot"), forState: .Normal)
        self.slider.setThumbImage(self.slider.thumbImageForState(.Normal), forState: .Highlighted)

        self.sceneView.LEDScene.selectCubesAtPanel(0)
        self.cube.delegate = self
        self.sceneView.actionDelegate = self
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.destinationViewController {
            case is ColorPickerViewController:
                let viewController = segue.destinationViewController as? ColorPickerViewController
                viewController?.selectedColor = self.colorButton.tintColor
                viewController?.onColorSelection = { [weak self] in self?.colorButton.tintColor = $0 }

            case is LoadAnimationViewController:
                let viewController = segue.destinationViewController as? LoadAnimationViewController
                viewController?.onAnimationSelection = { [weak self] in self?.loadAnimation($0) }

            default:
                break
        }
    }

    // MARK: - Control actions

    @IBAction private func sliderTouchUp(slider: UISlider) {
        slider.setValue(round(slider.value), animated: true)
    }

    @IBAction private func changeFrame(slider: UISlider) {
        let value = Int(round(slider.value))
        if self.cube.frame == value - 1 {
            return
        }

        self.cube.frame = value - 1
    }

    @IBAction private func nextFrame() {
        self.cube.frame = min(self.cube.frame + 1, self.cube.framesCount - 1)
    }

    @IBAction private func previousFrame() {
        self.cube.frame = max(self.cube.frame - 1, 0)
    }

    @IBAction private func addFrame() {
        self.slider.maximumValue = Float(self.cube.framesCount + 1)
        self.cube.appendFrame()
        self.cube.frame = self.cube.framesCount - 1
    }

    @IBAction private func removeFrame() {
        self.slider.maximumValue = Float(self.cube.framesCount - 1)
        self.cube.removeLastFrame()
        self.cube.frame = self.cube.framesCount - 1
    }

    @IBAction private func saveAnimation() {
        let alert = AlertView()
        let textField = alert.addTextField("Animation name", keyboardType: .Default)
        textField.text = self.cube.animation.name
        alert.showEdit("Save animation", subTitle: "Enter animation name", closeButtonTitle: "Save")
            .setDismissBlock {
                guard let text = textField.text where !text.isEmpty else {
                    return
                }

                self.nameLabel.text = text

                SVProgressHUD.showWithStatus("Saving")
                self.cube.animation.name = text
                self.cube.animation.saveTo(Directory.Save) { _ in
                    SVProgressHUD.showSuccessWithStatus("Saved")
                }
            }
    }

    @IBAction private func play(sender: UIButton) {
        sender.selected = !sender.selected
        self.setShowState(self.cube.isPlaying ? .Active : .None)
        self.cube.togglePlay()
    }

    @IBAction private func toggleEditTool(sender: UIButton) {
        sender.selected = !sender.selected
        self.sceneView.panEditsCube = sender.selected
    }

    @IBAction private func sendToCube(sender: UIButton) {
        SVProgressHUD.show()
        LyftCubeAPI.playAnimation(self.cube.animation) { animationID in
            if animationID == nil {
                executeAfter(0.2) { SVProgressHUD.showErrorWithStatus("Failed") }
                return
            }

            SVProgressHUD.showSuccessWithStatus("Sent")
            if let path = self.cube.animation.path {
                _ = try? NSFileManager.defaultManager().removeItemAtPath(path)
            }
        }
    }

    @IBAction private func changeDuration(sender: UIButton) {
        let alert = AlertView()
        let textField = alert.addTextField("Duration, e.g: 0.02", keyboardType: .DecimalPad)
        textField.text = String(format: "%.2f", self.cube.animation.frames[self.cube.frame].duration)
        alert.showEdit("Frame duration", subTitle: "Enter frame duration in seconds" )
            .setDismissBlock {
                let duration = NSTimeInterval(textField.text ?? "") ?? 0.02
                self.cube.animation.frames[self.cube.frame].duration = duration
                self.frameDidChange(self.cube.frame, isAnimating: true)
            }
    }

    @IBAction private func toolbarLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state != .Began {
            return
        }

        let alert = AlertView()
        alert.showCloseButton = false
        alert.addButton("Start Cube") { LyftCubeAPI.start() }
        alert.addButton("Shutdown Cube") { LyftCubeAPI.stop() }
        alert.showWarning("Cube admin actions", subTitle: "")
    }

    // MARK: - Private helpers

    private func loadAnimation(animation: Animation) {
        self.cube.frame = 0
        self.cube.animation = animation
        self.slider.maximumValue = Float(self.cube.framesCount)
        self.nameLabel.text = animation.name ?? "Unsaved"
        self.setShowState(.Active)
        self.frameDidChange(0, isAnimating: true)
    }

    private func setShowState(state: ShowState) {
        self.showState = state

        let scene = self.sceneView.LEDScene
        switch state {
            case .None:
                scene.selectCubesAtPanel(nil)

            case .Active:
                scene.selectCubesAtPanel(0)
        }
    }
}

// MARK: - LEDCubeViewDelegate implementation

extension LEDViewController: LEDCubeViewDelegate {

    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        var animation = Animation()
        animation.frames = [LEDCubeFrame()]
        self.loadAnimation(animation)
    }

    func didTapLED(LED: LEDNode, onLEDCube cube: LEDCube) {
        cube.setLEDColor(LED, color: LED.colorIsSet ? nil : self.colorButton.tintColor)
        cube.animation.id = nil
    }

    func didSwipeOnLEDCube(cube: LEDCube, direction: UISwipeGestureRecognizerDirection) {
        let scene = self.sceneView.LEDScene
        let delta = direction == .Right || direction == .Up ? 1 : -1
        scene.selectCubesAtPanel(scene.selectedPanel + delta,
            horizontal: direction == .Up || direction == .Down)
    }

    func didHoverLED(LED: LEDNode, onLEDCube cube: LEDCube) {
        self.isPanCleaning = self.isPanCleaning ?? LED.colorIsSet
        cube.setLEDColor(LED, color: self.isPanCleaning == true ? nil : self.colorButton.tintColor)
        cube.animation.id = nil
    }

    func panDidEndOnLEDCube(cube: LEDCube) {
        self.isPanCleaning = nil
    }
}

// MARK: - LEDCubeDelegate implementation

extension LEDViewController: LEDCubeDelegate {

    func frameDidChange(frame: Int, isAnimating: Bool) {
        self.setShowState(self.showState)
        self.slider.value = Float(frame + 1)

        let duration = String(format: "%.2fs", self.cube.animation.frames[self.cube.frame].duration)
        self.durationButton.setTitle(duration, forState: .Normal)

        if !isAnimating {
            // Show frame number by fading in the label and animating the label app
            self.frameLabel.text = String(frame + 1)

            let animationRunning = self.frameLabelAnimationTimer?.valid == true
            self.frameLabelAnimationTimer?.invalidate()
            self.frameLabelAnimationTimer = NSTimer.scheduledTimerWithTimeInterval(0.4) { timer in
                UIView.animateWithDuration(0.2) {
                    self.frameLabel.alpha = 0.0
                    self.frameLabel.frame.origin.y += 20
                }
            }

            if !animationRunning {
                self.frameLabel.frame.origin.y += 20
                UIView.animateWithDuration(0.2) {
                    self.frameLabel.alpha = 1.0
                    self.frameLabel.frame.origin.y -= 20
                }
            }
        }
    }
}
