import AppKit
import Foundation

let helpText = """
ad — AirDrop files and URLs to nearby Apple devices

usage:
  ad <file|url> [file|url ...]
  ad --help, -h
  ad --version, -V

multiple items are sent in a single AirDrop session.
"""

let version = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "unknown"

let args = Array(CommandLine.arguments.dropFirst())

for arg in args {
    switch arg {
    case "--help", "-h":
        print(helpText)
        exit(0)
    case "--version", "-V":
        print("ad \(version)")
        exit(0)
    default:
        if arg.hasPrefix("-") {
            FileHandle.standardError.write(Data("error: unknown flag: \(arg)\n\n\(helpText)\n".utf8))
            exit(2)
        }
    }
}

guard !args.isEmpty else {
    FileHandle.standardError.write(Data("\(helpText)\n".utf8))
    exit(2)
}

func resolve(_ arg: String) -> Any? {
    if let url = URL(string: arg), let scheme = url.scheme,
       scheme == "http" || scheme == "https" {
        return url
    }
    let expanded = NSString(string: arg).expandingTildeInPath
    let path = (expanded as NSString).standardizingPath
    guard FileManager.default.fileExists(atPath: path) else {
        FileHandle.standardError.write(Data("error: not found: \(path)\n".utf8))
        return nil
    }
    return URL(fileURLWithPath: path)
}

let items = args.compactMap(resolve)
guard items.count == args.count else { exit(1) }

guard let service = NSSharingService(named: .sendViaAirDrop) else {
    FileHandle.standardError.write(Data("error: AirDrop service unavailable\n".utf8))
    exit(1)
}

guard service.canPerform(withItems: items) else {
    FileHandle.standardError.write(Data("error: cannot share these items via AirDrop\n".utf8))
    exit(1)
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSSharingServiceDelegate {
    let items: [Any]
    let service: NSSharingService
    var exitCode: Int32 = 0

    init(items: [Any], service: NSSharingService) {
        self.items = items
        self.service = service
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
        service.delegate = self
        DispatchQueue.main.async { [self] in
            service.perform(withItems: items)
        }
    }

    func sharingService(_ s: NSSharingService, didShareItems shared: [Any]) {
        let n = shared.count
        print("sent \(n) item\(n == 1 ? "" : "s")")
        NSApp.terminate(nil)
    }

    func sharingService(_ s: NSSharingService,
                        didFailToShareItems shared: [Any],
                        error: Error) {
        let nsError = error as NSError
        if nsError.domain == NSCocoaErrorDomain && nsError.code == NSUserCancelledError {
            print("cancelled")
        } else {
            FileHandle.standardError.write(Data("error: \(error.localizedDescription)\n".utf8))
            exitCode = 1
        }
        NSApp.terminate(nil)
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        return .terminateNow
    }

    func applicationWillTerminate(_ notification: Notification) {
        exit(exitCode)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate(items: items, service: service)
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
