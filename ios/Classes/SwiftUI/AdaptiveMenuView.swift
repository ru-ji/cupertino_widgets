import SwiftUI

struct AdaptiveMenuView: View {
    let config: MenuConfiguration
    let onAction: (String, Any?) -> Void

    // Fallback state for iOS 13
    @State private var showActionSheet = false

    var body: some View {
        if #available(iOS 14.0, *) {
            let menu = Menu {
                ForEach(config.items) { item in
                    MenuItemMapper(item: item, onAction: onAction)
                }
            } label: {
                if let sysImg = config.systemImage {
                    applyCustomTextColor(
                        to: Label(config.title, systemImage: sysImg).font(customFont))
                } else {
                    applyCustomTextColor(to: Text(config.title).font(customFont))
                }
            }

            if #available(iOS 15.0, *) {
                applyMenuButtonStyle(menu)
            } else {
                menu
            }
        } else {
            // iOS 13 Fallback: Simple Button that triggers an ActionSheet
            // Note: ActionSheet does not support nested menus or customized views,
            // so we flatten the structure or just show top-level actions.
            Button(action: {
                showActionSheet = true
            }) {
                HStack {
                    if let sysImg = config.systemImage {
                        Image(systemName: sysImg)
                    } else {
                        Image(systemName: "ellipsis.circle")
                    }
                    Text(config.title)
                }
                .font(customFont)
                .foregroundColor(customTextColor ?? (tintColor ?? .blue))
            }
            .actionSheet(isPresented: $showActionSheet) {
                ActionSheet(
                    title: Text(config.title),
                    buttons: config.items.compactMap { item in
                        // Only map simple actions for the fallback
                        if item.type == .action {
                            if item.isDestructive == true {
                                return .destructive(
                                    Text(item.title ?? ""),
                                    action: {
                                        if let id = item.actionId { onAction(id, nil) }
                                    })
                            } else {
                                return .default(
                                    Text(item.title ?? ""),
                                    action: {
                                        if let id = item.actionId { onAction(id, nil) }
                                    })
                            }
                        }
                        return nil
                    } + [.cancel()]
                )
            }
        }
    }

    @available(iOS 15.0, *)
    @ViewBuilder
    func applyMenuButtonStyle(_ menu: some View) -> some View {
        switch config.style {
        case "filled":
            menu.buttonStyle(.borderedProminent).tint(tintColor)
        case "tinted":
            menu.buttonStyle(.bordered).tint(tintColor)
        case "plain":
            menu.buttonStyle(.borderless).tint(tintColor)
        case "glass":
            if #available(iOS 26.0, *) {
                menu.buttonStyle(.glass).tint(tintColor)
            } else {
                menu
                    .buttonStyle(.automatic).tint(tintColor)
            }

        case "glassProminent":
            if #available(iOS 26.0, *) {
                menu.buttonStyle(.glassProminent).tint(tintColor)
            } else {
                menu
                    .buttonStyle(.automatic).tint(tintColor)
            }
        default:
            menu.buttonStyle(.automatic).tint(tintColor)
        }
    }

    // MARK: - Style Helpers

    var tintColor: Color? {
        guard let val = config.color else { return nil }
        let a = Double((val >> 24) & 0xFF) / 255.0
        let r = Double((val >> 16) & 0xFF) / 255.0
        let g = Double((val >> 8) & 0xFF) / 255.0
        let b = Double(val & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b, opacity: a)
    }

    var customFont: Font? {
        if let size = config.fontSize {
            if let weightIndex = config.fontWeight {
                return .system(size: size).weight(weightIndexToFontWeight(weightIndex))
            }
            return .system(size: size)
        }
        if let weightIndex = config.fontWeight {
            return .body.weight(weightIndexToFontWeight(weightIndex))
        }
        return nil
    }

    func weightIndexToFontWeight(_ index: Int) -> Font.Weight {
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

    var customTextColor: Color? {
        guard let val = config.textColor else { return nil }
        let a = Double((val >> 24) & 0xFF) / 255.0
        let r = Double((val >> 16) & 0xFF) / 255.0
        let g = Double((val >> 8) & 0xFF) / 255.0
        let b = Double(val & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b, opacity: a)
    }

    @ViewBuilder
    func applyCustomTextColor(to view: some View) -> some View {
        if let color = customTextColor {
            if #available(iOS 15.0, *) {
                view.foregroundStyle(color)
            } else {
                view.foregroundColor(color)
            }
        } else {
            view
        }
    }
}

struct MenuItemMapper: View {
    let item: MenuItemConfig
    let onAction: (String, Any?) -> Void

    var body: some View {
        if #available(iOS 14.0, *) {
            switch item.type {
            case .action:
                // iOS 15+ supports role: .destructive
                if #available(iOS 15.0, *), item.isDestructive == true {
                    Button(role: .destructive) {
                        triggerAction()
                    } label: {
                        menuLabel
                    }
                    .disabled(item.isDisabled == true)
                } else {
                    // iOS 14
                    Button(action: {
                        triggerAction()
                    }) {
                        menuLabel
                    }
                    .disabled(item.isDisabled == true)
                    // Note: iOS 14 Menu buttons don't support destructive red text automatically
                    // without role, unless we custom style, but standard Menu styling is limited.
                }

            case .submenu:
                Menu {
                    if let children = item.items {
                        ForEach(children) { child in
                            MenuItemMapper(item: child, onAction: onAction)
                        }
                    }
                } label: {
                    menuLabel
                }

            case .section:
                // Section in Menu is available in iOS 14? Yes, standard Section container.
                Section(header: Text(item.title ?? "")) {
                    if let children = item.items {
                        ForEach(children) { child in
                            MenuItemMapper(item: child, onAction: onAction)
                        }
                    }
                }

            case .toggle:
                Toggle(
                    isOn: Binding(
                        get: { item.value ?? false },
                        set: { newValue in
                            if let id = item.actionId {
                                onAction(id, newValue)
                            }
                        }
                    )
                ) {
                    menuLabel
                }
            }
        } else {
            EmptyView()
        }
    }

    @available(iOS 14.0, *)
    var menuLabel: some View {
        Group {
            if let sysImg = item.systemImage {
                Label(item.title ?? "", systemImage: sysImg)
            } else {
                Text(item.title ?? "")
            }
        }
    }

    func triggerAction() {
        if let id = item.actionId {
            onAction(id, nil)
        }
    }
}
