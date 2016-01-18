import SCLAlertView

final class AlertView: SCLAlertView {

    required init() {
        super.init()
        self.view.gestureRecognizers?.forEach(self.view.removeGestureRecognizer)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)

        if touches.first?.view?.frame == self.view.frame {
            self.hideView()
        }
    }

    /**
     Adds a textfield into the alert using the given keyboard type. The textField will be focus when shown.

     - parameter title:        The text field placeholder
     - parameter keyboardType: The keyboard type to use for when the field gains focus

     - returns: the newly created UITextField
     */
    func addTextField(title: String?, keyboardType: UIKeyboardType) -> UITextField {
        let textField = super.addTextField(title)
        textField.keyboardType = keyboardType
        textField.becomeFirstResponder()
        return textField
    }
}