//
//  ConvertClient.swift
//  PreSales-Huddle
//
//  Created by Himanshu Phirke on 27/07/15.
//  Copyright (c) 2015 synerzip. All rights reserved.
//

import UIKit

class ConvertClient: UIViewController, DateSelectorDelegate {
 
  var prospectID: Int?
  var prospectName: String?
  private var startDate = NSDate()
  let updateProspectURL = "prospect/update/"
// MARK: Outlets
  @IBOutlet weak var start_date: UITextField!
  @IBOutlet weak var done: UIBarButtonItem!
  @IBOutlet weak var bu_head: UITextField!
  @IBOutlet weak var team_size: UITextField!
  @IBOutlet weak var prospect_name: UITextField!

// MARK: view functions
  override func viewDidLoad() {
    super.viewDidLoad()
    // stylizeControls()
    if let name = prospectName {
      prospect_name.text = name
    }
    team_size.becomeFirstResponder()
  }
  
// MARK: action functions
  @IBAction func done(sender: UIBarButtonItem) {
    updateProspectToWebService(updateProspectURL)
  }
  @IBAction func date_click(sender: UITextField) {
    let dateVC = DateSelector(nibName: "DateSelector", bundle: nil)
    dateVC.modalPresentationStyle = UIModalPresentationStyle.OverFullScreen
    dateVC.delegate = self
    dateVC.type = "StartDate"
    dateVC.pickerType = UIDatePickerMode.Date
    dateVC.senderFrame = sender.frame
    presentViewController(dateVC, animated: false, completion: nil)
  }
  
// MARK : private functions
  
  private func loadDateSelectorNIB(type: String) {
  }

  private func commonHandler() {
    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
  }

  func saveProspectSuccess() -> Void {
    commonHandler()
    dispatch_async(dispatch_get_main_queue()) {
      self.showMessage("Success",
        message: "Prospect converted to Client.")
    }
  }
  
  func networkError( error: NSError) -> Void {
    commonHandler()
    dispatch_async(dispatch_get_main_queue()) {
      self.showMessage("Network error",
        message: "Code: \(error.code)\n\(error.localizedDescription)")
    }
  }
  
  func serviceError(response: NSHTTPURLResponse) -> Void {
    commonHandler()
    dispatch_async(dispatch_get_main_queue()) {
      self.showMessage("Webservice Error",
        message: "Error received from webservice: \(response.statusCode)")
    }
  }

  private func saveProspectToWebService(dict: [String: AnyObject], method: String) {
    print("Prospect save:  \(dict)")
    saveProspectSuccess()
  }
  
  private func getFormData() -> [String: AnyObject] {
    var prospect = [String: AnyObject]()
    prospect["StartDate"] = DateHandler.getDBDate(startDate)
    prospect["BUHead"] = bu_head.text
    prospect["TeamSize"] = Int(team_size.text!)
    prospect["Name"] = prospect_name.text
    if let id = prospectID {
      prospect["ProspectID"] = id
    }
    return prospect
  }

  private func getNSData(prospectDict: [String: AnyObject]) -> NSData? {
    var jsonData:NSData?
    do {
      jsonData = try NSJSONSerialization.dataWithJSONObject(
            prospectDict, options: [])
    } catch {
      jsonData = nil
    }
    return jsonData
  }
  
  private func updateProspectToWebService(operation: String) {
    let prospect = getFormData()
    saveProspectToWebService(prospect, method:operation)
  }

  private func showMessage(title:String, message: String) {
    let alert = UIAlertController(title: title, message: message,
      preferredStyle: .Alert)
    let action = UIAlertAction(title: "Ok", style: .Default, handler: {
      action in
      self.navigationController?.popViewControllerAnimated(true)
    })
    alert.addAction(action)
    presentViewController(alert, animated: true, completion: nil)
  }
  
  private func stylizeControls() {
    view.backgroundColor = Theme.Prospects.formBG

    // Text Field BG Color
    bu_head.backgroundColor = Theme.Prospects.textFieldBG
    team_size.backgroundColor = Theme.Prospects.textFieldBG
    prospect_name.backgroundColor = Theme.Prospects.textFieldBG
    
    start_date.backgroundColor = Theme.Prospects.textFieldBG
    // Theme.applyLabelBorder(start_date_label)
  }

  // MARK: Delegate Functions
  func dateSelectorDidFinish(dateFromVC: NSDate, type: String?) {
    if let type = type {
      if type == "StartDate" {
        startDate = dateFromVC
        start_date.text = DateHandler.getPrintDate(startDate)
        done.enabled = true
        start_date.resignFirstResponder()
      }
    }
  }
}
