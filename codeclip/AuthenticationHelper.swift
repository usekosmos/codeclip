//
//  AuthenticationHelper.swift
//  codeclip
//
//  Created by Kevin Unkrich on 10/23/20.
//

import Foundation

class AuthenticationHelper: NSObject {
    let GITHUB_URL = "https://github.com"
    let GITHUB_CLIENT_ID = "c77cbb6d0ee65f2e6ecd"
    
    private var run_count = 0 // these should be optionals
    private var run_count_max = 0
    private var timer: Timer?
    
    var device_code = ""
    var access_token: String?
    var pollCompletion: (() -> Void)?
    
    func deviceFlowLogin(completionHandler: @escaping ([String: Any]) -> Void) {
        guard self.timer == nil else { return }
        
        let url = URL(string: GITHUB_URL + "/login/device/code")!
        var request = URLRequest(url: url)
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        
        let parameters: [String: Any] = [
            "scope": "gist",
            "client_id": GITHUB_CLIENT_ID
        ]
        let jsonData = try? JSONSerialization.data(withJSONObject: parameters)
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                completionHandler(responseJSON)
            }
        })
        task.resume()
    }
    
    func poll(response: [String: Any], completionHandler: @escaping () -> Void) {
        guard self.timer == nil else { return }
        self.pollCompletion = completionHandler
        
        guard let interval = response["interval"] as? Double, let expires_in = response["expires_in"] as? Double, let device_code = response["device_code"] as? String else {
            print("Could not parse GitHub response for device auth flow polling.")
            return
        }
        
        self.run_count = 0
        self.run_count_max = Int(expires_in / interval)
        self.device_code = device_code
        
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(self.pollAuthenticationStatus), userInfo: nil, repeats: true)
        }
    }
    
    @objc func pollAuthenticationStatus() {
        let url = URL(string: GITHUB_URL + "/login/oauth/access_token")!
        var request = URLRequest(url: url)
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        
        let parameters: [String: Any] = [
            "device_code": self.device_code,
            "client_id": "c77cbb6d0ee65f2e6ecd",
            "grant_type": "urn:ietf:params:oauth:grant-type:device_code"
        ]
        let jsonData = try? JSONSerialization.data(withJSONObject: parameters)
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                if let access_token = responseJSON["access_token"] as? String {
                    print("Retrieved access token from GitHub server.")
                    
                    self.access_token = access_token
                    self.timer?.invalidate()
                    self.timer = nil
                } else if let responseError = responseJSON["error"] as? String, responseError == "slow_down", let interval = responseJSON["interval"] as? Double {
                    print("GitHub server requested interval slow down to " + String(interval) + " seconds")
                    
                    self.timer?.invalidate()
                    DispatchQueue.main.async {
                        self.timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(self.pollAuthenticationStatus), userInfo: nil, repeats: true)
                    }
                }
            }
            
            if let responseJSON = responseJSON as? [String: Any], let access_token = responseJSON["access_token"] as? String {
                print(responseJSON)
                self.access_token = access_token
                if let completionHandler = self.pollCompletion {
                    completionHandler()
                }
                self.timer?.invalidate()
                self.timer = nil
            }
        })
        task.resume()
        
        self.run_count += 1
        if run_count == run_count_max {
            print("Github Authorization Expired. Please retry.")
            timer?.invalidate()
            self.timer = nil
        }
    }
}
