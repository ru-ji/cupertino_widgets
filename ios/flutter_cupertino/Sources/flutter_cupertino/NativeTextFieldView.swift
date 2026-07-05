import Flutter
import UIKit

class NativeTextFieldFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return NativeTextFieldView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            messenger: messenger
        )
    }

    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

/// A native single-line `UITextField` embedded as a Flutter platform view.
/// Reports edits back to Dart via the method channel and enforces `maxLength`
/// / `readOnly` through its delegate, so `CupertinoNativeTextField` can offer
/// Flutter-`TextField`-level customization.
class NativeTextFieldView: NSObject, FlutterPlatformView, UITextFieldDelegate {
    private let channel: FlutterMethodChannel
    private let container: UIView
    private let textField = UITextField()
    private var maxLength: Int?
    private var readOnly = false
    private var selectionActive = false

    /// Vertical breathing room so the selection handles/magnifier — which draw
    /// above and below the text — aren't clipped by the field's bounds.
    private let verticalInset: CGFloat = 8

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        messenger: FlutterBinaryMessenger
    ) {
        channel = FlutterMethodChannel(
            name: "flutter_cupertino/textfield_\(viewId)", binaryMessenger: messenger)
        container = UIView(frame: frame)

        super.init()

        container.backgroundColor = .clear
        // Let the selection handles / magnifier draw outside the field bounds.
        container.clipsToBounds = false
        textField.clipsToBounds = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .roundedRect
        container.addSubview(textField)
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textField.topAnchor.constraint(
                equalTo: container.topAnchor, constant: verticalInset),
            textField.bottomAnchor.constraint(
                equalTo: container.bottomAnchor, constant: -verticalInset),
        ])

        textField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        textField.addTarget(self, action: #selector(editingDidBegin), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(editingDidEnd), for: .editingDidEnd)
        textField.delegate = self

        if let dict = args as? [String: Any],
            let config = decodeConfig(TextFieldConfig.self, from: dict)
        {
            apply(config)
        }

        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
    }

    func view() -> UIView { container }

    // MARK: - Configuration

    private func apply(_ c: TextFieldConfig) {
        if let text = c.text, text != textField.text {
            textField.text = text
        }
        textField.placeholder = c.placeholder
        textField.isSecureTextEntry = c.obscureText ?? false
        textField.autocorrectionType = (c.autocorrect ?? true) ? .yes : .no
        textField.spellCheckingType = (c.enableSuggestions ?? true) ? .yes : .no
        textField.keyboardType = keyboardType(c.keyboardType)
        textField.returnKeyType = returnKeyType(c.textInputAction)
        textField.autocapitalizationType = autocapitalization(c.textCapitalization)
        textField.textAlignment = alignment(c.textAlign)
        textField.isEnabled = c.enabled ?? true
        textField.clearButtonMode = clearButtonMode(c.clearButtonMode)
        readOnly = c.readOnly ?? false
        maxLength = c.maxLength

        textField.textContentType = c.textContentType.flatMap(contentType(_:))

        let size = CGFloat(c.fontSize ?? 17)
        if let weightIndex = c.fontWeight {
            textField.font = .systemFont(ofSize: size, weight: uiFontWeight(weightIndex))
        } else {
            textField.font = .systemFont(ofSize: size)
        }
        if let textColor = c.textColor {
            textField.textColor = UIColor(argb: textColor)
        }
        if let cursorColor = c.cursorColor {
            textField.tintColor = UIColor(argb: cursorColor)
        }
        if c.autofocus == true {
            DispatchQueue.main.async { [weak self] in
                self?.textField.becomeFirstResponder()
            }
        }
    }

    @objc private func editingChanged() {
        channel.invokeMethod("onChanged", arguments: ["text": textField.text ?? ""])
    }

    @objc private func editingDidBegin() {
        channel.invokeMethod("onFocusChange", arguments: ["focused": true])
    }

    @objc private func editingDidEnd() {
        channel.invokeMethod("onFocusChange", arguments: ["focused": false])
        notifySelectionActive(false)
    }

    /// Tells Dart whether a non-empty selection (with its draggable handles)
    /// is currently on screen, so the Flutter-side gesture recognizer can
    /// claim every touch during that window — otherwise grabbing a handle
    /// looks like a scroll drag and gets ceded to the page.
    private func notifySelectionActive(_ active: Bool) {
        guard active != selectionActive else { return }
        selectionActive = active
        channel.invokeMethod("onSelectionActive", arguments: ["active": active])
    }

    // MARK: - UITextFieldDelegate

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        if readOnly { return false }
        guard let maxLength = maxLength else { return true }
        let current = textField.text ?? ""
        guard let r = Range(range, in: current) else { return true }
        let updated = current.replacingCharacters(in: r, with: string)
        return updated.count <= maxLength
    }

    func textFieldDidChangeSelection(_ textField: UITextField) {
        let active: Bool
        if let range = textField.selectedTextRange, !range.isEmpty {
            active = textField.isFirstResponder
        } else {
            active = false
        }
        notifySelectionActive(active)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        channel.invokeMethod("onEditingComplete", arguments: nil)
        channel.invokeMethod("onSubmitted", arguments: ["text": textField.text ?? ""])
        textField.resignFirstResponder()
        return true
    }

    // MARK: - Method channel

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getIntrinsicSize":
            let size = textField.intrinsicContentSize
            result([
                "width": Double(max(size.width, 100)),
                "height": Double(max(size.height, 36) + verticalInset * 2),
            ])
        case "updateTextField":
            if let dict = call.arguments as? [String: Any],
                let config = decodeConfig(TextFieldConfig.self, from: dict)
            {
                apply(config)
                result(nil)
            } else {
                result(FlutterError(code: "bad_args", message: "Missing config", details: nil))
            }
        case "setText":
            if let args = call.arguments as? [String: Any],
                let text = args["text"] as? String
            {
                if textField.text != text { textField.text = text }
                result(nil)
            } else {
                result(FlutterError(code: "bad_args", message: "Missing text", details: nil))
            }
        case "focus":
            textField.becomeFirstResponder()
            result(nil)
        case "unfocus":
            textField.resignFirstResponder()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Mapping helpers

    private func keyboardType(_ name: String?) -> UIKeyboardType {
        switch name {
        case "number", "numberWithOptions": return .numbersAndPunctuation
        case "phone": return .phonePad
        case "datetime": return .numbersAndPunctuation
        case "emailAddress": return .emailAddress
        case "url": return .URL
        case "visiblePassword": return .asciiCapable
        case "name": return .namePhonePad
        case "streetAddress": return .default
        case "none": return .default
        default: return .default
        }
    }

    private func returnKeyType(_ name: String?) -> UIReturnKeyType {
        switch name {
        case "go": return .go
        case "search": return .search
        case "send": return .send
        case "next": return .next
        case "done": return .done
        case "continueAction": return .continue
        case "join": return .join
        case "route": return .route
        case "emergencyCall": return .emergencyCall
        case "newline": return .default
        default: return .default
        }
    }

    private func autocapitalization(_ name: String?) -> UITextAutocapitalizationType {
        switch name {
        case "words": return .words
        case "sentences": return .sentences
        case "characters": return .allCharacters
        default: return .none
        }
    }

    private func alignment(_ name: String?) -> NSTextAlignment {
        switch name {
        case "left": return .left
        case "right": return .right
        case "center": return .center
        case "end": return .right
        case "justify": return .justified
        default: return .natural  // "start"
        }
    }

    private func clearButtonMode(_ name: String?) -> UITextField.ViewMode {
        switch name {
        case "whileEditing": return .whileEditing
        case "unlessEditing": return .unlessEditing
        case "always": return .always
        default: return .never
        }
    }

    /// Maps friendly content-type names to `UITextContentType`, so callers pass
    /// e.g. `"password"` rather than the raw UIKit constant. Falls back to the
    /// raw value for anything not listed.
    private func contentType(_ name: String) -> UITextContentType? {
        switch name {
        case "password": return .password
        case "newPassword": return .newPassword
        case "username": return .username
        case "emailAddress": return .emailAddress
        case "oneTimeCode": return .oneTimeCode
        case "name": return .name
        case "givenName": return .givenName
        case "familyName": return .familyName
        case "telephoneNumber": return .telephoneNumber
        case "URL", "url": return .URL
        case "fullStreetAddress": return .fullStreetAddress
        case "postalCode": return .postalCode
        default: return UITextContentType(rawValue: name)
        }
    }

    private func uiFontWeight(_ index: Int) -> UIFont.Weight {
        switch index {
        case 0: return .ultraLight
        case 1: return .thin
        case 2: return .light
        case 3: return .regular
        case 4: return .medium
        case 5: return .semibold
        case 6: return .bold
        case 7: return .heavy
        case 8: return .black
        default: return .regular
        }
    }
}
