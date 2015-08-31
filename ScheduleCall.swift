//
//  ScheduleCall.swift
//  PreSales-Huddle
//
//  Created by Himanshu Phirke on 26/07/15.
//  Copyright (c) 2015 synerzip. All rights reserved.
//

import UIKit

class ScheduleCall: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, DateSelectorDelegate {

  var hud:MBProgressHUD?
  var allParticipants = [Participant]()
  var prospectID: Int?
  let viewParticipantsURL = "participant/view/prospectid/"
  let updateParticipantURL = "participant/update/"
  let updateProspectURL = "prospect/update/"
  var toDate: NSDate = NSDate()
  var fromDate: NSDate = NSDate()

  // used for mock screens only
    var mockProspectData = [String:AnyObject]()

  // MARK: Outlets
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var participants_selected_count: UILabel!
  @IBOutlet weak var selection_note: UILabel!
  @IBOutlet weak var done: UIBarButtonItem!
  
  @IBOutlet weak var from_date_label: UITextField!
  @IBOutlet weak var to_date_label: UITextField!
  @IBOutlet weak var duration_label: UITextField!
  
  @IBOutlet weak var currentTableView: UITableView!
  @IBOutlet weak var noParticipantsLabel: UILabel!
  
// MARK: view functions
  override func viewDidLoad() {
    super.viewDidLoad()
    // stylizeControls()
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    fetchData()
  }

// MARK: action functions

  @IBAction func done(sender: AnyObject) {
    let from = (DateHandler.getDBDate(fromDate) as NSString).doubleValue
    let to = (DateHandler.getDBDate(toDate) as NSString).doubleValue
    if to > from {
      // updateProspectToWebService(updateProspectURL)
      saveProspectSuccessMock()
    } else {
      showMessage("Date Error",
        message: "Select valid From and To date")

    }
  }

  
  func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
    if textField.tag == 333 {
      let dateVC = DateSelector(nibName: "DateSelector", bundle: nil)
      dateVC.modalPresentationStyle = UIModalPresentationStyle.OverFullScreen
      dateVC.delegate = self
      dateVC.type = "From"
      dateVC.senderFrame = textField.frame
      presentViewController(dateVC, animated: false, completion: nil)
      return false
    } else if textField.tag == 444 {
      let dateVC = DateSelector(nibName: "DateSelector", bundle: nil)
      dateVC.modalPresentationStyle = UIModalPresentationStyle.OverFullScreen
      dateVC.delegate = self
      dateVC.type = "To"
      dateVC.senderFrame = textField.frame
      presentViewController(dateVC, animated: false, completion: nil)
      return false
    }
    return true
  }
  
// MARK: tableView functions
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return allParticipants.count
  }

  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("participant") as! UITableViewCell
    let participant = allParticipants[indexPath.row]
    populateCellData(cell, withParticipant: participant)
    configureSelectionLabel()
    // stylizeCell(cell,index: indexPath.row)
    return cell
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    if let cell = tableView.cellForRowAtIndexPath(indexPath) {
      let participant = allParticipants[indexPath.row]
      participant.toggleInclusion()
      configureCheckmarkForCell(cell, included: participant.isIncluded_)
      saveParticipantData(participant)
    }
    // Deselects the row
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
    configureSelectionLabel()
    tableView.reloadData()
  }
  
// MARK: Internal functions

  private func loadDateSelectorNIB(type: String) {
    let dateVC = DateSelector(nibName: "DateSelector", bundle: nil)
    dateVC.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
    dateVC.delegate = self
    dateVC.type = type
    presentViewController(dateVC, animated: true, completion: nil)
  }
  private func configureSelectionLabel() {
    var count = 0
    for entry in allParticipants {
      count = entry.isIncluded_ == "Yes" ? count + 1 : count
    }
    if count == 0 {
      done.enabled = false
    } else {
      done.enabled = true
    }
    participants_selected_count.text = "Selected Participants: \(count)"
  }
  
  private func getNSData(prospectDict: [String: AnyObject]) -> NSData? {
    var jsonError:NSError?
    var jsonData:NSData? = NSJSONSerialization.dataWithJSONObject(
      prospectDict, options: nil, error: &jsonError)
    return jsonData
  }

  private func saveParticipantData(participant: Participant) {
    var dict = participant.getDict()
    if let id = prospectID {
      dict["ProspectID"] = id
    }
    println(dict)
    if let data = getNSData(dict) {
      saveToWebService(data, operation: updateParticipantURL)
    } else {
      showMessage("Failure", message: "Failed to convert data")
    }
  }
  private func configureCheckmarkForCell(cell: UITableViewCell, included: String) {
    let label = cell.viewWithTag(301) as! UILabel
    if included == "Yes" {
      label.text = "√"
      label.textColor = view.tintColor
    } else {
      label.text = "X"
      label.textColor = UIColor(red: 204.0/255.0, green: 51/255.0, blue: 51/255.0, alpha: 1.0)
    }

  }
  
  private func setTextInTableCell(cell: UITableViewCell, name: String) {
      let label = cell.viewWithTag(302) as! UILabel
      label.text = name
  }

  
  private func populateCellData(cell: UITableViewCell,
    withParticipant participant: Participant) {
    configureCheckmarkForCell(cell, included: participant.isIncluded_)
    setTextInTableCell(cell, name: participant.userID_)
  }
  
  private func stylizeControls() {
    navigationController?.navigationBar.backgroundColor = Theme.Prospects.navBarBG
    tableView.separatorColor = Theme.Prospects.tableViewSeparator
    tableView.backgroundColor = Theme.Prospects.cellBGOddCell
    view.backgroundColor = Theme.Prospects.cellBGOddCell

//    Theme.applyLabelBorder(from_date_label) Edge are rounded and background color is not edged
//    Theme.applyLabelBorder(to_date_label)
//    Theme.applyLabelBorder(duration_label)
    
    to_date_label.backgroundColor = Theme.Prospects.textFieldBG
    from_date_label.backgroundColor = Theme.Prospects.textFieldBG
    duration_label.backgroundColor = Theme.Prospects.textFieldBG

  }
  
  private func fetchData() {
    dispatch_async(dispatch_get_main_queue()) {
      self.hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
      self.hud?.labelText = "Loading.."
    }

    fetch_success()
  }

  private func commonHandler() {
    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    dispatch_async(dispatch_get_main_queue()) {
      self.hud?.hide(true)
    }
  }
  
  class func fillData() -> [Participant] {
    let prospect1 = Participant(userID: "Himanshu", isIncluded: "Yes")
    let prospect2 = Participant(userID: "Vinaya", isIncluded: "Yes")
    let prospect3 = Participant(userID: "Sachin", isIncluded: "No")
    
    var allPros = [Participant]()

    allPros.append(prospect1)
    allPros.append(prospect2)
    allPros.append(prospect3)
    return allPros
  }
  
  func fetch_success() -> Void {
    commonHandler()
    if let id = prospectID {
      if id == 2 {
          allParticipants = [Participant]()
      } else {
          allParticipants = ScheduleCall.fillData()
      }
    }

    
    if (allParticipants.count == 0) {
      dispatch_async(dispatch_get_main_queue()) {
        self.noParticipantsLabel.hidden = false
        self.currentTableView.hidden = true
        self.done.enabled = false
        self.selection_note.hidden = true
      }
    }
    
  }
  
  func network_error( error: NSError) -> Void {
    commonHandler()
    dispatch_async(dispatch_get_main_queue()) {
      self.showMessage("Network error",
        message: "Code: \(error.code)\n\(error.localizedDescription)")
    }
  }
  
  func service_error(response: NSHTTPURLResponse) -> Void {
    commonHandler()
    dispatch_async(dispatch_get_main_queue()) {
      self.showMessage("Webservice Error",
        message: "Error received from webservice: \(response.statusCode)")
    }
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
  
  func selectionSaveSuccess() -> Void {
    commonHandler()
    dispatch_async(dispatch_get_main_queue()) {
      let hudMessage = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
      hudMessage.mode = MBProgressHUDMode.Text
      hudMessage.labelText = "Saved..."
      hudMessage.hide(true, afterDelay: 0.7)
      hudMessage.opacity = 0.25
      hudMessage.yOffset = Float(self.view.frame.size.height/2 - 100)
    }
  }
  
  func selectionNetworkError( error: NSError) -> Void {
    commonHandler()
    dispatch_async(dispatch_get_main_queue()) {
      self.showMessage("Network error",
        message: "Code: \(error.code)\n\(error.localizedDescription)")
    }
  }
  
  func selectionServiceError(response: NSHTTPURLResponse) -> Void {
    commonHandler()
    dispatch_async(dispatch_get_main_queue()) {
      self.showMessage("Webservice Error",
        message: "Error received from webservice: \(response.statusCode)")
    }
  }
  
  private func saveToWebService(data: NSData, operation: String) {
    println("Operation:  \(operation)")
    selectionSaveSuccess()
  }
  
  private func getFormData() -> [String: AnyObject] {
    var prospect = [String: AnyObject]()
    prospect["ConfDateStart"] = DateHandler.getDBDate(fromDate)
    prospect["ConfDateEnd"] = DateHandler.getDBDate(toDate)
    if let id = prospectID {
      prospect["ProspectID"] = id
    }
    return prospect
  }

  func saveProspectSuccessMock() -> Void {
    commonHandler()
    dispatch_async(dispatch_get_main_queue()) {
      self.showMessage("Data saved",
        message: "Data saved succesfully.")
    }

    //add an event
    let user = GIDSignIn.sharedInstance().currentUser
    let auth = user.authentication
    auth.getAccessTokenWithHandler({ (tokenstr, err) -> Void in
        if err == nil {
            var prospectName = self.mockProspectData["ProspectName"] as! String
            var callType = self.mockProspectData["Type"] as! String
            var prospect = self.mockProspectData["Prospect"] as! [String:AnyObject]
            
            var gCal = GoogleCalendarNotification(token: tokenstr)
            gCal.startDate = self.fromDate
            gCal.endDate = self.toDate
            gCal.summary = "[\(prospectName)] \(callType) Call"
            gCal.attendees = ["vinaya.mandke@synerzip.com","himanshu.phirke@synerzip.com"]
            gCal.createEventAndSendNotifications(self.eventSuccessHandler,
                handleServiceError: self.eventServiceErrorHandler)
        }
    })

    }

    func eventSuccessHandler(data: NSData) -> Void {
        commonHandler()
        //handle success
    }

    func eventServiceErrorHandler(response: NSHTTPURLResponse) -> Void {
        commonHandler()
        // handle service error
        println(response.description)
    }
  
  func saveProspectSuccess(data: NSData) -> Void {
    commonHandler()
    dispatch_async(dispatch_get_main_queue()) {
      self.showMessage("Data saved",
        message: "Data saved succesfully.")
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
    println("Prospect save:  \(dict)")
    if let data = getNSData(dict) {
      let nc = NetworkCommunication()
      nc.postData(data,
        successHandler: saveProspectSuccess,
        serviceErrorHandler: serviceError,
        errorHandler: networkError,
        request: nil,
        relativeURL: method)
    } else {
      showMessage("Failure", message: "Failed to convert data")
    }
  }
  
  private func updateProspectToWebService(operation: String) {
    var prospect = getFormData()
    saveProspectToWebService(prospect, method:operation)
  }
  
  private func stylizeCell(cell: UITableViewCell, index: Int) {
    if index % 2 != 0 {
      cell.backgroundColor = Theme.Prospects.cellBGOddCell
      tableView.backgroundColor = Theme.Prospects.cellBGEvenCell
    } else {
      cell.backgroundColor = Theme.Prospects.cellBGEvenCell
      tableView.backgroundColor = Theme.Prospects.cellBGOddCell
    }
    cell.textLabel?.backgroundColor = UIColor.clearColor()
    cell.detailTextLabel?.backgroundColor = UIColor.clearColor()
  }


  // MARK: Delegate Functions
  func dateSelectorDidFinish(dateFromVC: NSDate, type: String?) {
    if let type = type {
      if type == "From" {
        fromDate = dateFromVC
        from_date_label.text = DateHandler.getPrintDateTime(fromDate)
      } else if type == "To" {
        toDate = dateFromVC
        to_date_label.text = DateHandler.getPrintDateTime(toDate)
        duration_label.text = Int(((toDate.timeIntervalSince1970 - fromDate.timeIntervalSince1970) / 60)).description + " minutes"
      }
    }
  }

  func convertClientFinish() {
    dispatch_async(dispatch_get_main_queue()) {
      let hudMessage = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
      hudMessage.mode = MBProgressHUDMode.Text
      hudMessage.labelText = "Save successful"
      hudMessage.hide(true, afterDelay: 1.5)
      hudMessage.opacity = 0.4
      hudMessage.yOffset = Float(self.view.frame.size.height/2 - 100)
    }
    dismissViewControllerAnimated(true, completion: nil)
  }

}
