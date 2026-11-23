import Foundation

// SPM executable entry point.
// `swift run CleanMyMac --smoke-test` runs a headless self-check; otherwise launch the SwiftUI app.
if CommandLine.arguments.contains("--smoke-test") {
    SmokeTest.run()
    exit(0)
} else {
    CleanMyMacApp.main()
}
