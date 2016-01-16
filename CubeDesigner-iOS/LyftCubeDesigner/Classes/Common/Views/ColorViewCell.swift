import UIKit

final class ColorViewCell: UICollectionViewCell {

    @IBOutlet private var componentsLabel: UILabel!

    override var selected: Bool {
        didSet {
            self.layer.borderWidth = self.selected ? 3.0 : 1.0
            self.layer.borderColor = self.selected ? UIColor.whiteColor().CGColor : nil
        }
    }

    override var backgroundColor: UIColor? {
        didSet {
            let rgb = CGColorGetComponents(self.backgroundColor?.CGColor)
            let (r, g, b) = (Int(rgb[0] * 255.0), Int(rgb[1] * 255.0), Int(rgb[2] * 255.0))
            self.componentsLabel.text = "R: \(r)\nG: \(g)\nB: \(b)"

            let yiq = ((r * 299) + (g * 587) + (b * 114)) / 1000
            self.componentsLabel.textColor = yiq >= 128 ? .blackColor() : .whiteColor()
        }
    }
}
