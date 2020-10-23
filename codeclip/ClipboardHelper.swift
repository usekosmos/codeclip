//
//  ClipboardHelper.swift
//  codeclip
//
//  Created by Kevin Unkrich on 10/23/20.
//

import SwiftUI

class ClipboardHelper: NSObject {
    class func retrieveFiles() -> [String: Any] {
        var files:[String: Any] = [:]
        
        let pasteboard = NSPasteboard.general
        let items = pasteboard.pasteboardItems
        
        if let items = items, !items.isEmpty {
            for item in items {
                let path = item.string(forType: NSPasteboard.PasteboardType(rawValue: "public.file-url"))
                if let path = path, let url = URL(string: path) {
                    do {
                        let text = try String(contentsOf: url, encoding: .utf8)
                        files[url.lastPathComponent] = ["content": text]
                    }
                    catch {
                        print("couldn't read contents of file")
                        return [:]
                    }
                }
            }
            
            if files.count == 0, let text = items.first?.string(forType: .string) {
                files["clipboard-" + Date().toString(dateFormat: "MM-dd-yyyy-HH:mm:ss") + ".txt"] = ["content": text]
            }
        }
        
        return files
    }
}
