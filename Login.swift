//
//  Login.swift
//  PreSales-Huddle
//
//  Created by Himanshu Phirke on 28/07/15.
//  Copyright (c) 2015 synerzip. All rights reserved.
//

import UIKit
class Login : UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate, GIDSignInUIDelegate {
  
  let userRoles = ["Sales", "User"]
    let salesRepresenatives:[String] = ["salil.khedkar@synerzip.com","himanshu.phirke@synerzip.com"]
  var roleRow = 0
  var gPlusSignInEnabled = false
  var hud:MBProgressHUD?
  @IBOutlet weak var userName: UITextField!
  @IBOutlet weak var picker: UIPickerView!
  
  @IBOutlet weak var enter: UIButton!
  
  
  @IBAction func enterKeyBoard(sender: AnyObject) {
    performSegueWithIdentifier("enter-segue", sender: self)
  }
  
  override func viewDidLoad() {
    userName.becomeFirstResponder()
    if let id = NSUserDefaults.standardUserDefaults().stringForKey("userID") {
      userName.text = id
      enter.enabled = true
    }
    stylizeControls()
    
    // Enabling Google SignIn
    prepareForGoogleSignIn()
    GIDSignIn.sharedInstance().uiDelegate = self
    GIDSignIn.sharedInstance().signInSilently()
  }
  
  private func stylizeControls() {
    enter.backgroundColor = Theme.Prospects.okButtonBG
    Theme.applyButtonBorder(enter)
  }
    
  func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return userRoles.count
  }
  
  func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
    return userRoles[row]
  }
  
  func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    roleRow = row
  }
  
  func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
    return 1
  }
  
  func pickerView(pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
    return 100.0
  }
  
  func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange,
    replacementString string: String) -> Bool {
      let oldString: NSString = userName.text
      let newString: NSString = oldString.stringByReplacingCharactersInRange(
        range, withString: string)
      enter.enabled = newString.length > 0
      return true
  }
    
  func prepareForGoogleSignIn() {
    gPlusSignInEnabled = true
    userName.hidden = true
    picker.hidden = true
    enter.hidden = true
  }
    
  func enableGoogleSignIn() {
    prepareForGoogleSignIn()
    
    let frame = CGRect(x: userName.frame.origin.x, y: userName.frame.origin.y, width: 100, height: userName.frame.height)
    var signInButtonView = GIDSignInButton(frame: frame)
    view.addSubview(signInButtonView)
    
    // some constraints
    signInButtonView.center = view.center
    signInButtonView.addTarget(self, action: "signUsingGoogleInitiated:", forControlEvents: UIControlEvents.TouchUpInside)
  }
  
  func signUsingGoogleInitiated(sender: UIView) {
    dispatch_async(dispatch_get_main_queue()) {
      self.hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
      self.hud?.labelText = "Loading.."
      self.hud?.detailsLabelText = "Waiting for Google SignIn"
    }
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    var uName = userName.text;
    var uRole = userRoles[roleRow]
    if (gPlusSignInEnabled) {
      var user = GIDSignIn.sharedInstance().currentUser
      uName = user.profile.name
      uRole = contains(salesRepresenatives, user.profile.email) ? "Sales" : "User"
    }
    
    NSUserDefaults.standardUserDefaults().setObject(uName, forKey: "userID")
    NSUserDefaults.standardUserDefaults().setObject(uRole, forKey: "userRole")
    NSUserDefaults.standardUserDefaults().synchronize()
  }
}
