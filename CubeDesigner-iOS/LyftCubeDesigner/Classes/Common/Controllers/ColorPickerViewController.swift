import UIKit
import PKHUD

private let kReuseIdentifierCell = "colorCell"
private let kDefaultTotalColors = 60

final class ColorPickerViewController: UIViewController {

    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var spinner: UIActivityIndicatorView!

    private var indexPathForSelectedColor: NSIndexPath {
        let hueStep = 1.0 / CGFloat(self.colorCount ?? 1)
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        self.selectedColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        let index = saturation == 0 ? 0 : Int(round(hue / hueStep) - 1.0)
        return NSIndexPath(forItem: index, inSection: 0)
    }

    /// A boolean indicating if the view controller should auto-dismiss on selection. Default: true
    var autoDismissOnSelection = true

    /// A closure that is called on each color selection.
    var onColorSelection: (UIColor -> Void)?

    /// The currently selected color
    var selectedColor = UIColor.whiteColor() {
        didSet { self.onColorSelection?(self.selectedColor) }
    }

    /// The total number of colors, incrementing this number will decrease the HUE step between colors.
    var colorCount: Int? {
        didSet { self.collectionView.reloadData() }
    }

    override func viewDidLoad() {
        self.colorCount = 0
        super.viewDidLoad()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        self.spinner.stopAnimating()
        self.colorCount = kDefaultTotalColors
        self.collectionView.selectItemAtIndexPath(self.indexPathForSelectedColor, animated: true,
            scrollPosition: .None)
    }

    private func colorForIndex(index: Int) -> UIColor {
        if index == 0 {
            return UIColor(hue: 0.0, saturation: 0.0, brightness: 1.0, alpha: 1.0)
        }

        let hueStep = 1.0 / CGFloat(self.colorCount ?? 1)
        return UIColor(hue: hueStep * CGFloat(index + 1), saturation: 1.0, brightness: 1.0, alpha: 1.0)
    }

    @IBAction private func close() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}


// MARK: - CollectionView delegate implementation

extension ColorPickerViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.colorCount ?? 0
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath)
        -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(
            kReuseIdentifierCell, forIndexPath: indexPath) as! ColorViewCell
        cell.backgroundColor = self.colorForIndex(indexPath.item)
        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.selectedColor = self.colorForIndex(indexPath.item)

        if self.autoDismissOnSelection {
            self.close()
        }
    }
}