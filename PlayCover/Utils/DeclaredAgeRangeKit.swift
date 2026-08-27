//
//  DeclaredAgeRangeKit.swift
//  PlayCover
//

class DeclaredAgeRangeKit {
    private static let frameworksURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library")
        .appendingPathComponent("Frameworks")
    static let declaredAgeRangeFramework = frameworksURL
        .appendingPathComponent("DeclaredAgeRange")
        .appendingPathExtension("framework")
    static let declaredAgeRangeExecutable = declaredAgeRangeFramework
        .appendingPathComponent("DeclaredAgeRange")
    private static let bundledDeclaredAgeRangeFramework = Bundle.main.bundleURL
        .appendingPathComponent("Contents")
        .appendingPathComponent("Frameworks")
        .appendingPathComponent("DeclaredAgeRange")
        .appendingPathExtension("framework")

    static func installOnSystem() {
        Task(priority: .background) {
            do {
                Log.shared.log("Installing DeclaredAgeRange")

                // Check if Frameworks folder exists, if not, create it
                if !FileManager.default.fileExists(atPath: frameworksURL.path) {
                    try FileManager.default.createDirectory(
                        atPath: frameworksURL.path,
                        withIntermediateDirectories: true,
                        attributes: [:])
                }

                // Check if a version of DeclaredAgeRange is already installed, if so remove it
                if FileManager.default.fileExists(atPath: declaredAgeRangeFramework.path) {
                    try FileManager.default.removeItem(at: declaredAgeRangeFramework)
                }

                // Install version of DeclaredAgeRange bundled with PlayCover
                Log.shared.log("Copying DeclaredAgeRange to Frameworks")
                try FileManager.default.copyItem(at: bundledDeclaredAgeRangeFramework, to: declaredAgeRangeFramework)
            } catch {
                Log.shared.error(error)
            }
        }
    }
}
