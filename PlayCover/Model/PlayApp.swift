//
//  PlayApp.swift
//  PlayCover
//

import Cocoa
import Foundation
import IOKit.pwr_mgt

// swiftlint:disable file_length
class PlayApp: BaseApp {
    // MARK: - Static
    public static let bundleIDCacheURL = PlayTools.playCoverContainer.appendingPathComponent("CACHE")

    public static var bundleIDCache: [String] {
        get throws {
            (try String(contentsOf: bundleIDCacheURL))
                .split(whereSeparator: \.isNewline)
                .map { String($0) }
        }
    }

    // MARK: - Instance State
    var displaySleepAssertionID: IOPMAssertionID?
    public var isStarting = false
    var sessionDisableKeychain: Bool = false

    // MARK: - Init
    override init(appUrl: URL) {
        super.init(appUrl: appUrl)

        keymapping.reloadKeymapCache()

        removeAlias()
        createAlias()

        loadDiscordIPC()
    }

    // MARK: - Computed
    var searchText: String {
        info.displayName.lowercased()
            .appending(" ")
            .appending(info.bundleName)
            .lowercased()
    }

    var name: String {
        info.displayName.isEmpty ? info.bundleName : info.displayName
    }

    // MARK: - Paths / Singletons
    static let aliasDirectory = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Applications")
        .appendingPathComponent("PlayCover")

    lazy var aliasURL = PlayApp.aliasDirectory.appendingPathComponent(name).appendingPathExtension("app")
    lazy var playChainURL = KeyCover.playChainPath.appendingPathComponent(info.bundleIdentifier)

    lazy var settings = AppSettings(info)
    lazy var keymapping = Keymapping(info)
    lazy var container = AppContainer(bundleId: info.bundleIdentifier)

    // MARK: - Launch
    func launch() async {
        do {
            isStarting = true

            if prohibitedToPlay {
                await clearAllCache()
                throw PlayCoverError.appProhibited
            } else if maliciousProhibited {
                await clearAllCache()
                deleteApp()
                throw PlayCoverError.appMaliciousProhibited
            }

            AppsVM.shared.fetchApps()
            if await VersionCheck.shared.checkNewVersion(myApp: self) { return }

            settings.sync()

            if try !Entitlements.areEntitlementsValid(app: self) {
                sign()
            }

            if try !isInfoPlistSigned() {
                try Shell.signApp(executable)
            }

            // Wait for keychain unlock to finish before continuing
            await unlockKeyCover()

            // If the app does not have PlayTools, do not install PlugIns
            if hasPlayTools() {
                try PlayTools.installPluginInIPA(url)
            }

            if try !PlayTools.isInstalled() {
                Log.shared.error("PlayTools are not installed! Please move PlayCover.app into Applications!")
            } else if try !Macho.isMachoValidArch(executable) {
                Log.shared.error("The app threw an error during conversion.")
            } else {
                // Clear any debug-related env vars that could affect the launched app
                self.clearDebugAffectingEnvironment()

                if settings.openWithLLDB {
                    try Shell.lldb(executable, withTerminalWindow: settings.openLLDBWithTerminal)
                } else {
                    runAppExec() // Splitting to reduce complexity
                }
            }
            isStarting = false
        } catch {
            Log.shared.error(error)
        }
    }
}

// MARK: - Environment Management
extension PlayApp {
    static let introspection: String = "/usr/lib/system/introspection"
    static let iosFrameworks: String = "/System/iOSSupport/System/Library/Frameworks"

    /// Common Metal and capture related environment keys used in multiple places
    private static let metalEnvKeys: [String] = [
        "METAL_DEVICE_WRAPPER_TYPE",
        "METAL_DEBUG_LAYER",
        "MTL_DEBUG_LAYER",
        "METAL_API_VALIDATION",
        "METAL_SHADER_VALIDATION",
        "METAL_SHADER_VALIDATION_OPTIONS",
        "METAL_CAPTURE_ENABLED",
        "METAL_CAPTURE_OUTPUT_FILE",
        "METAL_CAPTURE_TYPE",
        "METAL_FORCE_LAZY_COMPILATION",
        "METAL_FRAME_CAPTURE_ENABLED",
        "METAL_ERROR_MODE",
        "MTLCaptureEnabled"
    ]

    // clear environment variables that can force debug wrappers or validation layers
    func clearDebugAffectingEnvironment() {
        // Clear DYLD_* variables inherited from Xcode or other debuggers
        for (key, _) in ProcessInfo.processInfo.environment where key.hasPrefix("DYLD_") {
            unsetenv(key)
        }

        // Clear common Metal debug and capture related variables
        for key in PlayApp.metalEnvKeys {
            unsetenv(key)
        }
    }

    func runAppExec() {
        let config = NSWorkspace.OpenConfiguration()

        // Prevent propagating debugging-related variables to child process
        for (key, _) in ProcessInfo.processInfo.environment where key.hasPrefix("DYLD_") {
            unsetenv(key)
        }
        for key in PlayApp.metalEnvKeys {
            unsetenv(key)
        }

        NSWorkspace.shared.openApplication(
            at: aliasURL,
            configuration: config,
            completionHandler: { runningApp, error in
                guard error == nil else { return }
                // Run a thread loop in the background to handle background tasks
                Task(priority: .background) {
                    if let runningApp = runningApp {
                        while !(runningApp.isTerminated) {
                            if runningApp.isActive {
                                self.disableTimeOut()
                            } else {
                                self.enableTimeOut()
                            }
                            sleep(1)
                        }
                        sleep(1)
                    }
                    // Things that are run after the app is closed
                    self.lockKeyCover()
                }
            }
        )
    }
}

// MARK: - Management
extension PlayApp {
    func disableTimeOut() {
        if displaySleepAssertionID != nil { return }

        let reason = "PlayCover: \(info.bundleIdentifier) is disabling sleep" as CFString
        var assertionID: IOPMAssertionID = 0
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )
        if result == kIOReturnSuccess {
            displaySleepAssertionID = assertionID
        }
    }

    func enableTimeOut() {
        if let assertionID = displaySleepAssertionID {
            IOPMAssertionRelease(assertionID)
            displaySleepAssertionID = nil
        }
    }
}

// MARK: - KeyCover
extension PlayApp {
    func unlockKeyCover() async {
        if KeyCover.shared.isKeyCoverEnabled() {
            let keychain = KeyCover.shared.listKeychains()
                .first(where: { $0.appBundleID == self.info.bundleIdentifier })

            if let keychain = keychain, keychain.chainEncryptionStatus {
                try? await KeyCover.shared.unlockChain(keychain)

                if KeyCover.shared.keyCoverPlainTextKey == nil {
                    // Pop an alert telling the user that keychain was not unlocked
                    // and keychain is disabled for the session
                    Task { @MainActor in
                        let alert = NSAlert()
                        alert.messageText = NSLocalizedString("keycover.alert.title", comment: "")
                        alert.informativeText = NSLocalizedString("keycover.alert.content", comment: "")
                        alert.alertStyle = .warning
                        alert.addButton(withTitle: NSLocalizedString("button.OK", comment: ""))
                        alert.runModal()
                    }
                    settings.settings.playChain = false
                    sessionDisableKeychain = true
                }
            }
        }
    }

    func lockKeyCover() {
        if KeyCover.shared.isKeyCoverEnabled() {
            if sessionDisableKeychain {
                settings.settings.playChain = true
                sessionDisableKeychain = false
                return
            }

            let keychain = KeyCover.shared.listKeychains()
                .first(where: { $0.appBundleID == self.info.bundleIdentifier })

            if let keychain = keychain, !keychain.chainEncryptionStatus {
                try? KeyCover.shared.lockChain(keychain)
            }
        }
    }
}

// MARK: - Tools
extension PlayApp {
    func hasPlayTools() -> Bool {
        do {
            return try PlayTools.installedInExec(atURL: url.appendingEscapedPathComponent(info.executableName))
        } catch {
            Log.shared.error(error)
            return true
        }
    }

    func changeDyldLibraryPath(set: Bool? = nil, path: String) async -> Bool {
        info.lsEnvironment["DYLD_LIBRARY_PATH"] = info.lsEnvironment["DYLD_LIBRARY_PATH"] ?? ""

        if let set = set {
            if set {
                info.lsEnvironment["DYLD_LIBRARY_PATH"]? += "\(path):"
            } else {
                info.lsEnvironment["DYLD_LIBRARY_PATH"] = info.lsEnvironment["DYLD_LIBRARY_PATH"]?
                    .replacingOccurrences(of: "\(path):", with: "")
            }

            do {
                try Shell.signApp(executable)
            } catch {
                Log.shared.error(error)
            }
        }

        guard let result = info.lsEnvironment["DYLD_LIBRARY_PATH"] else {
            return false
        }
        return result.contains(path)
    }
}

// MARK: - FS / Codesign
extension PlayApp {
    func hasAlias() -> Bool {
        FileManager.default.fileExists(atPath: aliasURL.path)
    }

    func isInfoPlistSigned() throws -> Bool {
        try Shell.run("/usr/bin/codesign", "-dv", executable.path).contains("Info.plist entries")
    }

    func showInFinder() {
        URL(fileURLWithPath: url.path).showInFinderAndSelectLastComponent()
    }

    func openAppCache() {
        container.containerUrl.showInFinderAndSelectLastComponent()
    }

    func clearAllCache() async {
        Uninstaller.clearExternalCache(info.bundleIdentifier)
    }

    func clearPlayChain() {
        FileManager.default.delete(at: playChainURL)
        FileManager.default.delete(at: playChainURL.appendingPathExtension("keyCover"))
        FileManager.default.delete(at: playChainURL.appendingPathExtension("db"))
    }

    func deleteApp() {
        FileManager.default.delete(at: URL(fileURLWithPath: url.path))
        AppsVM.shared.fetchApps()
    }

    func setup() {
        if settings.extraSettings.unrealEngineFixFilePath {
            applyUnrealEngineFilePathPatch()
        }
        if settings.extraSettings.fixAvailableMemoryValue {
            applyAvailableMemoryPatch()
        }
        if settings.extraSettings.neoxEngineFixFilePath {
            applyNeoXEngineFilePathPatch()
        }
        if settings.extraSettings.disableCriWareSonicSync {
            applyCriWareSonicSyncPatch()
        }
        if settings.extraSettings.unrealEngineBypassEntitlementsCheck {
            copyEntitlementsAsEmbeddedMobileprovision()
        }
        if settings.extraSettings.preventGoogleMeasurmentWriteFiles {
            setGoogleMeasurementDirectoryReadOnly(true)
        }
        if settings.extraSettings.jinChanChanFixMicrophone {
            applyJinChanChanMicrophonePatch()
        }
        if settings.extraSettings.nanaoriFixBuiltinMouseIssue {
            applyNanaoriBuiltinMousePatch()
        }
    }

    func sign() {
        do {
            let tmpDir = FileManager.default.temporaryDirectory
            let tmpEnts = tmpDir
                .appendingEscapedPathComponent(ProcessInfo().globallyUniqueString)
                .appendingPathExtension("plist")
            let conf = try Entitlements.composeEntitlements(self)
            try conf.store(tmpEnts)
            try Shell.signAppWith(executable, entitlements: tmpEnts)
            try FileManager.default.removeItem(at: tmpEnts)
        } catch {
            print(error)
            Log.shared.error(error)
        }
    }

    func copyEntitlementsAsEmbeddedMobileprovision() {
        do {
            if !FileManager.default.fileExists(atPath: entitlements.path) {
                return
            }
            if FileManager.default.fileExists(atPath: embeddedMobileprovision.path) {
                try FileManager.default.removeItem(at: embeddedMobileprovision)
            }
            try FileManager.default.copyItem(at: entitlements, to: embeddedMobileprovision)
        } catch {
            print(error)
            Log.shared.error(error)
        }
    }

    func deleteEmbeddedMobileprovision() {
        do {
            if FileManager.default.fileExists(atPath: embeddedMobileprovision.path) {
                try FileManager.default.removeItem(at: embeddedMobileprovision)
            }
        } catch {
            print(error)
            Log.shared.error(error)
        }
    }
}

// MARK: - Policies
extension PlayApp {
    var prohibitedToPlay: Bool {
        PlayApp.PROHIBITED_APPS.contains(info.bundleIdentifier)
    }

    var maliciousProhibited: Bool {
        PlayApp.MALICIOUS_APPS.contains(info.bundleIdentifier)
    }

    static let PROHIBITED_APPS = [
        "com.activision.callofduty.shooter",
        "com.ea.ios.apexlegendsmobilefps",
        "com.tencent.tmgp.cod",
        "com.tencent.ig",
        "com.pubg.newstate",
        "com.pubg.imobile",
        "com.tencent.tmgp.pubgmhd",
        "com.dts.freefireth",
        "com.dts.freefiremax",
        "vn.vng.codmvn",
        "com.ngame.allstar.eu",
        "com.axlebolt.standoff2",
        "com.tencent.lolm"
    ]

    static let MALICIOUS_APPS = [
        "com.zhiliaoapp.musically"
    ]
}

// MARK: - Extras
extension PlayApp {
    func setGoogleMeasurementDirectoryReadOnly(_ readOnly: Bool) {
        do {
            let fileManager = FileManager.default
            let measurementURL = fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent("Library")
                .appendingPathComponent("Containers")
                .appendingPathComponent(info.bundleIdentifier)
                .appendingPathComponent("Data")
                .appendingPathComponent("Library")
                .appendingPathComponent("Application Support")
                .appendingPathComponent("Google")
                .appendingPathComponent("Measurement")

            // Create directory if it does not exist
            if !fileManager.fileExists(atPath: measurementURL.path) {
                try fileManager.createDirectory(
                    at: measurementURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }

            // Clear all files if we want to make it read only
            if readOnly {
                let contents = try fileManager.contentsOfDirectory(
                    at: measurementURL,
                    includingPropertiesForKeys: nil,
                    options: []
                )
                for fileURL in contents {
                    try fileManager.removeItem(at: fileURL)
                }
            }

            // Modify directory permisision
            try fileManager.setAttributes(
                [.posixPermissions: readOnly ? 0o555 : 0o755],
                ofItemAtPath: measurementURL.path
            )
        } catch {
            print(error)
        }
    }

    func applyUnrealEngineFilePathPatch() {
        // Replace '/var/' with '/User'
        let success = Macho.patch(
            url: executable,
            bytesToFind: Data([0x2F, 0x00, 0x76, 0x00, 0x61, 0x00, 0x72, 0x00, 0x2F, 0x00, 0x00, 0x00]),
            bytesToWrite: Data([0x2F, 0x00, 0x55, 0x00, 0x73, 0x00, 0x65, 0x00, 0x72, 0x00, 0x00, 0x00])
        )
        print("Applying Unreal Engine file path patch... success: \(success)")
    }

    func applyAvailableMemoryPatch() {
        do {
            // Find the address of os_proc_available_memory() function
            let command = """
            otool -Iv "\(executable.path)" | grep _os_proc_available_memory | head -n1 | awk '{print $1}'
            """

            let output = try Shell.run("/bin/sh", "-c", command)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard let addr = UInt64(output.dropFirst(2), radix: 16) else {
                return
            }

            // Modify the os_proc_available_memory() function to constantly return 4 gigabytes
            let success = Macho.patch(
                url: executable,
                offset: addr - 0x100000000,
                data: Data([0x20, 0x00, 0xC0, 0xD2, 0xC0, 0x03, 0x5F, 0xD6])
            )
            print("Applying available memory patch... success: \(success)")
        } catch {
            print(error)
        }
    }

    func applyNeoXEngineFilePathPatch() {
        // Replace '/private' with '/'
        let success = Macho.patch(
            url: executable,
            bytesToFind: Data([0x00, 0x2F, 0x70, 0x72, 0x69, 0x76, 0x61, 0x74, 0x65, 0x00]),
            bytesToWrite: Data([0x00, 0x2F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        )
        print("Applying NeoX Engine file path patch (1)... success: \(success)")

        // Search instruction 'MOV X20, #0x657461766972702F',
        // then change the length of std::string to zero.
        let success2 = Macho.patch(
            url: executable,
            bytesToFind: Data([0xF4, 0x05, 0x8E, 0xD2, 0x54, 0x2E, 0xAD, 0xF2,
                               0xD4, 0x2E, 0xCC, 0xF2, 0x94, 0xAE, 0xEC, 0xF2]),
            bytesToWrite: Data([0x08, 0x00, 0x80, 0xD2]),
            writeOffset: 48
        )
        // This patch is only required for newer versions of NeoX Engine,
        // so it doesn't matter if this patch was not successfully applied.
        print("Applying NeoX Engine file path patch (2)... success: \(success2)")
    }

    func applyCriWareSonicSyncPatch() {
        var target = executable
        var sign = false

        let unityFramework = url.appendingPathComponent("Frameworks")
            .appendingPathComponent("UnityFramework.framework")
            .appendingPathComponent("UnityFramework")
        if FileManager.default.fileExists(atPath: unityFramework.path) {
            target = unityFramework
            sign = true
        }

        // Change CriAtomExConfig->thread_model to zero
        let success = Macho.patch(
            url: target,
            bytesToFind: Data([0x00, 0x00, 0xC0, 0x3D, 0x60, 0x02, 0x80, 0x3D,
                               0x00, 0x84, 0x40, 0xAD, 0x02, 0x8C, 0x41, 0xAD,
                               0x62, 0x8E, 0x01, 0xAD, 0x60, 0x86, 0x00, 0xAD,
                               0x00, 0x84, 0x42, 0xAD, 0x02, 0x1C, 0xC0, 0x3D]),
            bytesToWrite: Data([0x1F, 0x00, 0x00, 0xB9]),
            writeOffset: -4
        )
        if success && sign {
            do {
                try Shell.signMacho(target)
            } catch {
                print(error)
            }
        }
        print("Applying CRIWARE SonicSYNC patch... target: \(target) success: \(success)")
    }

    func applyJinChanChanMicrophonePatch() {
        // Force UnityEngine.Application.HasUserAuthorization(Microphone) to return true
        let success = Macho.patch(
            url: executable,
            bytesToFind: Data([0x7F, 0x0A, 0x00, 0x71, 0x93, 0x02, 0x88, 0x1A, 0xE0, 0x03, 0x13, 0xAA]),
            bytesToWrite: Data([0x20, 0x00, 0x80, 0xD2]),
            writeOffset: 8
        )
        print("Applying JinChanChan microphone patch... success: \(success)")
    }

    func applyNanaoriBuiltinMousePatch() {
        // Prevent the game from switching input mode to UIOnly
        let success = Macho.patch(
            url: executable,
            bytesToFind: Data([0xA8, 0x08, 0x85, 0x52, 0x29, 0x00, 0x80, 0x52, 0x69, 0x6A, 0x28, 0x38]),
            bytesToWrite: Data([0x14, 0x00, 0x80, 0xD2]),
            writeOffset: -0x100
        )
        print("Applying Nanaori built-in mouse patch... success: \(success)")
    }
}
