import Flutter
import UIKit

@available(iOS 15.0, *)
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

/// Container that reports layout passes, so the glass capsule's corner
/// radius can track the height while the app bar squeezes the field.
private final class SqueezableContainerView: UIView {
    var onLayout: (() -> Void)?
    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?()
    }
}

/// A native single-line `UITextField` embedded as a Flutter platform view.
/// Reports edits back to Dart via the method channel and enforces `maxLength`
/// / `readOnly` through its delegate, so `CupertinoNativeTextField` can offer
/// Flutter-`TextField`-level customization.
@available(iOS 15.0, *)
class NativeTextFieldView: NSObject, FlutterPlatformView, UITextFieldDelegate {
    private let channel: FlutterMethodChannel
    private let container: SqueezableContainerView
    private let textField = UITextField()
    private var maxLength: Int?
    private var readOnly = false
    private var selectionActive = false
    /// Liquid Glass background (iOS 26) / material fallback, behind the field.
    private var glassView: UIVisualEffectView?
    /// Configured capsule radius — clamped to half the current height during
    /// layout, so the squeezing capsule keeps valid continuous corners.
    private var glassCornerRadius: CGFloat = 16
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?

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
            name: "cupertino_widgets/textfield_\(viewId)", binaryMessenger: messenger)
        container = SqueezableContainerView(frame: frame)

        super.init()

        container.onLayout = { [weak self] in self?.clampGlassCorners() }

        container.backgroundColor = .clear
        // Let the selection handles / magnifier draw outside the field bounds.
        container.clipsToBounds = false
        textField.clipsToBounds = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        container.addSubview(textField)
        let leading = textField.leadingAnchor.constraint(equalTo: container.leadingAnchor)
        let trailing = textField.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        leadingConstraint = leading
        trailingConstraint = trailing
        let top = textField.topAnchor.constraint(
            equalTo: container.topAnchor, constant: verticalInset)
        let bottom = textField.bottomAnchor.constraint(
            equalTo: container.bottomAnchor, constant: -verticalInset)
        // The app bar squeezes the whole view below the insets' combined
        // 16pt during its collapse; sub-required priority lets the layout
        // compress gracefully instead of breaking constraints.
        top.priority = UILayoutPriority(999)
        bottom.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([leading, trailing, top, bottom])

        textField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        textField.addTarget(self, action: #selector(editingDidBegin), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(editingDidEnd), for: .editingDidEnd)
        textField.delegate = self

        // Tapping anywhere in the box (e.g. the glass padding) focuses the field.
        container.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(focusField)))

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
        // Apply Flutter's brightness to the container so UITextField matches
        // the Flutter theme (e.g. dark text on light background).
        if let isDark = c.isDark {
            container.overrideUserInterfaceStyle = isDark ? .dark : .light
        }
        // Background color — nil/transparent by default (iOS UITextField default).
        if let bg = c.backgroundColor {
            container.backgroundColor = UIColor(argb: bg)
        }
        // ...and its corner radius, drawn natively so a filled search capsule
        // needs nothing on the Flutter side.
        let radius = CGFloat(c.cornerRadius ?? 0)
        container.layer.cornerRadius = radius
        container.layer.cornerCurve = .continuous
        container.clipsToBounds = radius > 0

        // Where the single line of text sits within the field's height.
        switch c.verticalAlignment {
        case "top": textField.contentVerticalAlignment = .top
        case "bottom": textField.contentVerticalAlignment = .bottom
        default: textField.contentVerticalAlignment = .center
        }

        // Prefix / suffix SF Symbols via UITextField's native left/right views.
        textField.leftView = iconView(from: c.prefixIcon)
        textField.leftViewMode = textField.leftView != nil ? .always : .never
        textField.rightView = iconView(from: c.suffixIcon)
        textField.rightViewMode = textField.rightView != nil ? .always : .never

        applyGlass(c)
    }

    /// Small image view for a prefix/suffix SF Symbol.
    private func iconView(from icon: IconConfig?) -> UIView? {
        guard let icon, let symbolName = icon.sfSymbol else { return nil }
        let pointSize = CGFloat(icon.size ?? 17)
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
        let imageView = UIImageView(image: UIImage(systemName: symbolName, withConfiguration: config))
        imageView.tintColor = icon.color.map { UIColor(argb: $0) } ?? .secondaryLabel
        imageView.contentMode = .center
        // 8pt of clearance on each side, so the placeholder sits the same
        // distance from the symbol as it does in SwiftUI's `.searchable` field
        // (UITextField butts the text straight up against the left view).
        imageView.frame = CGRect(x: 0, y: 0, width: pointSize + 16, height: pointSize)
        return imageView
    }

    /// Liquid Glass capsule behind the field (iOS 26; ultra-thin material
    /// fallback earlier). The text gets a horizontal inset so it doesn't hug
    /// the glass edges; tapping anywhere on the glass focuses the field.
    private func applyGlass(_ c: TextFieldConfig) {
        glassView?.removeFromSuperview()
        glassView = nil
        let hasGlass = c.glass == true
        // A rounded background needs the same breathing room as the glass, or
        // the text runs into the capsule's curve.
        let inset: CGFloat = hasGlass || CGFloat(c.cornerRadius ?? 0) > 0 ? 16 : 0
        leadingConstraint?.constant = inset
        trailingConstraint?.constant = -inset
        guard hasGlass else { return }

        let effectView: UIVisualEffectView
        var interactiveGlass = false
        if #available(iOS 26.0, *) {
            let effect = UIGlassEffect(style: c.glassVariant == "clear" ? .clear : .regular)
            effect.isInteractive = c.glassInteractive ?? true
            interactiveGlass = effect.isInteractive
            if let tint = c.glassTint { effect.tintColor = UIColor(argb: tint) }
            effectView = UIVisualEffectView(effect: effect)
        } else {
            effectView = UIVisualEffectView(
                effect: UIBlurEffect(style: .systemUltraThinMaterial))
        }
        glassCornerRadius = CGFloat(c.glassCornerRadius ?? 16)
        effectView.layer.cornerRadius = glassCornerRadius
        effectView.layer.cornerCurve = .continuous
        effectView.clipsToBounds = true
        // Interactive glass only shimmers when the effect view receives the
        // touches. The container's tap recognizer still fires for hits on the
        // glass (recognizers observe subview hits), so tap-to-focus keeps
        // working either way.
        effectView.isUserInteractionEnabled = interactiveGlass
        if interactiveGlass {
            // Interactive glass ignores fully transparent content — the same
            // quirk as SwiftUI's .glassEffect on Color.clear — so keep a
            // near-invisible fill in the effect view to keep it alive.
            effectView.contentView.backgroundColor =
                UIColor.white.withAlphaComponent(0.02)
        }
        effectView.translatesAutoresizingMaskIntoConstraints = false
        container.insertSubview(effectView, at: 0)
        NSLayoutConstraint.activate([
            effectView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            effectView.topAnchor.constraint(equalTo: container.topAnchor),
            effectView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        glassView = effectView
    }

    /// A corner radius above half the height renders artifacts; track the
    /// squeezing bounds so the capsule stays a capsule all the way down.
    private func clampGlassCorners() {
        guard let glassView = glassView else { return }
        glassView.layer.cornerRadius =
            min(glassCornerRadius, max(container.bounds.height / 2, 0))
    }

    @objc private func focusField() {
        textField.becomeFirstResponder()
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
        case "setBrightness":
            if let args = call.arguments as? [String: Any],
                let isDark = (args["isDark"] as? NSNumber)?.boolValue
            {
                container.overrideUserInterfaceStyle = isDark ? .dark : .light
                result(nil)
            } else {
                result(FlutterError(code: "bad_args", message: "Missing isDark", details: nil))
            }
        case "setContentOpacity":
            // Scroll-driven fade of the field's *content* — text, placeholder
            // and prefix/suffix icons — while the capsule squeezes (Flutter's
            // Opacity can't fade platform-view pixels). The glass capsule
            // itself stays visible and shrinks away with the geometry, like
            // the system search bar.
            if let args = call.arguments as? [String: Any],
                let opacity = (args["opacity"] as? NSNumber)?.doubleValue
            {
                textField.alpha = CGFloat(max(0, min(1, opacity)))
                result(nil)
            } else {
                result(FlutterError(code: "bad_args", message: "Missing opacity", details: nil))
            }
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
