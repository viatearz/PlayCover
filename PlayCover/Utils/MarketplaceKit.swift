//
//  MarketplaceKit.swift
//  PlayCover
//

class MarketplaceKit {
    private static let frameworksURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library")
        .appendingPathComponent("Frameworks")
    static let marketplaceKitFramework = frameworksURL
        .appendingPathComponent("MarketplaceKit")
        .appendingPathExtension("framework")
    static let marketplaceKitExecutable = marketplaceKitFramework
        .appendingPathComponent("MarketplaceKit")
    private static let bundledMarketplaceKitFramework = Bundle.main.bundleURL
        .appendingPathComponent("Contents")
        .appendingPathComponent("Frameworks")
        .appendingPathComponent("MarketplaceKit")
        .appendingPathExtension("framework")

    static func installOnSystem() {
        Task(priority: .background) {
            do {
                Log.shared.log("Installing MarketplaceKit")

                // Check if Frameworks folder exists, if not, create it
                if !FileManager.default.fileExists(atPath: frameworksURL.path) {
                    try FileManager.default.createDirectory(
                        atPath: frameworksURL.path,
                        withIntermediateDirectories: true,
                        attributes: [:])
                }

                // Check if a version of MarketplaceKit is already installed, if so remove it
                if FileManager.default.fileExists(atPath: marketplaceKitFramework.path) {
                    try FileManager.default.removeItem(at: marketplaceKitFramework)
                }

                // Install version of MarketplaceKit bundled with PlayCover
                Log.shared.log("Copying MarketplaceKit to Frameworks")
                try FileManager.default.copyItem(at: bundledMarketplaceKitFramework, to: marketplaceKitFramework)
            } catch {
                Log.shared.error(error)
            }
        }
    }
}
