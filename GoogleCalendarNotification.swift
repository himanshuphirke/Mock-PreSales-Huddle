//
//  GoogleCalendarNotification.swift
//  PreSales-Huddle
//
//  Created by Vinaya Mandke on 27/08/15.
//  Copyright (c) 2015 Synerzip. All rights reserved.
//
//

import Foundation

class GoogleCalendarNotification {
    
    
    
    var endDate:NSDate
    var startDate:NSDate
    var attendees = [String]()
    var summary = ""
    var description = ""
    var access_token = ""
    
    //computed values for JSON
    
    var attendeesJSON: [[String:AnyObject]] {
        var json = [[String:AnyObject]]()
        for attendee in attendees {
            json.append(["email": attendee])
        }
        return json
    }
    
    var requestBody: [String:AnyObject] {
        return [
            "end":[
                "dateTime": endDate.rfc3339Formatted
            ],
            "start": [
                "dateTime": startDate.rfc3339Formatted
            ],
            "attendees": attendeesJSON,
            "summary" : summary
        ]
    }
    
    var request: NSMutableURLRequest {
        let url = "https://www.googleapis.com/calendar/v3/calendars/primary/events?sendNotifications=true&supportsAttachments=false"
        let apiUrl = NSURL(string: url)
        let request = NSMutableURLRequest(URL: apiUrl!)
        request.HTTPMethod = "POST"
        request.setValue("Bearer \(access_token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }
    
    init(token: String) {
        access_token = token
        startDate = NSDate()
        endDate = NSDate()
    }
    
    func addAttendee(attendee: String) {
        attendees.append(attendee)
    }
    
    private func encodeJSON(dataString : [String:AnyObject]) -> NSData? {
        do {
            return try NSJSONSerialization.dataWithJSONObject(dataString, options: [])
        } catch _ {
            return nil
        }
    }
    
    func createEventAndSendNotifications(successHandler:(NSData) -> Void, handleServiceError: (NSHTTPURLResponse) -> Void) {
        let config_ = NSURLSessionConfiguration.defaultSessionConfiguration()
        config_.timeoutIntervalForRequest = 10.0
        let nc = NetworkCommunication()
        let requestDataJSON = encodeJSON(requestBody)
        if let data = requestDataJSON {
            nc.postData(data, successHandler: successHandler,
                serviceErrorHandler: handleServiceError,
                errorHandler: errorHandler,
                request: request)
        }
    }
    
    func errorHandler(err: NSError) {
        print("\(err)")
    }
}

extension NSDate {
    struct Date {
        static let formatter = NSDateFormatter()
    }
    var rfc3339Formatted: String {
        Date.formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        Date.formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        // RFC 3339 is similar to ISO 8601
        Date.formatter.calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierISO8601)!
        Date.formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        return Date.formatter.stringFromDate(self)
    }
}

