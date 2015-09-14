//
//  EmailNotification.swift
//  PreSales-Huddle
//
//  Created by Vinaya Mandke on 25/08/15.
//  Copyright (c) 2015 Synerzip. All rights reserved.
//

import Foundation

class EmailNotification {
    var emailBody = ""
    var subject = ""
    var signedInUser = GIDSignIn.sharedInstance().currentUser
    var receivers = ""
    var sender = ""
    var access_token = ""
    
    var mailer:NSURLSessionDataTask?
   
    init(accessToken: String, msgText: String) {
        access_token = accessToken
        emailBody = msgText
        sender = "\(signedInUser.profile.name) via PreSales-Huddle <\(signedInUser.profile.email)>"
//        receivers = "vinaya.mandke@synerzip.com"
//        receivers += ";himanshu.phirke@synerzip.com"
    }
    
    func setTo(to: String) {
        receivers = to
    }
    
    func addReceivers(toList: [String]) {
        for to in toList {
            receivers += receivers.isEmpty ? to : ";" + to
        }
    }
    
    private func handleError(err: NSError) {
        //error handler
        println("\(err)")
    }
    
    private func getMimetextArray(recs: String, sender: String, sub: String, emailText: String) -> [String] {
        return  [
            "Content-Type: text/plain; charset=\"us-ascii\"",
            "MIME-Version: 1.0",
            "Content-Transfer-Encoding: 7bit",
            //sender
            "to: " + recs,
            //receiver
            "from: " + sender,
            //subject
            "subject: " + sub,
            //forced empty line
            "",
            //message text
            emailText
        ]
    }
    
    private func makeAString(arr: [String]) -> String {
        return join("\n", arr)
    }
    
    private func encode(str: String) -> String {
        let utf8str = str.dataUsingEncoding(NSUTF8StringEncoding)
        return utf8str!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
    }
    
    private func encodeJSON(dataString : [String:AnyObject]) -> NSData? {
       var err: NSError?
       return NSJSONSerialization.dataWithJSONObject(dataString, options: nil, error: &err)
    }
    
    private func getMailerRequest() -> NSMutableURLRequest {
        let url = "https://www.googleapis.com/gmail/v1/users/me/messages/send"
        let apiUrl = NSURL(string: url)
        let request = NSMutableURLRequest(URL: apiUrl!)
        request.HTTPMethod = "POST"
        request.setValue("Bearer \(access_token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }
    
    func sendEmail(successHandler:(NSData) -> Void, handleServiceError: (NSHTTPURLResponse) -> Void) {
        let mimeTextArr = getMimetextArray(receivers, sender: self.sender, sub: subject, emailText: emailBody)
        let messageText = makeAString(mimeTextArr)
        
        // encode as base64
        let encodedMsg = encode(messageText)
        let request = getMailerRequest()
        let config_ = NSURLSessionConfiguration.defaultSessionConfiguration()
        config_.timeoutIntervalForRequest = 10.0
        let session = NSURLSession(configuration: config_)
        
        let requestBody = encodeJSON(["raw":encodedMsg])
        let nc = NetworkCommunication()
        var successful = false
        if let data = requestBody {
          nc.postData(data, successHandler: successHandler,
            serviceErrorHandler: handleServiceError,
            errorHandler: errorHandler,
            request: request)
        }
    }
    
    func errorHandler(err: NSError) {
        println("\(err)")
    }
}
