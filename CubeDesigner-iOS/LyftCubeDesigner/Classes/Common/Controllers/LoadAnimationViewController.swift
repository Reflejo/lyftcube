import SVProgressHUD
import UIKit

private let kAnimationsDirectory = "lyftcubedesigner"
private let kEntryCellIdentifer = "entryCell"
private let kStartHue: CGFloat = 195.0 / 360.0
private let kHueStep: CGFloat = 0.010

struct Directory {

    /// The prefered path to store and load all animations.
    static var Save: String = {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let document = paths.first.map { $0 as NSString }
        return document?.stringByAppendingPathComponent(kAnimationsDirectory) ?? ""
    }()
}


final class LoadAnimationViewController: UIViewController {

    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var spinner: UIActivityIndicatorView!

    private var animations: [Animation] = []

    /// This closure will be called when an animation row is selected
    var onAnimationSelection: (Animation -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        let gifFiles = self.listGIFFiles()
        self.animations = gifFiles.map { Animation.fromGIF($0) }
        self.tableView.contentInset.top = self.tableView.scrollIndicatorInsets.top

        LyftCubeAPI.listAnimations { [weak self] animations in
            self?.spinner.stopAnimating()
            self?.animations.appendContentsOf(animations)
            self?.tableView.reloadData()
        }
    }

    private func listGIFFiles() -> [GIF] {
        let path = Directory.Save
        let manager = NSFileManager.defaultManager()
        if !manager.fileExistsAtPath(path) {
            _ = try? manager.createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
        }

        let files = try? manager.contentsOfDirectoryAtPath(path)
        return files?
            .filter { $0.hasSuffix("gif") }
            .flatMap { GIF(path: "\(path)/\($0)") }
            ?? []
    }

    @IBAction private func close() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

// MARK: - TableView delegate and data source implementation

extension LoadAnimationViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle,
        forRowAtIndexPath indexPath: NSIndexPath)
    {
        let animation = self.animations.removeAtIndex(indexPath.row)
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)

        if let animationID = animation.id {
            LyftCubeAPI.removeAnimation(animationID)
        }

        if let path = animation.path {
            _ = try? NSFileManager.defaultManager().removeItemAtPath(path)
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        SVProgressHUD.show()

        let animation = self.animations[indexPath.row]
        if animation.type == .Fixed, let path = animation.path, gif = GIF(path: path) {
            Animation.fromGIF(gif) { animation in
                SVProgressHUD.dismiss()
                self.onAnimationSelection?(animation)
            }

        } else if let animationID = animation.id {
            LyftCubeAPI.animationByID(animationID) { animation in
                SVProgressHUD.dismiss()
                if let animation = animation {
                    self.onAnimationSelection?(animation)
                }
            }

        } else {
            SVProgressHUD.dismiss()
            self.onAnimationSelection?(animation)
        }

        self.close()
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.animations.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(kEntryCellIdentifer) as! AnimationEntryViewCell

        let animation = self.animations[indexPath.row]
        let rowHue = kStartHue + CGFloat(indexPath.row) * kHueStep
        let color = UIColor(hue: rowHue, saturation: 0.8, brightness: 0.8, alpha: 1.0)
        cell.populateFromAnimation(animation, color: color)
        return cell
    }
}
