import AppKit

/// Entry point. `--generate-icon <path>` renders the app icon to a PNG (used by the build script).
@main
enum FrontlineApp {
    @MainActor
    static func main() {
        let arguments = CommandLine.arguments
        if let index = arguments.firstIndex(of: "--generate-icon"), index + 1 < arguments.count {
            let ok = IconGenerator.writePNG(to: arguments[index + 1], size: 1024)
            exit(ok ? 0 : 1)
        }
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        withExtendedLifetime(delegate) {
            app.run()
        }
    }
}
