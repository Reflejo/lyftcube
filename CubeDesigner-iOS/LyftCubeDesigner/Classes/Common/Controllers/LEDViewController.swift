import UIKit
import SceneKit
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
        let text = self.cube.animation.name != "Unsaved" ? self.cube.animation.name : ""
        let alert = TextActionController.showIn(self, title: "Enter animation name",
            placeholder: "Animation name", initialText: text, includeCancel: true)
        alert.setOKButton("OK") { text in
            self.nameLabel.text = text

            SVProgressHUD.showWithStatus("Saving")
            self.cube.animation.name = text ?? ""
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
            if animationID != nil {
                SVProgressHUD.showSuccessWithStatus("Sent")
            } else {
                SVProgressHUD.showErrorWithStatus("Error")
            }

            if animationID != nil, let path = self.cube.animation.path {
                _ = try? NSFileManager.defaultManager().removeItemAtPath(path)
            }
        }
    }

    @IBAction private func changeDuration(sender: UIButton) {
        let text = String(format: "%.2f", self.cube.animation.frames[self.cube.frame].duration)
        let alert = TextActionController.showIn(self, title: "Enter animation duration", initialText: text)
        alert.setOKButton("OK") { text in
            self.cube.animation.frames[self.cube.frame].duration = NSTimeInterval(text ?? "") ?? 0.02
            self.frameDidChange(self.cube.frame, isAnimating: true)
        }
    }

    @IBAction private func toolbarLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state != .Began {
            return
        }

        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        sheet.addAction(UIAlertAction(title: "Start Cube", style: .Default) { _ in LyftCubeAPI.start() })
        sheet.addAction(UIAlertAction(title: "Shutdown Cube", style: .Default) { _ in LyftCubeAPI.stop() })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(sheet, animated: true, completion: nil)
    }

    // MARK: - Private helpers

    private func loadAnimation(animation: Animation) {
        self.cube.frame = 0
        self.cube.animation = animation
        self.slider.maximumValue = Float(self.cube.framesCount)
        self.nameLabel.text = animation.name
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
        var animation = Animation(name: "Unsaved")
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
