//
//  AllProspectsViewController.swift
//  PreSales-Huddle
//
//  Created by Himanshu Phirke on 22/07/15.
//  Copyright (c) 2015 synerzip. All rights reserved.
//

import UIKit
class AllProspects: UITableViewController, ProspectDelgate {
  
  var hud:MBProgressHUD?
  var unScheduledProspect = 0
  // MARK: Outlets
  @IBOutlet weak var AddButton: UIBarButtonItem!
  // MARK: Class variables
  let viewAllURL = "prospect/view/"
   var viewAllNotifications : String? {
      get {
        if let user = NSUserDefaults.standardUserDefaults().stringForKey("userID") {
          return "participant/view/userid/\(user)"
        }
        return nil
      }
    }
  let prospectName = "Name"
  let calNotifier = CalendarNotification()
  var allProspects = [[String: AnyObject]]()
  var allProspectsCopy = [[String: AnyObject]]()
  private let concurrentUpdateAllPropspects = dispatch_queue_create(
        "com.synerzip.PreSalesHuddle.updateAllProspects", DISPATCH_QUEUE_SERIAL)
  
  
  @IBAction func logout(sender: UIBarButtonItem) {
    dismissViewControllerAnimated(true, completion: nil)
  }

  // MARK: View Functions
  
  override func viewDidLoad() {
    super.viewDidLoad()
    stylizeControls()
    self.refreshControl = UIRefreshControl()
    self.refreshControl?.backgroundColor = Theme.Prospects.RefreshControlBackground
    self.refreshControl?.tintColor = Theme.Prospects.RefreshControl
    self.refreshControl?.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
  }
  
  func refresh(sender:AnyObject) {
    fetchData()
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    accessControl()
    fetchData()
  }

  // MARK: tableView Functions
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return allProspects.count
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCellWithIdentifier("prospect-id") as! UITableViewCell
    let prospect = allProspects[indexPath.row] as [String: AnyObject]
    populateCellData(cell, withProspectDictionary: prospect)
    stylizeCell(cell, index: indexPath.row)
    return cell
  }

  override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
    if indexPath.row ==  (tableView.indexPathsForVisibleRows() as! [NSIndexPath]).last?.row {
      setBadgeIcon()
    }
  }
  
  
  // MARK: Internal Functions
  
  private func showNoData() {
    let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: view.bounds.size.height))    
    messageLabel.text = "No data is currently available. Please pull down to refresh."
    messageLabel.textColor = UIColor.blackColor()
    messageLabel.numberOfLines = 0;
    messageLabel.textAlignment = NSTextAlignment.Center
    messageLabel.font = UIFont(name: "Palatino-Italic", size: 16)
    messageLabel.sizeToFit()
  
    self.tableView.backgroundView = messageLabel;
  
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
  
  private func accessControl() {
    if let userRole = NSUserDefaults.standardUserDefaults().stringForKey("userRole") {
      if userRole == "User" {
        AddButton.enabled = false
      }
    }
  }
  
  private func configureCellDetailText(cell: UITableViewCell, prospect: [String: AnyObject]) {
    if let userRole = NSUserDefaults.standardUserDefaults().stringForKey("userRole") {
      if userRole == "Sales" {
        let startDate = prospect["ConfDateStart"] as! String
        let endDate = prospect["ConfDateEnd"] as! String
        if startDate.isEmpty || endDate.isEmpty {
          cell.detailTextLabel!.text = "Conference call NOT scheduled"
          cell.detailTextLabel!.textColor = Theme.Prospects.detailTextSecond
          unScheduledProspect = unScheduledProspect + 1
        } else {
          cell.detailTextLabel!.text = "Conference call scheduled"
          cell.detailTextLabel!.textColor = Theme.Prospects.detailText
        }
      } else {
        cell.detailTextLabel!.text = prospect["TechStack"] as? String
        cell.detailTextLabel!.textColor = Theme.Prospects.detailText
      }
    } else {
      cell.detailTextLabel!.text = ""
    }

  }
  private func populateCellData(cell: UITableViewCell,
    withProspectDictionary prospect: [String: AnyObject]) {
      if let name = prospect[prospectName] as? String {
        cell.textLabel?.text = name
        configureCellDetailText(cell, prospect: prospect)
      }
  }
  
  private func commonHandler() {
    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    dispatch_async(dispatch_get_main_queue()) {
      self.hud?.hide(true, afterDelay: 0.5)
      self.refreshControl?.endRefreshing()
    }
  }

  class func fillData() -> [[String: AnyObject]] {
    let prospect1 = ["ProspectID": 1, "Name":"Emerson","Domain":"Office Documents","DesiredTeamSize":10, "CreateDate":"1439373335.63184","TechStack":"C++, Java","SalesID":"Himanshu","Notes":"Some Notes", "ConfDateStart": "", "ConfDateEnd": ""]
    let prospect2 = ["ProspectID": 2, "Name":"HP","Domain":"IT Services","DesiredTeamSize":14, "CreateDate":"1439373335.63184","TechStack":"C++","SalesID":"Himanshu","Notes":"Some Notes", "ConfDateStart": "1442225434.0", "ConfDateEnd": "1442229047.0" ]
    let prospect3 = ["ProspectID": 3, "Name":"Tesla","Domain":"Automotive","DesiredTeamSize":20, "CreateDate":"1439373335.63184","TechStack":"C++, JavaScript","SalesID":"Himanshu","Notes":"Some Notes", "ConfDateStart": "1442229434.0", "ConfDateEnd": "1442232047.0"]
    
        let prospect4 = ["ProspectID": 4, "Name":"QuickOffice","Domain":"Office Documents","BUHead":"Salil", "CreateDate":"1439373335.63184","TechStack":"C++, Java, JavaScript","SalesID":"Hemant","Notes":"Acquired by Google", "ConfDateStart": "1442229434.0", "ConfDateEnd": "1442232047.0", "TeamSize": 25]

    var allPros = [[String: AnyObject]]()
    allPros.append(prospect1)
    allPros.append(prospect2)
    allPros.append(prospect3)
        allPros.append(prospect4)
    return allPros
  }
  func fetch_success() {
    commonHandler()
    allProspects = [[String: AnyObject]]()
    
    for dict in AllProspects.fillData()  {
      if let teamSize = dict["TeamSize"] as? Int {

      } else {
        allProspects.append(dict)
      }
    }
    
    dispatch_async(concurrentUpdateAllPropspects) {
      self.allProspectsCopy = self.allProspects
      self.addCalendarInvites()
    }
    dispatch_async(dispatch_get_main_queue()) {
      if self.allProspects.count == 0 {
        self.showNoData()
      } else {
        self.tableView.backgroundView = nil
      }
      self.tableView.reloadData()
    }
  }
  
  private func setBadgeIcon() {
    let notificationSettings = UIUserNotificationSettings(forTypes: .Badge, categories: nil)
    UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
    var badgeValue = 0
    if let userRole = NSUserDefaults.standardUserDefaults().stringForKey("userRole") {
      if userRole == "Sales" {
        badgeValue = unScheduledProspect
      }
    }
    let localNotification = UILocalNotification()
    localNotification.applicationIconBadgeNumber = badgeValue
    UIApplication.sharedApplication().scheduleLocalNotification(localNotification)


  }
  
  private func fetch_success_notifications() -> Void {
    commonHandler()
    var error: NSError?
    var addNotificatios = [Int]()
    
    if let user = NSUserDefaults.standardUserDefaults().stringForKey("userID") {
        
//        if let dict_array = NSJSONSerialization.JSONObjectWithData(data,
//            options: NSJSONReadingOptions.MutableContainers, error: &error) as? [AnyObject] {
//          for item in dict_array  {
//            let included = item["Included"] as! String
//            let participation = item["Participation"] as! String
//            if included == "Yes" && participation == "Yes" {
//              addNotificatios += [item["ProspectID"] as! Int]
//            }
//          }
//        }
        addNotificatios = [1, 2, 3]
        var events: String = ""
        for prospect in allProspectsCopy {
          let prospectID = prospect["ProspectID"] as! Int
          let confEndDate = prospect["ConfDateEnd"] as! String
          let confStartDate = prospect["ConfDateStart"] as! String
          let salesID = prospect["SalesID"] as! String
          if (contains(addNotificatios, prospectID) || salesID == user) && !confEndDate.isEmpty
              && !confStartDate.isEmpty {
              // need to add notification for this
              let sd = DateHandler.getNSDate(confStartDate)
              let ed = DateHandler.getNSDate(confEndDate)
              let title = (prospect["Name"] as! String) + " - " + user + " - Prospect Call" 
              if calNotifier.addEntry(prospectID, title: title, startDate: sd, endDate: ed) {
              events += title + "\n"
            }
          }
        }
      if !events.isEmpty {
        dispatch_async(dispatch_get_main_queue()) {
          let hudMessage = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
          hudMessage.mode = MBProgressHUDMode.Text
          hudMessage.labelText = "Updated Calendar entries"
          hudMessage.labelFont = UIFont.systemFontOfSize(14)
          hudMessage.detailsLabelText = events
          hudMessage.detailsLabelFont = UIFont.systemFontOfSize(12)
          hudMessage.sizeToFit()
          hudMessage.hide(true, afterDelay: 2)
          hudMessage.opacity = 0.4
          hudMessage.yOffset = Float(self.view.frame.size.height/2 - 200)
          hudMessage.userInteractionEnabled = false
        }
      }
    }
  }
  
  private func addCalendarInvites() {
    fetch_success_notifications()
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
    let action = UIAlertAction(title: "Ok", style: .Default, handler: nil)
    alert.addAction(action)
    presentViewController(alert, animated: true, completion: nil)
  }

  private func fetchData() {
    unScheduledProspect = 0
    dispatch_async(dispatch_get_main_queue()) {
      self.hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
      self.hud?.labelText = "Loading.."
      self.hud?.detailsLabelText = "Delay added for display"
    }
    fetch_success()
  }
  
  private func stylizeControls() {
    navigationController?.navigationBar.backgroundColor = Theme.Prospects.navBarBG
    tableView.separatorColor = Theme.Prospects.tableViewSeparator
    tableView.backgroundColor = Theme.Prospects.cellBGOddCell
  }
  
  // MARK: Segue Functions
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    let targetController = segue.destinationViewController as! UINavigationController
    let targetView = targetController.topViewController as! Prospect
    targetView.delegate = self
    if segue.identifier == "EditProspect" {
      if let indexPath = tableView.indexPathForCell(sender as! UITableViewCell) {
        targetView.itemToEdit = allProspects[indexPath.row]
      }
    } else if segue.identifier == "AddProspect" {
      // Add Prospect operation required
    }
  }
// MARK: Delegate Methods
  func saveProspectFinish(name: String) {
    dispatch_async(dispatch_get_main_queue()) {
      let hudMessage = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
      hudMessage.mode = MBProgressHUDMode.Text
      hudMessage.labelText = "Saved: \(name)"
      hudMessage.hide(true, afterDelay: 1.5)
      hudMessage.opacity = 0.4
      hudMessage.yOffset = Float(self.view.frame.size.height/2 - 150)
    }
    dismissViewControllerAnimated(true, completion: nil)
  }
}
