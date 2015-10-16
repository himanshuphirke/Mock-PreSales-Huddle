//
//  AllDead.swift
//  PreSales-Huddle
//
//  Created by Himanshu Phirke on 31/08/15.
//  Copyright (c) 2015 synerzip. All rights reserved.
//

import UIKit

class AllDead: UITableViewController {
  var deadClients = [[String: AnyObject]]()

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    deadClients = []
    for dict in AllProspects.fillData()  {
      if let status = dict["Status"] as? String {
        if status == "Dead" {
          deadClients.append(dict)
        }
      }
    }
  }
  
  @IBAction func logout(sender: UIBarButtonItem) {
    GIDSignIn.sharedInstance().signOut()
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//    let item =  self.tabBarController?.tabBar.items as! [UITabBarItem]
//    item[3].badgeValue = "\(deadClients.count)"
    return deadClients.count
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCellWithIdentifier("dead") {
      let client = deadClients[indexPath.row] as [String: AnyObject]
      populateCellData(cell, withProspectDictionary: client)
      return cell
    } else {
      return UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "dead")
    }
  }
  
  private func populateCellData(cell: UITableViewCell,
    withProspectDictionary client: [String: AnyObject]) {
      if let name = client["Name"] as? String {
        cell.textLabel?.text = name
        cell.textLabel?.textColor = UIColor.grayColor()
      }
  }
  // MARK: Segue Functions
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    let targetView = segue.destinationViewController as! DeadProspect
    if segue.identifier == "deadDetails" {
      if let indexPath = tableView.indexPathForCell(sender as! UITableViewCell) {
        targetView.itemToView = deadClients[indexPath.row]
      }
    }
  }
}
