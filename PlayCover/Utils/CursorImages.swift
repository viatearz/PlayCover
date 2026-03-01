//
//  CursorImages.swift
//  PlayCover
//

import Foundation

class CursorImages {
    static let shared = CursorImages()
    static var cursorImageDir: URL {
        let cursorImageFolder = PlayTools.playCoverContainer.appendingPathComponent("Cursors")

        if !FileManager.default.fileExists(atPath: cursorImageFolder.path) {
            do {
                try FileManager.default.createDirectory(at: cursorImageFolder, withIntermediateDirectories: true)
            } catch {
                Log.shared.error(error)
            }
        }

        return cursorImageFolder
    }

    func imageURL(for bundleID: String) -> URL {
        return CursorImages.cursorImageDir
            .appendingPathComponent(bundleID)
            .appendingPathExtension("png")
    }

    func load(bundleID: String) -> NSImage? {
        let url = imageURL(for: bundleID)
        return NSImage(contentsOfFile: url.path)
    }

    func save(srcImageUrl: URL, for bundleID: String) {
        do {
            let dstImageUrl = imageURL(for: bundleID)
            FileManager.default.delete(at: dstImageUrl)
            try FileManager.default.copyItem(at: srcImageUrl, to: dstImageUrl)
        } catch {
            Log.shared.error(error)
        }
    }

    func clear(bundleID: String) {
        let url = imageURL(for: bundleID)
        FileManager.default.delete(at: url)
    }
}
