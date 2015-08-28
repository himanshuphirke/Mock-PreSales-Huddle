//
//  Prospect.swift
//  PreSales-Huddle
//
//  Created by Himanshu Phirke on 22/07/15.
//  Copyright (c) 2015 synerzip. All rights reserved.
//

import UIKit


protocol ProspectDelgate: class {
  func saveProspectFinish(name: String)
}

class Prospect: UIViewController, UITextFieldDelegate, UITextViewDelegate, ParticipateInCallDelgate  {

  var hud:MBProgressHUD?
  var delegate: ProspectDelgate?
  var itemToEdit: [String: AnyObject]?
  var userRole = "Unknown"
  var pinFile = "pin"
  var prospectID: Int?
  var isDead: Bool?
  var participantEntryPresent = false
  let addProspectURL = "prospect/add/"
  let updateProspectURL = "prospect/update/"
  let viewParticipantsByUserIDURL = "participant/view/userid/"
  let addParticipant = "participant/add/"
  let updateParticipant = "participant/update/"
  var keyBoardHeight:CGFloat = 400
  var dateSelected = NSDate()
  
  // MARK: Outlets
  @IBOutlet weak var name: UITextField!
  @IBOutlet weak var notes: UITextView!
  @IBOutlet weak var domain: UITextField!
  @IBOutlet weak var desiredTeamSize: UITextField!
  @IBOutlet weak var techStack: UITextField!
  @IBOutlet weak var date: UITextField!
  @IBOutlet weak var desiredtTeamDesc: UITextField!

  @IBOutlet weak var status: UITextField!
  @IBOutlet weak var listOfContacts: UITextField!
  @IBOutlet weak var discussions: UIBarButtonItem!
  @IBOutlet weak var save_button: UIButton!

  @IBOutlet weak var pinImage: UIImageView!
  @IBOutlet weak var participateButton: UIButton!
  var blinkState = true;
  // MARK: view Functions

  override func viewWillAppear(animated: Bool) {
    getUserRole()
    accessControl()
    participantEntryPresent = false
    if let prospect = itemToEdit {
      // Edit or view screen
      prospectID = prospect["ProspectID"] as? Int
      if userRole == "Sales" {
        self.title = "Edit Prospect"
      } else {
        self.title = "View Prospect"
        fetchParticipantDetails()
      }
      
      if let isDead = isDead {
        status.text = "Dead Prospect"
        status.textColor = UIColor.redColor()
      }
      displayFormData(prospect)
    } else {
      discussions.enabled = false
      name.becomeFirstResponder()
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // stylizeControls()
    notes.layer.borderWidth = 1.0
    notes.layer.cornerRadius = 5.0
    notes.layer.borderColor = UIColor(red: 0.835, green: 0.835, blue: 0.835, alpha: 1.00).CGColor
    
    initMockData()
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyBoardShow:", name: UIKeyboardWillShowNotification, object: nil)
  
  }
  
  func keyBoardShow(notification: NSNotification) {
    keyBoardHeight = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue().height
  }
  
  // MARK: Action functions
    
  @IBAction func save(sender: AnyObject) {
    dispatch_async(dispatch_get_main_queue()) {
      self.hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
      self.hud?.labelText = "Saving data"
      self.hud?.detailsLabelText = "Please wait..."
    }
    
    saveProspectSuccessMock()
//    if let prospect = itemToEdit {
//      // Edit
//      updateProspectToWebService(updateProspectURL)
//    } else {
//      // Add
//      updateProspectToWebService(addProspectURL)
//    }
  }

  @IBAction func participateInCall(sender: UISwitch) {
    var participant = [String: AnyObject]()
    var operation = addParticipant

    participant["ProspectID"] = prospectID

    if let userName = NSUserDefaults.standardUserDefaults().stringForKey("userID") {
      participant["UserID"] = userName
    }
    var value = "No"
    if sender.on == true {
      value = "Yes"
    }
    participant["Participation"] = value
    
    if participantEntryPresent == true {
      // Update query
      operation = updateParticipant
    } else {
      // Add Query
      operation = addParticipant
      participant["Included"] = "Yes"
    }
    
    saveParticipantWebService(participant, method:operation)
    
  }
  
  @IBAction func date_click(sender: UITextField) {
    sender.resignFirstResponder()
    callDatePicker(sender)
  }
  
  // MARK: Date Popup - Start
  
  func changeDate(sender: UIDatePicker) {
    dateSelected = sender.date
  }
  
  func removeViews() {
    UIView.animateWithDuration(0.5, animations: {
      self.view.viewWithTag(31)?.alpha = 0
      self.view.viewWithTag(32)?.alpha = 0
      self.view.viewWithTag(33)?.alpha = 0
      }, completion: {
        val in
        self.view.viewWithTag(31)?.removeFromSuperview()
        self.view.viewWithTag(32)?.removeFromSuperview()
        self.view.viewWithTag(33)?.removeFromSuperview()
    })
  }
  
  func dismissDatePicker(sender: AnyObject) {
    removeViews()
  }
  
  func dateDone(sender: AnyObject) {
    date.text = DateHandler.getPrintDate(dateSelected)
    removeViews()
  }
  
  func callDatePicker(sender: UITextField) {

    let trans = UIView(frame: self.view.frame)
    trans.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
    trans.tag = 31
    let tap = UITapGestureRecognizer(target: self, action: "dismissDatePicker:")
    trans.addGestureRecognizer(tap)
    self.view.addSubview(trans)
    
    let datePickerFrame = CGRectMake(0, 0, 0, 0);
    let datePicker = UIDatePicker(frame: datePickerFrame)
    datePicker.tag = 32;
    datePicker.backgroundColor = UIColor.whiteColor()
    datePicker.datePickerMode = UIDatePickerMode.Date
    datePicker.addTarget(self, action: "changeDate:", forControlEvents: UIControlEvents.ValueChanged)
    datePicker.layer.borderWidth = 1.0
    datePicker.layer.cornerRadius = 20.0
    datePicker.layer.borderColor = UIColor.grayColor().CGColor
    datePicker.layer.masksToBounds = true
    self.view.addSubview(datePicker)
  
    
    let dateDoneButtonFrame = CGRectMake(0, datePicker.frame.origin.y + datePicker.frame.height + self.view.frame.height, datePicker.frame.width, 50);
    let dateDoneButton = UIButton(frame: dateDoneButtonFrame)
    dateDoneButton.addTarget(self, action: "dateDone:", forControlEvents: UIControlEvents.TouchUpInside)
    dateDoneButton.setTitle("Done", forState: UIControlState.Normal)
    dateDoneButton.setTitleColor(UIColor(red: 0.039, green: 0.494, blue: 0.992, alpha: 1.00), forState: UIControlState.Normal)
    dateDoneButton.setTitleColor(UIColor(red: 0.039, green: 0.494, blue: 0.992, alpha: 0.20), forState: UIControlState.Highlighted)
    dateDoneButton.backgroundColor = UIColor.whiteColor()
    dateDoneButton.layer.borderWidth = 1.0
    dateDoneButton.layer.cornerRadius = 10.0
    dateDoneButton.layer.borderColor = UIColor.grayColor().CGColor
    dateDoneButton.tag = 33;
    self.view.addSubview(dateDoneButton)
    
    
    UIView.animateWithDuration(0.4, animations: {
      datePicker.frame = CGRectMake(0, sender.frame.origin.y + sender.frame.height + 10, 0, 0)
      dateDoneButton.frame = CGRectMake(0, datePicker.frame.origin.y + datePicker.frame.height, datePicker.frame.width, 50)
    })

  }
  
  // MARK: Date Popup - Start
  
  @IBAction func tapOnPin(sender: UITapGestureRecognizer) {
    pinImage.image = toggleImage()
    if pinFile == "unpin" {
      pinImage.alpha = 0.25
    } else {
      pinImage.alpha = 1
    }
  }
// MARK: Internal functions
  
  private func toggleImage() -> UIImage? {
    if pinFile == "pin" {
      pinFile = "unpin"
    } else {
      pinFile = "pin"
    }
    return UIImage(named:pinFile)
  }
  private func accessControl() {
    if userRole == "Sales" {
      participateButton.hidden = true
    } else {
      save_button.hidden = true
    }
  }
  
  private func initMockData() {
    date.text = DateHandler.getPrintDate(NSDate())
    let dateFieldLabel = UILabel(frame: CGRectZero)
    dateFieldLabel.text = " Date "
    dateFieldLabel.font = UIFont.systemFontOfSize(14)
    dateFieldLabel.sizeToFit()
    dateFieldLabel.textColor = UIColor.grayColor()
    date.leftViewMode = UITextFieldViewMode.Always
    date.leftView = dateFieldLabel

    
    let statusFieldLabel = UILabel(frame: CGRectZero)
    statusFieldLabel.text = " Status "
    statusFieldLabel.font = UIFont.systemFontOfSize(14)
    statusFieldLabel.sizeToFit()
    statusFieldLabel.textColor = UIColor.grayColor()
    status.leftViewMode = UITextFieldViewMode.Always
    status.leftView = statusFieldLabel
  
  }
  
  private func getUserRole() {
    if let role = NSUserDefaults.standardUserDefaults().stringForKey("userRole") {
      userRole = role
    }
  }
  
  private func stylizeControls() {
    // Applying outline to textview
    notes.layer.borderColor = Theme.Prospects.inputOutline.CGColor
    notes.layer.borderWidth = 1.0
    notes.layer.cornerRadius = 5.0
    
    // Setting tint color
    navigationController?.navigationBar.backgroundColor = Theme.Prospects.navBarBG
    view.backgroundColor = Theme.Prospects.formBG
    
    
    // Text Field BG Color    
    name.backgroundColor = Theme.Prospects.textFieldBG
    notes.backgroundColor = Theme.Prospects.textFieldBG
    domain.backgroundColor = Theme.Prospects.textFieldBG
    desiredTeamSize.backgroundColor = Theme.Prospects.textFieldBG
    techStack.backgroundColor = Theme.Prospects.textFieldBG
    date.backgroundColor = Theme.Prospects.textFieldBG
    desiredtTeamDesc.backgroundColor = Theme.Prospects.textFieldBG
    status.backgroundColor = Theme.Prospects.textFieldBG
    listOfContacts.backgroundColor = Theme.Prospects.textFieldBG


    save_button.backgroundColor = Theme.Prospects.okButtonBG
    participateButton.backgroundColor = Theme.Prospects.okButtonBG


    Theme.applyButtonBorder(save_button)
    Theme.applyButtonBorder(participateButton)

  }
  
  private func displayFormData(prospect: [String: AnyObject]) {
    name.text = prospect["Name"] as! String
    techStack.text = prospect["TechStack"] as! String
    domain.text = prospect["Domain"] as! String
    if let teamSize = prospect["DesiredTeamSize"] as? Int {
      desiredTeamSize.text = "\(teamSize)"
    }
    desiredtTeamDesc.text = prospect["DesiredTeamDesc"] as! String
    listOfContacts.text =  prospect["ListOfContacts"] as! String
    notes.text = prospect["Notes"] as! String

  }
  private func getFormData() -> [String: AnyObject] {
    var prospect = [String: AnyObject]()
    prospect["Name"] = name.text
    prospect["TechStack"] = techStack.text
    prospect["Domain"] = domain.text
    prospect["DesiredTeamSize"] = desiredTeamSize.text.toInt()
    prospect["Notes"] = notes.text
    return prospect
  }
  
  private func getNSData(prospectDict: [String: AnyObject]) -> NSData? {
    var jsonError:NSError?
    var jsonData:NSData? = NSJSONSerialization.dataWithJSONObject(
      prospectDict, options: nil, error: &jsonError)
    return jsonData
  }

  private func updateProspectToWebService(operation: String) {
    var prospect = getFormData()
    if operation == updateProspectURL {
      if let id = prospectID {
        prospect["ProspectID"] = id
      }
    } else if let userName = NSUserDefaults.standardUserDefaults().stringForKey("userID") {
      prospect["SalesID"] = userName
      prospect["CreateDate"] = DateHandler.getDBDate(NSDate())
    }

    saveProspectToWebService(prospect, method:operation)
  }
  
  private func saveProspectToWebService(dict: [String: AnyObject], method: String) {
    println("Prospect save:  \(dict)")
    if let data = getNSData(dict) {
      let nc = NetworkCommunication()
      nc.postData(method, data: data,
          successHandler: saveProspectSuccess,
          serviceErrorHandler: serviceError,
          errorHandler: networkError)
    } else {
      showMessage("Failure", message: "Failed to convert data")
    }
  }
  
  private func saveParticipantWebService(dict: [String: AnyObject], method: String) {
    println("Participant operation:  \(method)")
    println("Participant save:  \(dict)")
    participantSaveSuccess()
  }
  
  private func showMessage(title:String, message: String) {
    let alert = UIAlertController(title: title, message: message,
      preferredStyle: .Alert)
    let action = UIAlertAction(title: "Ok", style: .Default, handler: {
      action in
      self.dismissViewControllerAnimated(false,completion: nil)
    })
    alert.addAction(action)
    presentViewController(alert, animated: true, completion: nil)
  }

  private func commonHandler() {
    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    dispatch_async(dispatch_get_main_queue()) {
      self.hud?.hide(true, afterDelay: 1.0)
    }
  }
  
  private func setParticipantSwitch(dict: [String: AnyObject]) -> Bool {
    if let participate = dict["Participation"] as? String {
      participantEntryPresent = true
      if participate == "Yes" {
      return true
      }
    }
    return false
  }
  
  func fetchParticipantSuccess() -> Void {
    commonHandler()
  }
  func saveProspectSuccessMock() -> Void {
    commonHandler()
    self.navigationController?.popViewControllerAnimated(true)
    delegate?.saveProspectFinish(name.text)
    // send an email
    let user = GIDSignIn.sharedInstance().currentUser
    let auth = user.authentication
    auth.getAccessTokenWithHandler({ (tokenstr, err) -> Void in
      if err == nil {
        let newData = self.getFormData()
        var emailBody = "I have added a new Prospect. Please check it out.\n\n\(newData)\n\nRegards,\n\(user.profile.name)"
        var draft = EmailNotification(accessToken: tokenstr, msgText: emailBody)
        draft.addReceivers([user.profile.email])
        draft.subject = "[New Prospect]  \(self.name.text)"
        if let prospect = self.itemToEdit {
          draft.subject = "[Prospect Update]  \(self.name.text)"
        }
        draft.sendEmail(self.emailSuccessHandler, handleServiceError: self.emailServiceErrorHandler)
      }
    })
  }

  func emailSuccessHandler(data: NSData) -> Void {
    commonHandler()
    println("Email sent successfully")
  }

  func emailServiceErrorHandler(response: NSHTTPURLResponse) -> Void {
    commonHandler()
    println("Email Failed to send. Statuc code: \(response.statusCode)")
  }
  
  func saveProspectSuccess(data: NSData) -> Void {
    commonHandler()
    delegate?.saveProspectFinish(name.text)
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
  
  func participantSaveSuccess() -> Void {
    commonHandler()
    participantEntryPresent = true
    dispatch_async(dispatch_get_main_queue()) {
      let hudMessage = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
      hudMessage.mode = MBProgressHUDMode.Text
      hudMessage.labelText = "Preference saved"
      hudMessage.hide(true, afterDelay: 1.5)
      hudMessage.opacity = 0.4
      hudMessage.yOffset = Float(self.view.frame.size.height/2 - 100)
    }

  }

  
  func participantNetworkError( error: NSError) -> Void {
    commonHandler()
    dispatch_async(dispatch_get_main_queue()) {
      self.showMessage("Network error",
        message: "Code: \(error.code)\n\(error.localizedDescription)")

    }
  }
  
  func participantServiceError(response: NSHTTPURLResponse) -> Void {
    commonHandler()
    dispatch_async(dispatch_get_main_queue()) {
      self.showMessage("Webservice Error",
        message: "Error received from webservice: \(response.statusCode)")

    }
  }
  

  private func fetchParticipantDetails() {
    if let userName = NSUserDefaults.standardUserDefaults().stringForKey("userID") {
      fetchParticipantSuccess()
    }
  }

  // MARK: Segue Functions
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "Discussions" {
      let targetController = segue.destinationViewController as! UINavigationController
      let targetView = targetController.topViewController as! Discussions
      if let id = prospectID {
        targetView.prospectID = id
      }
    } else if segue.identifier == "ScheduleCall" {
      let targetController = segue.destinationViewController as! UINavigationController
      let targetView = targetController.topViewController as! ScheduleCall
      if let id = prospectID {
        targetView.prospectID = id
      }
    } else if segue.identifier == "ParticipateInCall" {
      let targetView = segue.destinationViewController as! ParticipateInCall
      targetView.delegate = self
    }
  }
  
  // MARK: Delegate Functions
  
  func saveFinish() {
    dispatch_async(dispatch_get_main_queue()) {
      let hudMessage = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
      hudMessage.mode = MBProgressHUDMode.Text
      hudMessage.labelText = "Saved..."
      hudMessage.hide(true, afterDelay: 0.7)
      hudMessage.opacity = 0.25
      hudMessage.yOffset = Float(self.view.frame.size.height/2 - 100)
    }
  }
  
//  func textViewDidBeginEditing(textView: UITextView) {
//    UIView.animateWithDuration(0.5, animations: {
//      self.view.bounds.origin.y += self.keyBoardHeight - 50
//    })
//    
//  }
//  
//  func textViewDidEndEditing(textView: UITextView) {
//    UIView.animateWithDuration(0.5, animations: {
//      self.view.bounds.origin.y = 0
//    })
//  }

}
