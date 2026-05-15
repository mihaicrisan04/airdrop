import AppKit
import Foundation

let helpText = """
ad — AirDrop files, URLs and text to nearby Apple devices

usage:
  ad <file|url> [file|url ...]
  ad - (reads stdin into a temp file and sends it)
  ad --text "snippet" [--text "..." ...]
  ad --help, -h
  ad --version, -V

flags:
  -q, --quiet     suppress success output
  --text <s>      send literal text content (can repeat)
  -               read stdin into a temp file and send it

multiple items are sent in a single AirDrop session.
"""

let version = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "unknown"

func die(_ message: String, code: Int32 = 1) -> Never {
    FileHandle.standardError.write(Data("\(message)\n".utf8))
    exit(code)
}

var items: [Any] = []
var quiet = false

let rawArgs = Array(CommandLine.arguments.dropFirst())
var i = 0
while i < rawArgs.count {
    let arg = rawArgs[i]
    switch arg {
    case "--help", "-h":
        print(helpText)
        exit(0)
    case "--version", "-V":
        print("ad \(version)")
        exit(0)
    case "--quiet", "-q":
        quiet = true
    case "--text":
        guard i + 1 < rawArgs.count else {
            die("error: --text requires a value", code: 2)
        }
        items.append(rawArgs[i + 1])
        i += 1
    case "-":
        let data = FileHandle.standardInput.readDataToEndOfFile()
        guard !data.isEmpty else {
            die("error: stdin is empty", code: 1)
        }
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("stdin-\(Int(Date().timeIntervalSince1970)).txt")
        do {
            try data.write(to: tmp)
        } catch {
            die("error: writing stdin to temp file: \(error.localizedDescription)")
        }
        items.append(tmp)
    default:
        if arg.hasPrefix("-") {
            die("error: unknown flag: \(arg)\n\n\(helpText)", code: 2)
        }
        if let url = URL(string: arg), let scheme = url.scheme,
           scheme == "http" || scheme == "https" {
            items.append(url)
        } else {
            let path = (NSString(string: arg).expandingTildeInPath as NSString).standardizingPath
            guard FileManager.default.fileExists(atPath: path) else {
                die("error: not found: \(path)")
            }
            items.append(URL(fileURLWithPath: path))
        }
    }
    i += 1
}

guard !items.isEmpty else {
    FileHandle.standardError.write(Data("\(helpText)\n".utf8))
    exit(2)
}

guard let service = NSSharingService(named: .sendViaAirDrop) else {
    die("error: AirDrop service unavailable")
}

guard service.canPerform(withItems: items) else {
    die("error: cannot share these items via AirDrop")
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSSharingServiceDelegate {
    let items: [Any]
    let service: NSSharingService
    let quiet: Bool
    var exitCode: Int32 = 0

    init(items: [Any], service: NSSharingService, quiet: Bool) {
        self.items = items
        self.service = service
        self.quiet = quiet
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
        if !quiet {
            let n = shared.count
            print("sent \(n) item\(n == 1 ? "" : "s")")
        }
        NSApp.terminate(nil)
    }

    func sharingService(_ s: NSSharingService,
                        didFailToShareItems shared: [Any],
                        error: Error) {
        let nsError = error as NSError
        if nsError.domain == NSCocoaErrorDomain && nsError.code == NSUserCancelledError {
            if !quiet { print("cancelled") }
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
let delegate = AppDelegate(items: items, service: service, quiet: quiet)
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
