//
//  Login.swift
//  PreSales-Huddle
//
//  Created by Himanshu Phirke on 28/07/15.
//  Copyright (c) 2015 synerzip. All rights reserved.
//

import UIKit
class Login : UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate, GIDSignInDelegate, GIDSignInUIDelegate {
  
  let userRoles = ["Sales", "User"]
  let salesRepresenatives:[String] = [
    "salil.khedkar@synerzip.com",
    "himanshu.phirke@synerzip.com",
    "vinaya.mandke@synerzip.com"
  ]
  var roleRow = 0
  var gPlusSignInEnabled = false
  var hud:MBProgressHUD?
  var signInButtonView:UIControl?
  @IBOutlet weak var userName: UITextField!
  @IBOutlet weak var picker: UIPickerView!
  
  @IBOutlet weak var enter: UIButton!
  
  
  @IBAction func enterKeyBoard(sender: AnyObject) {
    performSegueWithIdentifier("enter-segue", sender: self)
  }
  
  override func viewWillAppear(animated: Bool) {
    if GIDSignIn.sharedInstance().currentUser == nil {
      GIDSignIn.sharedInstance().signInSilently()
    }
  }
  override func viewDidLoad() {
    if let id = NSUserDefaults.standardUserDefaults().stringForKey("userID") {
      userName.text = id
      enter.enabled = true
    }
    stylizeControls()
    progressDisplayLogin()
    // Enabling Google SignIn
    initGoogleSignIn()
    initSignInButton()
    prepareForGoogleSignIn()
    GIDSignIn.sharedInstance().uiDelegate = self
  }
  private func initSignInButton() {
    let frame = CGRect(x: userName.frame.origin.x, y: userName.frame.origin.y, width: 100, height: userName.frame.height)
    signInButtonView = GIDSignInButton(frame: frame)
    // some constraints
    signInButtonView?.center = view.center
    signInButtonView?.addTarget(self, action: "signUsingGoogleInitiated:", forControlEvents: UIControlEvents.TouchUpInside)
    signInButtonView?.tag = 10
  }
  
  private func initGoogleSignIn() {
    let apiScopes = ["https://www.googleapis.com/auth/gmail.send", "https://www.googleapis.com/auth/calendar"]
    let currentScopes = GIDSignIn.sharedInstance().scopes as NSArray
    GIDSignIn.sharedInstance().scopes = currentScopes.arrayByAddingObjectsFromArray(apiScopes)
    // Initialize sign-in
    var configureError: NSError?
    GGLContext.sharedInstance().configureWithError(&configureError)
    assert(configureError == nil, "Error configuring Google services: \(configureError)")
    GIDSignIn.sharedInstance().delegate = self
  }
  
  private func stylizeControls() {
    enter.backgroundColor = Theme.Prospects.okButtonBG
    Theme.applyButtonBorder(enter)
  }
    
  func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return userRoles.count
  }
  
  func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
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
      let oldString: NSString = userName.text!
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
    dispatch_async(dispatch_get_main_queue()) {
      self.view.addSubview(self.signInButtonView!)
      self.signInButtonView?.center = self.view.center
    }
  }
  
  func signUsingGoogleInitiated(sender: UIView) {
    progressDisplayLogin()
  }

  private func progressDisplayLogin() {
    dispatch_async(dispatch_get_main_queue()) {
    self.hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
    self.hud?.labelText = "Logging.."
    self.hud?.detailsLabelText = "Waiting for Google Sign-In"
    self.hud?.yOffset = 100
    }
  }
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    var uName = userName.text;
    var uRole = userRoles[roleRow]
    if (gPlusSignInEnabled) {
      let user = GIDSignIn.sharedInstance().currentUser
      uName = user.profile.name
      uRole = salesRepresenatives.contains(user.profile.email) ? "Sales" : "User"
    }
    
    NSUserDefaults.standardUserDefaults().setObject(uName, forKey: "userID")
    NSUserDefaults.standardUserDefaults().setObject(uRole, forKey: "userRole")
    NSUserDefaults.standardUserDefaults().synchronize()
  }
  
  func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!, withError error: NSError!) {
    dispatch_async(dispatch_get_main_queue()) {
     self.hud?.hide(true)
    }
    if (error == nil) {
      dispatch_async(dispatch_get_main_queue()) {
        let signIn = self.view.viewWithTag(10)
        signIn?.removeFromSuperview()
      }
      let user = GIDSignIn.sharedInstance().currentUser
      let email = user.profile.email as NSString
      let r = email.rangeOfString("@synerzip.com", options: NSStringCompareOptions.CaseInsensitiveSearch)
      
      if r.location == NSNotFound {
        GIDSignIn.sharedInstance().signOut()
        print("Sign-In Validation: Login from non-synerzip id")
        let name = user.profile.name as String
        let msg = "Dear \(name) \nPlease login using synerzip email"
        let alert = UIAlertController(title: "Invalid Login", message: msg, preferredStyle: .Alert)
        let action = UIAlertAction(title: "Ok", style: .Default, handler: nil)
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: {
            self.enableGoogleSignIn()
        })

      } else {
        performSegueWithIdentifier("enter-segue", sender: self)
      }
    } else {
      enableGoogleSignIn()
      print("Sign-In Error: \(error.localizedDescription)")
    }
  }  
}
