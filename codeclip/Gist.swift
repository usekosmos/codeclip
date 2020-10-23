//
//  Gist.swift
//  codeclip
//
//  Created by Kevin Unkrich on 10/21/20.
//

import SwiftUI

class Gist: NSObject {
    private let GITHUB_API_URL = "https://api.github.com"
    private let authHelper = AuthenticationHelper()
    
    func isAuthenticated() -> Bool {
        return authHelper.access_token != nil
    }
    
    func login(completionHandler: @escaping ([String: Any]) -> Void, pollCompletion: @escaping () -> Void) {
        authHelper.deviceFlowLogin(completionHandler: { data in
            completionHandler(data)
            self.authHelper.poll(response: data, completionHandler: pollCompletion)
        })
    }
    
    func create() {
        guard let accessToken = authHelper.access_token else {
            print("GitHub is not authenticated.")
            return
        }
        
        let url = URL(string: GITHUB_API_URL + "/gists")!
        var request = URLRequest(url: url)
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Accept: application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.addValue("token " + accessToken, forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = Gist.createHttpBody()
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                if let html_url = responseJSON["html_url"] as? String {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(html_url, forType: .string)
                } else {
                    print("There was an issue creating the gist.")
                }
            }
        })
        task.resume()
    }
    
    private class func createHttpBody() -> Data? {
        let files = ClipboardHelper.retrieveFiles()
        guard files.count > 0 else { return  nil }
        
        let parameters: [String: Any] = [
            "description": "Gist created by CodeClip on " + Date().toString(dateFormat: "MM/dd/yyyy HH:mm:ss"),
            "public": false,
            "files": files
        ]
        let jsonData = try? JSONSerialization.data(withJSONObject: parameters)
        
        return jsonData
    }
}
