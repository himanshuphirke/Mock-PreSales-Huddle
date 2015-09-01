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

  var rowTapped = -1
  var indexTapped: NSIndexPath?
  // MARK: Outlets
  
  var contextMenu = ["Update prospect", "Schedule prep call", "Schedule client call ", "Setup follow-up reminders", "Dead prospect", "Contract signed"]
  
  let contextMenuRowHeight:CGFloat = 30
  
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
    GIDSignIn.sharedInstance().signOut()
    dismissViewControllerAnimated(true, completion: nil)
  }
  


  @IBAction func longTapped(sender: UILongPressGestureRecognizer) {
    if sender.state != UIGestureRecognizerState.Ended {
      return
    }

    let pt = sender.locationInView(self.tableView)
    let index = self.tableView.indexPathForRowAtPoint(pt)
    
    if index == nil {
      // Tapped outside table rows
      return
    }
    tableView.selectRowAtIndexPath(index, animated: true, scrollPosition: UITableViewScrollPosition.Top)
    let cell = tableView.cellForRowAtIndexPath(index!)
    cell?.contentView.backgroundColor = UIColor(red: 0.992, green: 0.757, blue: 0.176, alpha: 1.00)
    indexTapped = index
    rowTapped = index!.row
    let trans = UIView(frame: self.view.frame)
    trans.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
    trans.tag = 25
    let tap = UITapGestureRecognizer(target: self, action: "dismissTransView:")
    trans.addGestureRecognizer(tap)
    self.view.addSubview(trans)
    
    let frm = CGRectMake(0, 0, 0, 0)
    
    let contextTableView = UITableView(frame: frm , style: UITableViewStyle.Plain)
    contextTableView.scrollEnabled = false
    contextTableView.delegate = self
    contextTableView.dataSource = self
    contextTableView.tag = 20
    self.view.addSubview(contextTableView)
    UIView.animateWithDuration(0.3, animations: {
      contextTableView.frame = CGRectMake(0, 0, 210, CGFloat(self.contextMenu.count) * self.contextMenuRowHeight)
      })
    contextTableView.center = self.view.center
  }
  
  
  
  func searchBarResultsListButtonClicked(searchBar: UISearchBar) {
    
  }
  // MARK: View Functions
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // stylizeControls()
//    self.refreshControl = UIRefreshControl()
//    self.refreshControl?.backgroundColor = Theme.Prospects.RefreshControlBackground
//    self.refreshControl?.tintColor = Theme.Prospects.RefreshControl
//    self.refreshControl?.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)

  }
  
  func refresh(sender:AnyObject) {
    fetchData()
  }
  
  func dismissTransView(sender: AnyObject) {
    dismissContextMenu()
  }
  
  func dismissContextMenu() {
    if let indexTapped = indexTapped {
      tableView.deselectRowAtIndexPath(indexTapped, animated: true)
    }
    let tabView = self.view.viewWithTag(20)
    tabView?.removeFromSuperview()

    let trans = self.view.viewWithTag(25)
    trans?.removeFromSuperview()
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
//    UIView.animateWithDuration(0.3, animations: {
//      self.tabBarController?.tabBar.hidden = false
//    })

    accessControl()
    fetchData()
  }
  
  // MARK: tableView Functions
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if tableView == self.tableView {
      var rows = allProspects.count
      if isFiltered == true {
        rows = filteredProspects.count
      }

      let item =  self.tabBarController?.tabBar.items as! [UITabBarItem]
      item[0].badgeValue = "1"
      return rows
    } else {
      return contextMenu.count
    }
  }
  
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    if tableView != self.tableView {
      return contextMenuRowHeight
    }
    return 44
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
//     let cell = tableView.dequeueReusableCellWithIdentifier("prospect-id") as! UITableViewCell
    if tableView == self.tableView {
      let cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "prospect-id")
      cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
      var prospect = [String: AnyObject]()
      if isFiltered == true {
        prospect = filteredProspects[indexPath.row] as [String: AnyObject]
      } else {
        prospect = allProspects[indexPath.row] as [String: AnyObject]
      }
      populateCellData(cell, withProspectDictionary: prospect)
      configureCellDetailText(cell, prospect: prospect, index: indexPath)
      // stylizeCell(cell, index: indexPath.row)
      return cell
    } else {
      let cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "context-id")
      cell.textLabel?.text = contextMenu[indexPath.row]
      cell.textLabel?.font = UIFont.systemFontOfSize(14)

      return cell
    }
  }

  func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
    if indexPath.row ==  (tableView.indexPathsForVisibleRows() as! [NSIndexPath]).last?.row {
      setBadgeIcon()
    }
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    if tableView == self.tableView {
      performSegueWithIdentifier("EditProspect", sender: tableView.cellForRowAtIndexPath(indexPath))
      tableView.deselectRowAtIndexPath(indexPath, animated: true)
    } else {
      // Steps to perform when menu is clicked
      switch indexPath.row {
        case 0:
          performSegueWithIdentifier("EditProspect", sender: self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: rowTapped, inSection: 0)))
        case 1:
          let prospectID = allProspects[rowTapped]["ProspectID"] as! Int
          let name = allProspects[rowTapped]["Name"] as! String
          let idAndType = TupleWrapperSceduleCall(tuple: (prospectID, "Prep", name, allProspects[rowTapped]))
          performSegueWithIdentifier("ContextMenuScheduleCall", sender: idAndType)

        case 2:
          let prospectID = allProspects[rowTapped]["ProspectID"] as! Int
          let name = allProspects[rowTapped]["Name"] as! String
          let idAndType = TupleWrapperSceduleCall(tuple: (prospectID, "Client", name, allProspects[rowTapped]))
          performSegueWithIdentifier("ContextMenuScheduleCall", sender: idAndType)

        case 3:
          remindNDay()
        
        case 4:
          performSegueWithIdentifier("ContextDeadProspect", sender: self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: rowTapped, inSection: 0)))

        case 5:
          let prospectID = allProspects[rowTapped]["ProspectID"] as! Int
          let name = allProspects[rowTapped]["Name"] as! String
          let idAndName = TupleWrapper(tuple: (prospectID, name))
          performSegueWithIdentifier("ContextConvertToClient", sender: idAndName)

        default:
        println("Unsupported menu clicked")
      }
      tableView.deselectRowAtIndexPath(indexPath, animated: true)
      dismissContextMenu()
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
    
    let unread = UILabel(frame: CGRectMake(frame.width - 145, 8,60,30))
    unread.text = prospect["Unread"] as? String
    unread.font = UIFont(name: "Palatino", size: 11)
    unread.textColor = UIColor.brownColor()
    unread.sizeToFit()
    cell.contentView.addSubview(unread)
    
    let participants = UILabel(frame: CGRectMake(frame.width - 145, 26,60,30))
    participants.text = prospect["Participants"] as? String
    participants.font = UIFont(name: "Palatino", size: 11)
    participants.sizeToFit()
    participants.textColor = UIColor.blackColor()
    cell.contentView.addSubview(participants)
    
  }
  
  private func configureCellImage(cell: UITableViewCell, prospect: [String: AnyObject]) {
    if let name = prospect["PinStatus"] as? String {
      if name == "Pin" {
        let iconImage = UIImageView(frame: CGRectMake(tableView.frame.width - 170,cell.frame.height / 2 - 10,20,20))
        iconImage.image = UIImage(named: "pin")
        cell.contentView.addSubview(iconImage)
      }
    }
    
    if let name = prospect["CallStatus"] as? String {
        let iconImage = UIImageView(frame: CGRectMake(tableView.frame.width - 60, cell.frame.height / 2 - 10,20,20))
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
    let prospect1 = ["ProspectID": 1, "Name":"Emerson","Domain":"Office Documents","DesiredTeamSize":10, "CreateDate":"1439373335.63184","TechStack":"C++, Java","SalesID":"Himanshu","Notes":"Looking to replace Microsoft office with LibreOffice", "ConfDateStart": "", "ConfDateEnd": "", "CallStatus": "call-green", "Unread": "8 unread replies","Participants" : "2 participants",     "DesiredTeamDesc": "6 Dev & 4 QA", "ListOfContacts": "Dave - VP Engineering"]
    
    let prospect2 = ["ProspectID": 2, "Name":"HP","Domain":"IT Services","DesiredTeamSize":14, "CreateDate":"1439373335.63184","TechStack":"Linux, Python","SalesID":"Himanshu","Notes":"IT MNC Giant", "ConfDateStart": "1442225434.0", "ConfDateEnd": "1442229047.0","PinStatus":"Pin", "CallStatus": "call-yellow", "Unread": "3 unread replies","Participants" : "5 participants", "DesiredTeamDesc": "6 Dev, 4 Dev Ops & 4 QA", "ListOfContacts": "Harry - VP Product Management"]
    
    let prospect3 = ["ProspectID": 3, "Name":"Tesla","Domain":"Automotive","DesiredTeamSize":5, "CreateDate":"1439373335.63184","TechStack":"C++, JavaScript","SalesID":"Himanshu","Notes":"Innovative Company", "ConfDateStart": "1442229434.0", "ConfDateEnd": "1442232047.0", "CallStatus": "call-red", "Unread": "2 unread replies","Participants" : "3 participants", "DesiredTeamDesc": "2 Dev, 1 Dev Ops & 1 QA", "ListOfContacts": "Mike - CTO"]
    
    let prospect4 = ["ProspectID": 4, "Name":"QuickOffice","Domain":"Office Documents","BUHead":"Salil", "CreateDate":"1439373335.63184","TechStack":"C++, Java, JavaScript","SalesID":"Hemant","Notes":"Acquired by Google", "ConfDateStart": "1442229434.0", "ConfDateEnd": "1442232047.0", "TeamSize": 25]
    
    
    let prospect5 = ["ProspectID": 5, "Name":"ChaiOne","Domain":"Oil & Gas industry", "CreateDate":"1439373335.63184","TechStack":"Ruby on Rails, PostGreSQL, iOS, Android","SalesID":"Ashish","Notes":"Team is in Houston and another in Austin (focused on UX)", "ConfDateStart": "", "ConfDateEnd": "", "TeamSize": 0, "Status": "Dead"]

    var allPros = [[String: AnyObject]]()
    allPros.append(prospect1)
    allPros.append(prospect2)
    allPros.append(prospect3)
    allPros.append(prospect4)
    allPros.append(prospect5)
    return allPros
  }
  func fetch_success() {
    commonHandler()
    allProspects = [[String: AnyObject]]()
    
    unScheduledProspect = 1
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
//          let hudMessage = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
//          hudMessage.mode = MBProgressHUDMode.Text
//          hudMessage.labelText = "Updated Calendar entries"
//          hudMessage.labelFont = UIFont.systemFontOfSize(14)
//          hudMessage.detailsLabelText = events
//          hudMessage.detailsLabelFont = UIFont.systemFontOfSize(12)
//          hudMessage.sizeToFit()
//          hudMessage.hide(true, afterDelay: 0.5)
//          hudMessage.opacity = 0.4
//          hudMessage.yOffset = Float(self.view.frame.size.height/2 - 200)
//          hudMessage.userInteractionEnabled = false
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
  
  private func remindNDay() {
    let alert = UIAlertController(title: "Remind every N Days", message: "", preferredStyle: UIAlertControllerStyle.Alert)
    alert.addTextFieldWithConfigurationHandler { (textField: UITextField!) -> Void in
      textField.placeholder = "Frequency in days"
    }
    let defaultAction = UIAlertAction(title: "Submit", style: .Default, handler: {
      (action:UIAlertAction!) -> Void in
      if let frequency = alert.textFields?.first as? UITextField {
        let hudMessage = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        hudMessage.mode = MBProgressHUDMode.Text
        hudMessage.labelText = "Alert will be sent every \(frequency.text) days."
        hudMessage.hide(true, afterDelay: 1.5)
        hudMessage.opacity = 0.25
        hudMessage.yOffset = Float(self.view.frame.size.height/2 - 100)
      }
    })
    let cancelAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
    
    alert.addAction(cancelAction)
    alert.addAction(defaultAction)
    presentViewController(alert, animated: true, completion: {

    })
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
      self.hud?.labelText = "Loading"
      self.hud?.detailsLabelText = "Please wait.."
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
    // self.tabBarController?.tabBar.hidden = true
    if segue.identifier == "EditProspect" {
      let targetView = segue.destinationViewController as! Prospect
      targetView.delegate = self
      if let indexPath = tableView.indexPathForCell(sender as! UITableViewCell) {
        targetView.itemToEdit = allProspects[indexPath.row]
      }
    } else if segue.identifier == "AddProspect"{
      let targetView = segue.destinationViewController as! Prospect
      targetView.delegate = self      
    } else if segue.identifier == "ContextMenuScheduleCall" {
      let s = sender as! TupleWrapperSceduleCall
      let targetView = segue.destinationViewController as! ScheduleCall
      targetView.title = "Schedule a \(s.tuple.data) Call"
      targetView.prospectID = s.tuple.id
      targetView.mockProspectData = ["Type": s.tuple.data,
        "ProspectName":s.tuple.prospectName, "Prospect":s.tuple.prospect]
    } else if segue.identifier == "ContextSetupReminders" {

    } else if segue.identifier == "ContextDeadProspect" {
      let targetView = segue.destinationViewController as! Prospect
      targetView.delegate = self
      if let indexPath = tableView.indexPathForCell(sender as! UITableViewCell) {
        targetView.itemToEdit = allProspects[indexPath.row]
      }
      targetView.isDead = true
    } else if segue.identifier == "ContextConvertToClient" {
      let s = sender as! TupleWrapper
      let targetView = segue.destinationViewController as! ConvertClient
      targetView.prospectID = s.tuple.id
      targetView.prospectName = s.tuple.data
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
  }
  
  @IBAction func segmentClicked(sender: UISegmentedControl) {
    isFiltered = false
    searchBar.text = ""
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
