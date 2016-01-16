import UIKit

final class AnimationEntryViewCell: UITableViewCell {

    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var frameLabel: UILabel!
    @IBOutlet private var typeLabel: UILabel!
    @IBOutlet private var wrapperView: UIView!

    private var rowBackgroundColor: UIColor?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectedBackgroundView = UIView()
    }

    /**
     Sets animation properties and background color on animation entry row.

     - parameter animation: The animation model containing its properties
     - parameter color:     The rounded wrapper background color
     */
    func populateFromAnimation(animation: Animation, color: UIColor) {
        self.nameLabel.text = animation.name
        self.wrapperView.backgroundColor = color
        self.typeLabel.text = animation.type.rawValue.capitalizedString

        let kiloBytes = Double(animation.fileSize ?? 0) / 1024.0
        self.frameLabel.text = String(format: "%.2f", kiloBytes)

        self.rowBackgroundColor = color
    }

    override func didTransitionToState(state: UITableViewCellStateMask) {
        super.didTransitionToState(state)

        let button = self.valueForKey("_deleteConfirmationView") as? UIView
        button?.frame.origin.y = self.wrapperView.frame.origin.y
        button?.frame.size.height = self.wrapperView.frame.height
    }

    override func setHighlighted(highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.wrapperView.backgroundColor = self.wrapperColor(highlighted: highlighted)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.wrapperView.backgroundColor = self.wrapperColor(highlighted: selected)
    }

    private func wrapperColor(highlighted highlighted: Bool) -> UIColor? {
        let selectedColor = self.rowBackgroundColor?.colorByAddingBrightness(0.0, andSaturationFactor: 0.7)
        return highlighted ? selectedColor : self.rowBackgroundColor
    }
}
