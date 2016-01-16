import UIKit

class TextActionController: UIAlertController {

    /**
     Shows an action controller with an UITextField with the given placeholder and/or initial text.

     - parameter viewController: The UIViewController instance where this alert will be presented
     - parameter title:          The title of the action controller.
     - parameter placeholder:    The place holder for the UITextField
     - parameter includeCancel:  A boolean indicating if the alert includes a cancel button or not
     - parameter initialText:    The initial text to be set on the UITextField (if any)

     - returns: the newly created TextActionController
     */
    static func showIn(viewController: UIViewController, title: String?, placeholder: String? = nil,
        includeCancel: Bool = false, initialText: String? = nil) -> TextActionController
    {
        let alert = TextActionController(title: title, message: nil, preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler { textField in
            textField.text = initialText
            textField.placeholder = placeholder
        }

        if includeCancel {
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        }

        viewController.presentViewController(alert, animated: true, completion: nil)
        return alert
    }

    /**
     Adds a button (usually the OK button) with the given text and handler

     - parameter text:  The text to show as the CTA on the button
     - parameter onTap: A closure that will be called with the entered text
     */
    func setOKButton(text: String, onTap: (text: String?) -> Void) {
        let okButton = UIAlertAction(title: "OK", style: .Default) { action in
            onTap(text: self.textFields?.first?.text)
        }
        self.addAction(okButton)
    }
}