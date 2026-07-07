import Foundation

/// Creation/update parameters for the native scaffold platform view.
/// When `entryPoint` is nil, body engines boot the app's default `main()`
/// with a `cn-scaffold://<route>` initial route intercepted by
/// `CupertinoNativeScaffold.maybeRun` on the Dart side; otherwise it names a
/// `@pragma('vm:entry-point')` function used with the raw route.
struct ScaffoldConfig: Codable {
    let entryPoint: String?
    let body: String?  // root body route, used when tabBar == nil
    let appBar: AppBarConfig?
    let tabBar: TabBarConfig?
    let scrollEdgeEffect: String?  // "automatic" | "soft" | "hard" (iOS 26)
    let isDark: Bool?
    let backgroundColor: Int?  // ARGB — defaults to scaffoldBackgroundColor from Flutter theme
    let primaryColor: Int?     // ARGB — defaults to colorScheme.primary from Flutter theme
}
