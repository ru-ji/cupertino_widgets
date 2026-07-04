import Flutter
import SwiftUI
import UIKit

/// Embeds an auto-resizable FlutterEngine view controller inside SwiftUI.
///
/// Contract (per the engine's auto-resize implementation): the DART side
/// drives the size — the engine lays the root widget out with unbounded
/// constraints, the top-level widget must have explicit dimensions (the
/// scaffold wraps bodies in a screen-wide SizedBox), and the FlutterView
/// sizes itself via its own internal Auto Layout constraints. The host must
/// NOT constrain the view externally; it only observes the resulting
/// intrinsic size and mirrors it into SwiftUI so the native ScrollView gets
/// the full content height.
@available(iOS 16.0, *)
struct FlutterContentView: View {
    let engine: FlutterEngine

    @State private var contentSize: CGSize?

    var body: some View {
        _FlutterContentRepresentable(engine: engine) { size in
            // Reported from UIKit layout passes; hop out before mutating state.
            DispatchQueue.main.async {
                if contentSize != size {
                    contentSize = size
                }
            }
        }
        // Placeholder height until Flutter's first layout reports in.
        .frame(height: contentSize?.height ?? UIScreen.main.bounds.height)
    }
}

@available(iOS 16.0, *)
private struct _FlutterContentRepresentable: UIViewControllerRepresentable {
    let engine: FlutterEngine
    let onSizeChange: (CGSize) -> Void

    func makeUIViewController(context: Context) -> FlutterHostViewController {
        let controller = FlutterHostViewController(engine: engine)
        controller.onSizeChange = onSizeChange
        return controller
    }

    func updateUIViewController(_ uiViewController: FlutterHostViewController, context: Context) {
        uiViewController.onSizeChange = onSizeChange
    }
}

/// Hosts the FlutterViewController WITHOUT any external constraints — the
/// auto-resizable FlutterView installs its own (FlutterAutoResizeLayoutConstraint)
/// and publishes the Dart-chosen size through intrinsicContentSize/bounds.
final class FlutterHostViewController: UIViewController {
    private let flutterController: FlutterViewController
    private var lastReportedSize: CGSize = .zero
    private var boundsObservation: NSKeyValueObservation?

    var onSizeChange: ((CGSize) -> Void)?

    init(engine: FlutterEngine) {
        flutterController = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
        flutterController.isViewOpaque = false
        flutterController.isAutoResizable = true
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        addChild(flutterController)
        view.addSubview(flutterController.view)
        flutterController.didMove(toParent: self)

        // The engine resizes the FlutterView through its own constraints;
        // host layout passes don't reliably re-run when that happens, so
        // observe the view's bounds directly.
        boundsObservation = flutterController.view.observe(\.bounds, options: [.new]) {
            [weak self] observedView, _ in
            self?.reportIfChanged(observedView.bounds.size)
        }
    }

    deinit {
        boundsObservation?.invalidate()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        reportIfChanged(flutterController.view.intrinsicContentSize)
        // Dart layout can settle after this pass (fonts, images, async
        // builds); re-check once shortly after.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            self.reportIfChanged(self.flutterController.view.intrinsicContentSize)
        }
    }

    private func reportIfChanged(_ size: CGSize) {
        guard size.width > 1, size.height > 1, size != lastReportedSize else { return }
        lastReportedSize = size
        onSizeChange?(size)
    }
}
