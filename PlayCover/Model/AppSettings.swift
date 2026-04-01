//
//  AppSettings.swift
//  PlayCover
//

// swiftlint:disable file_length

import AppKit
import Foundation
import UniformTypeIdentifiers

struct AppSettingsData: Codable {
    var bundleIdentifier: String = ""

    var keymapping = true
    var sensitivity: Float = 50

    var disableTimeout = false
    var iosDeviceModel = "iPad13,8"
    var windowWidth = 1920
    var windowHeight = 1080
    var customScaler = 2.0
    var resolution = 1
    var aspectRatio = 1
    var notch: Bool = NSScreen.hasNotch()
    var bypass = false
    var discordActivity = DiscordActivity()
    var version = "3.0.0"
    var playChain = true
    var playChainDebugging = false
    var inverseScreenValues = false
    var metalHUD = false {
        didSet {
            do {
                try Shell.setMetalHUD(bundleIdentifier, enabled: metalHUD)
            } catch {
                Log.shared.error(error)
            }
        }
    }
    var windowFixMethod = 0
    var injectIntrospection = false
    var rootWorkDir = true
    var noKMOnInput = true
    var enableScrollWheel = true
    var hideTitleBar = false
    var floatingWindow = false
    var checkMicPermissionSync = false
    var limitMotionUpdateFrequency = false
    var disableBuiltinMouse = false
    var resizableAspectRatioType = 0
    var resizableAspectRatioWidth = 0
    var resizableAspectRatioHeight = 0
    var blockSleepSpamming = false

    init() {}

    // handle old 2.x settings where PlayChain did not exist yet
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bundleIdentifier = try container.decodeIfPresent(String.self, forKey: .bundleIdentifier) ?? ""
        keymapping = try container.decodeIfPresent(Bool.self, forKey: .keymapping) ?? true
        sensitivity = try container.decodeIfPresent(Float.self, forKey: .sensitivity) ?? 50
        disableTimeout = try container.decodeIfPresent(Bool.self, forKey: .disableTimeout) ?? false
        iosDeviceModel = try container.decodeIfPresent(String.self, forKey: .iosDeviceModel) ?? "iPad13,8"
        windowWidth = try container.decodeIfPresent(Int.self, forKey: .windowWidth) ?? 1920
        windowHeight = try container.decodeIfPresent(Int.self, forKey: .windowHeight) ?? 1080
        customScaler = try container.decodeIfPresent(Double.self, forKey: .customScaler) ?? 2.0
        resolution = try container.decodeIfPresent(Int.self, forKey: .resolution) ?? 1
        aspectRatio = try container.decodeIfPresent(Int.self, forKey: .aspectRatio) ?? 1
        notch = try container.decodeIfPresent(Bool.self, forKey: .notch) ?? NSScreen.hasNotch()
        bypass = try container.decodeIfPresent(Bool.self, forKey: .bypass) ?? false
        discordActivity = try container.decodeIfPresent(DiscordActivity.self,
                                                        forKey: .discordActivity) ?? DiscordActivity()
        version = try container.decodeIfPresent(String.self, forKey: .version) ?? "3.0.0"
        playChain = try container.decodeIfPresent(Bool.self, forKey: .playChain) ?? true
        playChainDebugging = try container.decodeIfPresent(Bool.self, forKey: .playChainDebugging) ?? false
        inverseScreenValues = try container.decodeIfPresent(Bool.self, forKey: .inverseScreenValues) ?? false
        metalHUD = try container.decodeIfPresent(Bool.self, forKey: .metalHUD) ?? false
        windowFixMethod = try container.decodeIfPresent(Int.self, forKey: .windowFixMethod) ?? 0
        injectIntrospection = try container.decodeIfPresent(Bool.self, forKey: .injectIntrospection) ?? false
        rootWorkDir = try container.decodeIfPresent(Bool.self, forKey: .rootWorkDir) ?? true
        noKMOnInput = try container.decodeIfPresent(Bool.self, forKey: .noKMOnInput) ?? true
        enableScrollWheel = try container.decodeIfPresent(Bool.self, forKey: .enableScrollWheel) ?? true
        hideTitleBar = try container.decodeIfPresent(Bool.self, forKey: .hideTitleBar) ?? false
        floatingWindow = try container.decodeIfPresent(Bool.self, forKey: .floatingWindow) ?? false
        checkMicPermissionSync = try container.decodeIfPresent(Bool.self, forKey: .checkMicPermissionSync) ?? false
        limitMotionUpdateFrequency = try container.decodeIfPresent(Bool.self,
                                                                   forKey: .limitMotionUpdateFrequency) ?? false
        disableBuiltinMouse = try container.decodeIfPresent(Bool.self, forKey: .disableBuiltinMouse) ?? false
        resizableAspectRatioType = try container.decodeIfPresent(Int.self, forKey: .resizableAspectRatioType) ?? 0
        resizableAspectRatioWidth = try container.decodeIfPresent(Int.self, forKey: .resizableAspectRatioWidth) ?? 0
        resizableAspectRatioHeight = try container.decodeIfPresent(Int.self, forKey: .resizableAspectRatioHeight) ?? 0
        blockSleepSpamming = try container.decodeIfPresent(Bool.self, forKey: .blockSleepSpamming) ?? false
    }

    mutating func applyOverrides(_ overrides: [String: Any]) {
        guard !overrides.isEmpty else { return }
        if let val = overrides["keymapping"] as? Bool { keymapping = val }
        if let val = overrides["resolution"] as? Int { resolution = val }
        if let val = overrides["bypass"] as? Bool { bypass = val }
        if let val = overrides["inverseScreenValues"] as? Bool { inverseScreenValues = val }
        if let val = overrides["windowFixMethod"] as? Int { windowFixMethod = val }
        if let val = overrides["checkMicPermissionSync"] as? Bool { checkMicPermissionSync = val }
        if let val = overrides["limitMotionUpdateFrequency"] as? Bool { limitMotionUpdateFrequency = val }
        if let val = overrides["disableBuiltinMouse"] as? Bool { disableBuiltinMouse = val }
        if let val = overrides["blockSleepSpamming"] as? Bool { blockSleepSpamming = val }
    }
}

struct ExtraAppSettingsData: Codable {
    var enableCustomCursor = false
    var customCursorWidth = 32
    var customCursorHeight = 32
    var customCursorHotSpotX = 0
    var customCursorHotSpotY = 0
    var forceQuitAppOnClose = false
    var unrealEngineSetScaleFactor = false
    var ignoreClicksWhenNotFocused = true
    var enhanceBuiltinMouse = false
    var preventKeyboardBeepSound = false
    var fixPlayChainMatchLimit = true
    var unityEngineFixKeyboardInput = false
    var disableINTLUtilsSwizzling = false
    var unityEngineForceLandscape = false
    var unrealEngineSmartTextInput = false
    var webViewSmartTextInput = false
    var unityEngineIgnoreKeyboardDelegateCrash = false
    var preloadAppTrackingFramework = false
    var skipGameCenterLogin = false
    var unityEngineDisableOrientationCheck = false
    var unityEngineDisableAROverlayTouches = false
    var forceWebViewUseMobileContentMode = false
    var unrealEngineBypassEntitlementsCheck = false
    var preventGoogleMeasurmentWriteFiles = false
    var bypassUnknownDetectionA = false
    var unrealEngineFixFilePath = false
    var fixAvailableMemoryValue = false
    var neoxEngineFixFilePath = false
    var disableCriWareSonicSync = false
    var enableAutoRotate = false
    var jinChanChanFixMicrophone = false
    var forceUIViewLandscape = false
    var forceUIViewLandscapeArgs: [String] = []
    var useBuiltinPointerLock = false
    var clearLastTouchesWhenEnterTextInput = false
    var disableAllAlertDialogs = false
    var dontInterceptClicksInUIViews = false
    var dontInterceptClicksInUIViewsArgs: [String] = []
    var unityEngineFixAutoRotate = false
    var useNewHitTestMethodWhenNilWindow = true
    var useNewHitTestMethodAlways = false
    var racingMasterFixFilePath = false // swiftlint:disable:this inclusive_language
    var fortniteFixNonMainThreadCrash = false
    var fortniteDisableOptionKey = false
    var nanaoriFixBuiltinMouseIssue = false
    var fixPlayChainAccessGroup = false
    var supportMultipleMice = false

    init() {}

    // swiftlint:disable line_length
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enableCustomCursor = try container.decodeIfPresent(Bool.self, forKey: .enableCustomCursor) ?? false
        customCursorWidth = try container.decodeIfPresent(Int.self, forKey: .customCursorWidth) ?? 32
        customCursorHeight = try container.decodeIfPresent(Int.self, forKey: .customCursorHeight) ?? 32
        customCursorHotSpotX = try container.decodeIfPresent(Int.self, forKey: .customCursorHotSpotX) ?? 0
        customCursorHotSpotY = try container.decodeIfPresent(Int.self, forKey: .customCursorHotSpotY) ?? 0
        forceQuitAppOnClose = try container.decodeIfPresent(Bool.self, forKey: .forceQuitAppOnClose) ?? false
        unrealEngineSetScaleFactor = try container.decodeIfPresent(Bool.self, forKey: .unrealEngineSetScaleFactor) ?? false
        ignoreClicksWhenNotFocused = try container.decodeIfPresent(Bool.self, forKey: .ignoreClicksWhenNotFocused) ?? true
        enhanceBuiltinMouse = try container.decodeIfPresent(Bool.self, forKey: .enhanceBuiltinMouse) ?? false
        preventKeyboardBeepSound = try container.decodeIfPresent(Bool.self, forKey: .preventKeyboardBeepSound) ?? false
        fixPlayChainMatchLimit = try container.decodeIfPresent(Bool.self, forKey: .fixPlayChainMatchLimit) ?? true
        unityEngineFixKeyboardInput = try container.decodeIfPresent(Bool.self, forKey: .unityEngineFixKeyboardInput) ?? false
        disableINTLUtilsSwizzling = try container.decodeIfPresent(Bool.self, forKey: .disableINTLUtilsSwizzling) ?? false
        unityEngineForceLandscape = try container.decodeIfPresent(Bool.self, forKey: .unityEngineForceLandscape) ?? false
        unrealEngineSmartTextInput = try container.decodeIfPresent(Bool.self, forKey: .unrealEngineSmartTextInput) ?? false
        webViewSmartTextInput = try container.decodeIfPresent(Bool.self, forKey: .webViewSmartTextInput) ?? false
        unityEngineIgnoreKeyboardDelegateCrash = try container.decodeIfPresent(Bool.self, forKey: .unityEngineIgnoreKeyboardDelegateCrash) ?? false
        preloadAppTrackingFramework = try container.decodeIfPresent(Bool.self, forKey: .preloadAppTrackingFramework) ?? false
        skipGameCenterLogin = try container.decodeIfPresent(Bool.self, forKey: .skipGameCenterLogin) ?? false
        unityEngineDisableOrientationCheck = try container.decodeIfPresent(Bool.self, forKey: .unityEngineDisableOrientationCheck) ?? false
        unityEngineDisableAROverlayTouches = try container.decodeIfPresent(Bool.self, forKey: .unityEngineDisableAROverlayTouches) ?? false
        forceWebViewUseMobileContentMode = try container.decodeIfPresent(Bool.self, forKey: .forceWebViewUseMobileContentMode) ?? false
        unrealEngineBypassEntitlementsCheck = try container.decodeIfPresent(Bool.self, forKey: .unrealEngineBypassEntitlementsCheck) ?? false
        preventGoogleMeasurmentWriteFiles = try container.decodeIfPresent(Bool.self, forKey: .preventGoogleMeasurmentWriteFiles) ?? false
        bypassUnknownDetectionA = try container.decodeIfPresent(Bool.self, forKey: .bypassUnknownDetectionA) ?? false
        unrealEngineFixFilePath = try container.decodeIfPresent(Bool.self, forKey: .unrealEngineFixFilePath) ?? false
        fixAvailableMemoryValue = try container.decodeIfPresent(Bool.self, forKey: .fixAvailableMemoryValue) ?? false
        neoxEngineFixFilePath = try container.decodeIfPresent(Bool.self, forKey: .neoxEngineFixFilePath) ?? false
        disableCriWareSonicSync = try container.decodeIfPresent(Bool.self, forKey: .disableCriWareSonicSync) ?? false
        enableAutoRotate = try container.decodeIfPresent(Bool.self, forKey: .enableAutoRotate) ?? false
        jinChanChanFixMicrophone = try container.decodeIfPresent(Bool.self, forKey: .jinChanChanFixMicrophone) ?? false
        forceUIViewLandscape = try container.decodeIfPresent(Bool.self, forKey: .forceUIViewLandscape) ?? false
        forceUIViewLandscapeArgs = try container.decodeIfPresent([String].self, forKey: .forceUIViewLandscapeArgs) ?? []
        useBuiltinPointerLock = try container.decodeIfPresent(Bool.self, forKey: .useBuiltinPointerLock) ?? false
        clearLastTouchesWhenEnterTextInput = try container.decodeIfPresent(Bool.self, forKey: .clearLastTouchesWhenEnterTextInput) ?? false
        disableAllAlertDialogs = try container.decodeIfPresent(Bool.self, forKey: .disableAllAlertDialogs) ?? false
        dontInterceptClicksInUIViews = try container.decodeIfPresent(Bool.self, forKey: .dontInterceptClicksInUIViews) ?? false
        dontInterceptClicksInUIViewsArgs = try container.decodeIfPresent([String].self, forKey: .dontInterceptClicksInUIViewsArgs) ?? []
        unityEngineFixAutoRotate = try container.decodeIfPresent(Bool.self, forKey: .unityEngineFixAutoRotate) ?? false
        useNewHitTestMethodWhenNilWindow = try container.decodeIfPresent(Bool.self, forKey: .useNewHitTestMethodWhenNilWindow) ?? true
        useNewHitTestMethodAlways = try container.decodeIfPresent(Bool.self, forKey: .useNewHitTestMethodAlways) ?? false
        racingMasterFixFilePath = try container.decodeIfPresent(Bool.self, forKey: .racingMasterFixFilePath) ?? false
        fortniteFixNonMainThreadCrash = try container.decodeIfPresent(Bool.self, forKey: .fortniteFixNonMainThreadCrash) ?? false
        fortniteDisableOptionKey = try container.decodeIfPresent(Bool.self, forKey: .fortniteDisableOptionKey) ?? false
        nanaoriFixBuiltinMouseIssue = try container.decodeIfPresent(Bool.self, forKey: .nanaoriFixBuiltinMouseIssue) ?? false
        fixPlayChainAccessGroup = try container.decodeIfPresent(Bool.self, forKey: .fixPlayChainAccessGroup) ?? false
        supportMultipleMice = try container.decodeIfPresent(Bool.self, forKey: .supportMultipleMice) ?? false
    }

    // swiftlint:disable:next cyclomatic_complexity
    mutating func applyOverrides(_ overrides: [String: Any]) {
        guard !overrides.isEmpty else { return }
        if let val = overrides["forceQuitAppOnClose"] as? Bool { forceQuitAppOnClose = val }
        if let val = overrides["unrealEngineSetScaleFactor"] as? Bool { unrealEngineSetScaleFactor = val }
        if let val = overrides["enableCustomCursor"] as? Bool { enableCustomCursor = val }
        if let val = overrides["customCursorWidth"] as? Int { customCursorWidth = val }
        if let val = overrides["customCursorHeight"] as? Int { customCursorHeight = val }
        if let val = overrides["customCursorHotSpotX"] as? Int { customCursorHotSpotX = val }
        if let val = overrides["customCursorHotSpotY"] as? Int { customCursorHotSpotY = val }
        if let val = overrides["ignoreClicksWhenNotFocused"] as? Bool { ignoreClicksWhenNotFocused = val }
        if let val = overrides["enhanceBuiltinMouse"] as? Bool { enhanceBuiltinMouse = val }
        if let val = overrides["preventKeyboardBeepSound"] as? Bool { preventKeyboardBeepSound = val }
        if let val = overrides["fixPlayChainMatchLimit"] as? Bool { fixPlayChainMatchLimit = val }
        if let val = overrides["unityEngineFixKeyboardInput"] as? Bool { unityEngineFixKeyboardInput = val }
        if let val = overrides["disableINTLUtilsSwizzling"] as? Bool { disableINTLUtilsSwizzling = val }
        if let val = overrides["unityEngineForceLandscape"] as? Bool { unityEngineForceLandscape = val }
        if let val = overrides["unrealEngineSmartTextInput"] as? Bool { unrealEngineSmartTextInput = val }
        if let val = overrides["webViewSmartTextInput"] as? Bool { webViewSmartTextInput = val }
        if let val = overrides["unityEngineIgnoreKeyboardDelegateCrash"] as? Bool { unityEngineIgnoreKeyboardDelegateCrash = val }
        if let val = overrides["preloadAppTrackingFramework"] as? Bool { preloadAppTrackingFramework = val }
        if let val = overrides["skipGameCenterLogin"] as? Bool { skipGameCenterLogin = val }
        if let val = overrides["unityEngineDisableOrientationCheck"] as? Bool { unityEngineDisableOrientationCheck = val }
        if let val = overrides["unityEngineDisableAROverlayTouches"] as? Bool { unityEngineDisableAROverlayTouches = val }
        if let val = overrides["forceWebViewUseMobileContentMode"] as? Bool { forceWebViewUseMobileContentMode = val }
        if let val = overrides["unrealEngineBypassEntitlementsCheck"] as? Bool { unrealEngineBypassEntitlementsCheck = val }
        if let val = overrides["preventGoogleMeasurmentWriteFiles"] as? Bool { preventGoogleMeasurmentWriteFiles = val }
        if let val = overrides["bypassUnknownDetectionA"] as? Bool { bypassUnknownDetectionA = val }
        if let val = overrides["unrealEngineFixFilePath"] as? Bool { unrealEngineFixFilePath = val }
        if let val = overrides["fixAvailableMemoryValue"] as? Bool { fixAvailableMemoryValue = val }
        if let val = overrides["neoxEngineFixFilePath"] as? Bool { neoxEngineFixFilePath = val }
        if let val = overrides["disableCriWareSonicSync"] as? Bool { disableCriWareSonicSync = val }
        if let val = overrides["enableAutoRotate"] as? Bool { enableAutoRotate = val }
        if let val = overrides["jinChanChanFixMicrophone"] as? Bool { jinChanChanFixMicrophone = val }
        if let val = overrides["forceUIViewLandscape"] as? Bool { forceUIViewLandscape = val }
        if let val = overrides["forceUIViewLandscapeArgs"] as? [String] { forceUIViewLandscapeArgs = val }
        if let val = overrides["useBuiltinPointerLock"] as? Bool { useBuiltinPointerLock = val }
        if let val = overrides["clearLastTouchesWhenEnterTextInput"] as? Bool { clearLastTouchesWhenEnterTextInput = val }
        if let val = overrides["disableAllAlertDialogs"] as? Bool { disableAllAlertDialogs = val }
        if let val = overrides["dontInterceptClicksInUIViews"] as? Bool { dontInterceptClicksInUIViews = val }
        if let val = overrides["dontInterceptClicksInUIViewsArgs"] as? [String] { dontInterceptClicksInUIViewsArgs = val }
        if let val = overrides["unityEngineFixAutoRotate"] as? Bool { unityEngineFixAutoRotate = val }
        if let val = overrides["useNewHitTestMethodWhenNilWindow"] as? Bool { useNewHitTestMethodWhenNilWindow = val }
        if let val = overrides["useNewHitTestMethodAlways"] as? Bool { useNewHitTestMethodAlways = val }
        if let val = overrides["racingMasterFixFilePath"] as? Bool { racingMasterFixFilePath = val }
        if let val = overrides["fortniteFixNonMainThreadCrash"] as? Bool { fortniteFixNonMainThreadCrash = val }
        if let val = overrides["fortniteDisableOptionKey"] as? Bool { fortniteDisableOptionKey = val }
        if let val = overrides["nanaoriFixBuiltinMouseIssue"] as? Bool { nanaoriFixBuiltinMouseIssue = val }
        if let val = overrides["fixPlayChainAccessGroup"] as? Bool { fixPlayChainAccessGroup = val }
        if let val = overrides["supportMultipleMice"] as? Bool { supportMultipleMice = val }
    }
    // swiftlint:enable line_length
}

class AppSettings {
    static var appSettingsDir: URL {
        let settingsFolder =
            PlayTools.playCoverContainer.appendingPathComponent("App Settings")
        if !FileManager.default.fileExists(atPath: settingsFolder.path) {
            do {
                try FileManager.default.createDirectory(at: settingsFolder,
                                                        withIntermediateDirectories: true,
                                                        attributes: [:])
            } catch {
                Log.shared.error(error)
            }
        }
        return settingsFolder
    }

    let info: AppInfo
    let settingsUrl: URL
    let extraSettingsUrl: URL
    var openWithLLDB: Bool = false
    var openLLDBWithTerminal: Bool = true
    var settings: AppSettingsData {
        didSet {
            encode()
        }
    }
    var extraSettings: ExtraAppSettingsData {
       didSet {
           encodeExtra()
       }
    }

    init(_ info: AppInfo) {
        self.info = info
        settingsUrl = AppSettings.appSettingsDir.appendingPathComponent(info.bundleIdentifier)
                                                .appendingPathExtension("plist")
        extraSettingsUrl = AppSettings.appSettingsDir.appendingPathComponent(info.bundleIdentifier + ".extra")
                                                     .appendingPathExtension("plist")
        settings = AppSettingsData()
        extraSettings = ExtraAppSettingsData()
        var overrides: [String: Any]?
        if !decode() {
            if overrides == nil {
                overrides = loadOverrides()
            }
            if let overrides = overrides {
                applyOverridesToBaseSettings(overrides)
            }
            encode()
        }
        if !decodeExtra() {
            if overrides == nil {
                overrides = loadOverrides()
            }
            if let overrides = overrides {
                applyOverridesToExtraSettings(overrides)
            }
            encodeExtra()
        }

        settings.bundleIdentifier = info.bundleIdentifier
    }

    public func sync() {
        settings.notch = NSScreen.hasNotch()
    }

    public func reset() {
        settings = AppSettingsData()
        extraSettings = ExtraAppSettingsData()
        let overrides = loadOverrides()
        applyOverridesToBaseSettings(overrides)
        applyOverridesToExtraSettings(overrides)
    }

    @discardableResult
    public func decode() -> Bool {
        do {
            let data = try Data(contentsOf: settingsUrl)
            settings = try PropertyListDecoder().decode(AppSettingsData.self, from: data)
            return true
        } catch {
            print(error)
            return false
        }
    }

    @discardableResult
    public func encode() -> Bool {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml

        do {
            let data = try encoder.encode(settings)
            try data.write(to: settingsUrl)
            return true
        } catch {
            print(error)
            return false
        }
    }

    @discardableResult
    public func decodeExtra() -> Bool {
        do {
            let data = try Data(contentsOf: extraSettingsUrl)
            extraSettings = try PropertyListDecoder().decode(ExtraAppSettingsData.self, from: data)
            return true
        } catch {
            print(error)
            return false
        }
    }

    @discardableResult
    public func encodeExtra() -> Bool {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml

        do {
            let data = try encoder.encode(extraSettings)
            try data.write(to: extraSettingsUrl)
            return true
        } catch {
            print(error)
            return false
        }
    }

    func loadOverrides() -> [String: Any] {
        var overrides: [String: Any] = [:]
        guard let url = Bundle.main.url(
            forResource: info.bundleIdentifier,
            withExtension: "json",
            subdirectory: "AppSettingsOverrides"
        ) else {
            return overrides
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            return overrides
        }

        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let dictionary = json as? [String: Any] {
                overrides = dictionary
            }
        } catch {
            print(error)
        }
        return overrides
    }

    private func applyOverridesToBaseSettings(_ overrides: [String: Any]) {
        if info.isUnityEngine {
            settings.limitMotionUpdateFrequency = true
        }
        settings.applyOverrides(overrides)
    }

    private func applyOverridesToExtraSettings(_ overrides: [String: Any]) {
        if info.isUnityEngine {
            extraSettings.unityEngineFixKeyboardInput = true
        }
        if info.isUnrealEngine {
            extraSettings.unrealEngineFixFilePath = true
            extraSettings.fixAvailableMemoryValue = true
        }
        if info.isNeoXEngine {
            extraSettings.neoxEngineFixFilePath = true
        }
        extraSettings.applyOverrides(overrides)
    }
}

extension NSScreen {
    public static func hasNotch() -> Bool {
        guard #available(macOS 12, *) else { return false }
        // check if any of the connected screens contains a notch
        return NSScreen.screens.contains { $0.safeAreaInsets.top != 0 }
    }

    private static func getMacModel() -> String? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        var modelIdentifier: String?

        if let modelData = IORegistryEntryCreateCFProperty(service, "model" as CFString, kCFAllocatorDefault, 0)
            .takeRetainedValue() as? Data {
            if let modelIdentifierCString = String(data: modelData, encoding: .utf8)?.cString(using: .utf8) {
                modelIdentifier = String(cString: modelIdentifierCString)
            }
        }
        IOObjectRelease(service)
        return modelIdentifier
    }
}
