//
//  NetworkCommunication.swift
//  PreSales-Huddle
//
//  Created by Himanshu Phirke on 21/07/15.
//  Copyright (c) 2015 Himanshu Phirke. All rights reserved.
//

import Foundation
import UIKit

class NetworkCommunication {
  private var baseUrl_:String
  var requestTimeOut:NSTimeInterval
  private var config_:NSURLSessionConfiguration
  var postTask: NSURLSessionDataTask?
  var getTask: NSURLSessionDataTask?
  
  init() {
    baseUrl_ = "http://127.0.0.1:8080/"
    requestTimeOut = 10.0
    config_ = NSURLSessionConfiguration.defaultSessionConfiguration()
  }
  
  private func urlwithText(relativeURL: String) -> NSURL? {
    return NSURL(string: baseUrl_ + relativeURL)
  }
  
  // Return value indicates if the function was able to call the network
  // function or not. Actuall errors will be passed to respective handlers
  // successHandler: Handler called only when success is returned by webservice
  // serviceErrorHandler: Handler called to handle webservice valid errors
  // error: Handler for error in network communication
  
  func fetchData(relativeURL:String,
    successHandler:(NSData) -> Void,
    serviceErrorHandler: (NSHTTPURLResponse) -> Void,
    errorHandler:(NSError) -> Void) -> Bool {
      let url = urlwithText(relativeURL)
      if (url == nil) {
        print("Error: Unable to form a valid URL")
        return false
      }
      config_.timeoutIntervalForRequest = requestTimeOut
      let session = NSURLSession(configuration: config_)
      
      getTask?.cancel()
      UIApplication.sharedApplication().networkActivityIndicatorVisible = true
      getTask = session.dataTaskWithURL(url!, completionHandler: {
        data, response, error in
        if let error = error {
          errorHandler(error)
        } else if let http_response = response as? NSHTTPURLResponse {
          if http_response.statusCode == 200 {
            if let data = data {
              successHandler(data)
            } else {
              // This case coule be seen only when Webservice fails to return data
              // and only sends 200 status code
            }
          } else {
            serviceErrorHandler(http_response)
          }
        }
      })
      getTask?.resume()
      return true
  }
  
  // Return value indicates if the function was able to call the network
  // function or not. Actuall errors will be passed to respective handlers
  // data: Data to be sent in Post request body
  // successHandler: Handler called only when success is returned by webservice
  // serviceErrorHandler: Handler called to handle webservice valid errors
  // error: Handler for error in network communication
  
  func postData(data:NSData,
    successHandler:(NSData) -> Void,
    serviceErrorHandler: (NSHTTPURLResponse) -> Void,
    errorHandler:(NSError) -> Void,
    request: NSMutableURLRequest?,
    relativeURL:String = "") -> Bool {
      UIApplication.sharedApplication().networkActivityIndicatorVisible = true
      let session = NSURLSession(configuration: config_)
      postTask?.cancel()
      let postRequest = (request != nil) ? request : getRequest(relativeURL)
      if let urlRequest = postRequest {
        postTask = session.uploadTaskWithRequest(urlRequest, fromData: data,
          completionHandler: {
            data, response, error in
            if let error = error {
              errorHandler(error)
            } else if let http_response = response as? NSHTTPURLResponse {
              if http_response.statusCode == 200 {
                if let data = data {
                  successHandler(data)
                } else {
                  // This case coule be seen only when Webservice fails to return data
                  // and only sends 200 status code
                }
              } else {
                serviceErrorHandler(http_response)
              }
            }
        })
      } else {
        print("PostTask Error: Unable to unwrap request from optional")
        return false
      }
      postTask?.resume()
      return true
  }
    
  private func getRequest(relativeURL:String) -> NSMutableURLRequest? {
    let url = urlwithText(relativeURL)
    if (url == nil) {
      print("Error: Unable to form a valid URL")
      return nil
    }
    config_.timeoutIntervalForRequest = requestTimeOut
    let request = NSMutableURLRequest(URL: url!)
    request.HTTPMethod = "POST"
    return request
  }
}
