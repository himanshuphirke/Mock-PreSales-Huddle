//
//  AllProspectsViewController.swift
//  PreSales-Huddle
//
//  Created by Himanshu Phirke on 22/07/15.
//  Copyright (c) 2015 synerzip. All rights reserved.
//

import UIKit
class AllProspects: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate ,ProspectDelgate {
  enum PinStatus {
    case Pin
    case UnPin
    case All
  }
  var hud:MBProgressHUD?
  var unScheduledProspect = 0
  var currentTab = PinStatus.All
  // MARK: Outlets
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var AddButton: UIBarButtonItem!
  @IBOutlet weak var segmentedControl: UISegmentedControl!
  
  @IBOutlet weak var searchBar: UISearchBar!
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
  var filteredProspects = [[String: AnyObject]]()
  var isFiltered = false
  var allProspectsCopy = [[String: AnyObject]]()
  private let concurrentUpdateAllPropspects = dispatch_queue_create(
        "com.synerzip.PreSalesHuddle.updateAllProspects", DISPATCH_QUEUE_SERIAL)
  
  
  @IBAction func logout(sender: UIBarButtonItem) {
    dismissViewControllerAnimated(true, completion: nil)
  }

  @IBAction func longTapped(sender: UILongPressGestureRecognizer) {
    if sender.state != UIGestureRecognizerState.Ended {
      return
    }

    let pt = sender.locationInView(self.tableView)
    let index = self.tableView.indexPathForRowAtPoint(pt)

    let trans = UIView()
    trans.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
    trans.frame = self.view.frame
    trans.tag = 25
    let tap = UITapGestureRecognizer(target: self, action: "dismissTransView:")
    trans.addGestureRecognizer(tap)
    self.view.addSubview(trans)
    
  }
  
  func searchBarResultsListButtonClicked(searchBar: UISearchBar) {
    
  }
  // MARK: View Functions
  
  override func viewDidLoad() {
    super.viewDidLoad()
    stylizeControls()
//    self.refreshControl = UIRefreshControl()
//    self.refreshControl?.backgroundColor = Theme.Prospects.RefreshControlBackground
//    self.refreshControl?.tintColor = Theme.Prospects.RefreshControl
//    self.refreshControl?.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
  }
  
  func refresh(sender:AnyObject) {
    fetchData()
  }
  
  func dismissTransView(sender: AnyObject) {
    let trans = self.view.viewWithTag(25)
    trans?.removeFromSuperview()
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    accessControl()
    fetchData()
  }

  // MARK: tableView Functions
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    var rows = allProspects.count
    if isFiltered == true {
      rows = filteredProspects.count
    }
    return rows
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
//     let cell = tableView.dequeueReusableCellWithIdentifier("prospect-id") as! UITableViewCell
    let cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "prospect-id")
    cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
    var prospect = allProspects[indexPath.row] as [String: AnyObject]
    if isFiltered == true {
      prospect = filteredProspects[indexPath.row] as [String: AnyObject]
    }
    populateCellData(cell, withProspectDictionary: prospect)
    configureCellDetailText(cell, prospect: prospect, index: indexPath)
    stylizeCell(cell, index: indexPath.row)
    return cell
  }

  func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
    if indexPath.row ==  (tableView.indexPathsForVisibleRows() as! [NSIndexPath]).last?.row {
      setBadgeIcon()
    }
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    performSegueWithIdentifier("EditProspect", sender: tableView.cellForRowAtIndexPath(indexPath))
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
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

    tableView.backgroundView = messageLabel;
  
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
  
  private func configureCellDetailText(cell: UITableViewCell, prospect: [String: AnyObject], index: NSIndexPath) {
    
    let frame = tableView.rectForRowAtIndexPath(index)
    
    cell.detailTextLabel!.text = prospect["TechStack"] as? String
    cell.detailTextLabel!.textColor = Theme.Prospects.detailText
    let unread = UILabel(frame: CGRectMake(frame.width - 130, 8,60,30))
    unread.text = prospect["Unread"] as? String
    unread.font = UIFont(name: "Palatino-Italic", size: 10)
    unread.textColor = Theme.Prospects.detailText
    unread.sizeToFit()
    cell.contentView.addSubview(unread)
    
    let participants = UILabel(frame: CGRectMake(frame.width - 130, 26,60,30))
    participants.text = prospect["Participants"] as? String
    participants.font = UIFont(name: "Palatino-Italic", size: 10)
    participants.sizeToFit()
    participants.textColor = Theme.Prospects.detailText
    cell.contentView.addSubview(participants)
    
  }
  
  private func configureCellImage(cell: UITableViewCell, prospect: [String: AnyObject]) {
    if let name = prospect["PinStatus"] as? String {
      if name == "Pin" {
        let iconImage = UIImageView(frame: CGRectMake(tableView.frame.width - 170,4,30,30))
        iconImage.image = UIImage(named: "pin")
        cell.contentView.addSubview(iconImage)
      }
    }
    
    if let name = prospect["CallStatus"] as? String {
        let iconImage = UIImageView(frame: CGRectMake(tableView.frame.width - 60,6,30,30))
        iconImage.image = UIImage(named: name)
        cell.contentView.addSubview(iconImage)
    }


  }
  private func populateCellData(cell: UITableViewCell,
    withProspectDictionary prospect: [String: AnyObject]) {
      if let name = prospect[prospectName] as? String {
        cell.textLabel?.text = name
        configureCellImage(cell, prospect: prospect)
      }
  }
  
  private func commonHandler() {
    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    dispatch_async(dispatch_get_main_queue()) {
      self.hud?.hide(true, afterDelay: 0.5)
//      self.refreshControl?.endRefreshing()
    }
  }

  class func fillData() -> [[String: AnyObject]] {
    let prospect1 = ["ProspectID": 1, "Name":"Emerson","Domain":"Office Documents","DesiredTeamSize":10, "CreateDate":"1439373335.63184","TechStack":"C++, Java","SalesID":"Himanshu","Notes":"Some Notes", "ConfDateStart": "", "ConfDateEnd": "", "CallStatus": "call-green", "Unread": "8 unread replies","Participants" : "2 participants",     "DesiredTeamDesc": "6 Dev & 4 QA", "ListOfContacts": "Dave - VP Engineering"]
    
    let prospect2 = ["ProspectID": 2, "Name":"HP","Domain":"IT Services","DesiredTeamSize":14, "CreateDate":"1439373335.63184","TechStack":"Linux, Python","SalesID":"Himanshu","Notes":"Some Notes", "ConfDateStart": "1442225434.0", "ConfDateEnd": "1442229047.0","PinStatus":"Pin", "CallStatus": "call-yellow", "Unread": "3 unread replies","Participants" : "5 participants", "DesiredTeamDesc": "6 Dev, 4 Dev Ops & 4 QA", "ListOfContacts": "Harry - VP Product Management"]
    
    let prospect3 = ["ProspectID": 3, "Name":"Tesla","Domain":"Automotive","DesiredTeamSize":5, "CreateDate":"1439373335.63184","TechStack":"C++, JavaScript","SalesID":"Himanshu","Notes":"Some Notes", "ConfDateStart": "1442229434.0", "ConfDateEnd": "1442232047.0", "CallStatus": "call-red", "Unread": "2 unread replies","Participants" : "3 participants",     "DesiredTeamDesc": "2 Dev, 1 Dev Ops & 1 QA", "ListOfContacts": "John - CTO"]
    
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
        if currentTab == PinStatus.All {
          allProspects.append(dict)
        } else {
          if let name = dict["PinStatus"] as? String {
            if name == "Pin" && currentTab == PinStatus.Pin{
              allProspects.append(dict)
            }
          } else {
            if (currentTab == PinStatus.UnPin ){
              allProspects.append(dict)
            }
          }
        }

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
          hudMessage.hide(true, afterDelay: 0.5)
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
    view.backgroundColor = Theme.Prospects.cellBGOddCell
    segmentedControl.tintColor = Theme.Prospects.cellBGEvenCell
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
  
  @IBAction func segmentClicked(sender: UISegmentedControl) {
    switch(sender.selectedSegmentIndex) {
    case 0:
      currentTab = PinStatus.All
    case 1:
      currentTab = PinStatus.Pin
    case 2:
      currentTab = PinStatus.UnPin
    default:
      println("unsupported tab clicked")
    }
    fetchData()
    tableView.reloadData()
  }
  
  func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
    if count(searchText) == 0 {
      isFiltered = false
    } else {
      isFiltered = true
      filteredProspects = [[String: AnyObject]]()
      for prospect in allProspects {
        let techStack = prospect["TechStack"] as! NSString
        let domain = prospect["Domain"] as! NSString
        let name = prospect["Name"] as! NSString
        
        let t = techStack.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch)
        let d = domain.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch)
        let n = name.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch)
        
        if t.location != NSNotFound || d.location != NSNotFound || n.location != NSNotFound {
          filteredProspects.append(prospect)
        }
      }
    }
    tableView.reloadData()
  }

// Mark: Segment
}
