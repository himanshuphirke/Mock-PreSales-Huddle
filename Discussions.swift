//
//  Discussions.swift
//  PreSales-Huddle
//
//  Created by Vinaya Mandke on 22/07/15.
//  Copyright (c) 2015 synerzip. All rights reserved.
//

import UIKit

class Discussions: UITableViewController {
    
    
    // MARK: Class variables
    var prospectID = -1 {
        didSet {
            fetchData()
        }
    }

    var imgData:NSData?
    let viewAllQA = "discussion/view/prospectid/"
    let updateQA = "discussion/update/"
    let addQURL = "discussion/add/"
    var tableData = [String]();
    var allQAs = [[String: AnyObject]]() {
        //for mock screens
        didSet {
            if var lastDiscussion = allQAs.last {
                if lastDiscussion["DiscussionID"] == nil {
                    lastDiscussion["DiscussionID"] = 60 + allQAs.count
                    lastDiscussion["UserID"] = currentUserEmail
                    allQAs.removeLast()
                    allQAs.append(lastDiscussion)
                }
            }
        }
    }

    var currentUser:GIDGoogleUser! {
        return GIDSignIn.sharedInstance().currentUser
    }

    var currentUserEmail:String {
        let user = currentUser
        return user.profile.email
    }
    var cachedAnswers = [Int: String]()
    var arrayForBool = [Bool]()
    
    override func viewDidLoad() {

        // get user's profile pic
        let user = currentUser
        if(user.profile.hasImage) {
            let imgURL = user.profile.imageURLWithDimension(35)
            if let data = NSData(contentsOfURL: imgURL) {
                imgData = data
            }
        }

        super.viewDidLoad()
        tableView.scrollEnabled = true
        tableView.bounces = false
        stylize()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func addAQuestion(sender: UIBarButtonItem) {
        cacheAnswers()
        let alert = UIAlertController(title: "Ask a Question", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addTextFieldWithConfigurationHandler { (textField: UITextField!) -> Void in
            textField.placeholder = "Enter a Question"
        }
        let defaultAction = UIAlertAction(title: "Submit", style: .Default, handler: { (action:UIAlertAction) -> Void in
            if let questionField = alert.textFields?.first {
                let question = questionField.text
                
                // Take user id from NSDefaults; currently defaulting to "USER1"
                var userID = "Unknown"
                if let id = NSUserDefaults.standardUserDefaults().stringForKey("userID") {
                    userID = id
                }
                let dataStore : [String:AnyObject] = ["UserID": userID, "ProspectID": self.prospectID,"Query":"\(question)", "Answer": [[String:AnyObject]]()]
                //for mock-screens
                self.allQAs.append(dataStore)
                
                //for mock screens reload tableview
                self.fetchData()
            }
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
        
        alert.addAction(cancelAction)
        alert.addAction(defaultAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return allQAs.count
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        
        if(arrayForBool.count > section && arrayForBool[section])
        {
            if allQAs.count > section {
                let qa = allQAs[section] as [String: AnyObject]
                if let ans = qa["Answer"] as? [[String:AnyObject]] {
                    return ans.count + 1
                }
                
            }
        }
        return 0;
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Height for table cell is predetermined
        // try and calculate it here:-
        if allQAs.count > section {
            let qa = allQAs[section] as [String: AnyObject]
            if let query = qa["Query"] as? String {
                let attrs = [NSFontAttributeName:UIFont.systemFontOfSize(UIFont.systemFontSize())]
                let size = (query as NSString).sizeWithAttributes(attrs)
                return size.height + 40
            }
        }
        return UITableViewAutomaticDimension
        //        return 50
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if(arrayForBool[indexPath.section]){
            // Height for table cell is predetermined
            // try and calculate it here:-
            
            //hard-coded for mock-screens
            return 90
            
        }
        
        return 1;
    }
    
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let hVWidth = tableView.frame.size.width
        let hvHeight =  CGFloat(40)
        
        let headerView = UIView(frame: CGRectMake(0, 0, hVWidth, hvHeight))
        headerView.backgroundColor = Appearance.tableheaderBG
        headerView.tag = section
        
        let headerString = UILabel(frame: CGRect(x: 60, y: 15, width: hVWidth-50, height: hvHeight - 10)) as UILabel
        if allQAs.count > section {
            let qa = allQAs[section] as [String: AnyObject]
            if let query = qa["Query"] as? String {
                headerString.text = query
                headerString.textColor = UIColor.brownColor()
                let userid = qa["UserID"] as! String
                headerView.addSubview(getprofilePic(userid, frame: CGRect(x: 10, y: 15, width: 35, height: 35)))
            }
            if let answer = qa["Answer"] as? [[String:AnyObject]] {
                if answer.isEmpty {
                    let unansweredLabel = UILabel(frame: CGRectMake(60, 0, 75, 15))
                    unansweredLabel.text = "Unanswered"
                    unansweredLabel.textColor = UIColor.redColor()
                    unansweredLabel.font = UIFont.systemFontOfSize(10)
                    headerView.addSubview(unansweredLabel)
                }
            }
        }
        headerView.addSubview(headerString)
        
        let headerTapped = UITapGestureRecognizer (target: self, action:"sectionHeaderTapped:")
        headerView .addGestureRecognizer(headerTapped)
        styleTheView(headerView)
        return headerView
    }
    
    func sectionHeaderTapped(recognizer: UITapGestureRecognizer) {
        cacheAnswers()
        
        let indexPath : NSIndexPath = NSIndexPath(forRow: 0, inSection:(recognizer.view?.tag as Int!)!)
        if (indexPath.row == 0) {
            var collapsed = arrayForBool[indexPath.section]
            collapsed       = !collapsed;
            arrayForBool[indexPath.section] = collapsed
            
            //reload specific section animated
            let range = NSMakeRange(indexPath.section, 1)
            let sectionToReload = NSIndexSet(indexesInRange: range)
            self.tableView.reloadSections(sectionToReload, withRowAnimation:UITableViewRowAnimation.Fade)
        }
        
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let qa = allQAs[indexPath.section] as [String: AnyObject]
        
        //TODO (vinaya.mandke) currently if no ans provided answer is provided as empty string
        if let ans = qa["Answer"] as? [[String:AnyObject]] {
            if ans.count > indexPath.row {
                let query = ans[indexPath.row]
                cell.textLabel?.text = query["data"] as? String
                cell.textLabel?.lineBreakMode = NSLineBreakMode.ByWordWrapping
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.preferredMaxLayoutWidth = tableView.frame.size.width
                cell.textLabel?.sizeToFit()
                if let labelFrame = cell.textLabel?.frame {
                    cell.frame = labelFrame
                }
                cell.sizeToFit()
                cell.textLabel?.textColor = Appearance.textViewTextColor
                let userid = query["UserID"] as! String
                let imageView = getprofilePic(userid, frame: CGRect(x: 10, y: 15, width: 35, height: 35))
                cell.accessoryView = imageView
                
            } else {
                let answerblock = UITextView(frame: CGRect(x: 10, y: 10, width: tableView.frame.size.width-20, height: cell.bounds.height)) as UITextView
                answerblock.layer.borderWidth = 2
                answerblock.layer.borderColor = UIColor.grayColor().CGColor
                answerblock.layer.cornerRadius = 5.0
                let postButton = UIButton(frame: CGRect(x: 10, y: 60, width: 50, height: 20))
                // tag button with section id
                postButton.tag = indexPath.section + 1
                answerblock.tag = indexPath.section + 1
                postButton.setTitle("POST", forState: UIControlState.Normal)
                postButton.backgroundColor = Appearance.tableheaderBG
                postButton.setTitleColor(UIColor.brownColor(), forState: UIControlState.Normal)
                postButton.titleLabel?.font = UIFont.systemFontOfSize(CGFloat(10))
                postButton.layer.cornerRadius = 1.0
                postButton.addTarget(self, action: "postAnswer:", forControlEvents: UIControlEvents.TouchUpInside)
                
                styleTheView(answerblock)
                styleTheView(postButton)
                
                cell.addSubview(answerblock)
                cell.addSubview(postButton)
                cell.sizeToFit()
                
                // try to get cached answer value
                if let discussionID = qa["DiscussionID"] as? Int {
                    if let cachedValue = cachedAnswers[discussionID] {
                        answerblock.text = cachedValue
                        // remove the cached value
                        cachedAnswers[discussionID] = nil
                    }
                }
            }
            
        }
        styleTheView(cell)
        return cell
    }
    
    func postAnswer(sender: UIButton) {
        // POST the answer to API use sender.tag as identifier in allQAs
        NSLog("hello \(sender.tag)")
        let sectionID = sender.tag - 1
        let answerView = tableView.viewWithTag(sender.tag) as? UITextView
        let answer = answerView?.text
        if (answer != nil && !answer!.isEmpty) {
            let alert = UIAlertController(title: "Preview Answer", message: answer!, preferredStyle: UIAlertControllerStyle.Alert)
            
            let submitActionHandler = { (action:UIAlertAction!) -> Void in
                //POST the discussion
                var qa = self.allQAs[sectionID] as [String: AnyObject]
                var allAns = qa["Answer"] as! [[String:AnyObject]]
                // for mock-screens add in qa
                allAns.append(["data":answer!, "UserID":self.currentUserEmail])
                qa["Answer"] = allAns
                self.allQAs[sectionID] = qa
                
                
                let range = NSMakeRange(sectionID, 1)
                let sectionToReload = NSIndexSet(indexesInRange: range)
                dispatch_async(dispatch_get_main_queue()) {
                    var collapsed = self.arrayForBool[sectionID]
                    collapsed       = !collapsed;
                    self.arrayForBool[sectionID] = collapsed
                    self.tableView.reloadSections(sectionToReload, withRowAnimation:UITableViewRowAnimation.Fade)
                }
            }
            
            let defaultAction = UIAlertAction(title: "Submit", style: .Default, handler: submitActionHandler)
            let cancelAction = UIAlertAction(title: "Cancel", style: .Default, handler: {(action:UIAlertAction) -> Void in
                self.cacheAnswers()
                let range = NSMakeRange(sectionID, 1)
                let sectionToReload = NSIndexSet(indexesInRange: range)
                dispatch_async(dispatch_get_main_queue()) {
                    var collapsed = self.arrayForBool[sectionID]
                    collapsed       = !collapsed;
                    self.arrayForBool[sectionID] = collapsed
                    self.tableView.reloadSections(sectionToReload, withRowAnimation:UITableViewRowAnimation.Fade)
                }
            })
            alert.addAction(cancelAction)
            alert.addAction(defaultAction)
            presentViewController(alert, animated: true, completion: nil)
            
        }
    }
    
    private func commonHandler() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    func service_success() -> Void {
        commonHandler()
        // for mock-screens
        let dataToFill = fillData
        allQAs.removeAll(keepCapacity: true)
        for item in dataToFill  {
            let dict = item as [String: AnyObject]
            allQAs.append(dict)
        }
        for _ in (0...allQAs.count-1) {
            arrayForBool.append(false)
        }
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
    }
    
    
    func service_success_post(data: NSData) -> Void {
        commonHandler()
        fetchData()
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
    
    func showMessage(title:String, message: String) {
        let alert = UIAlertController(title: title, message: message,
            preferredStyle: .Alert)
        let action = UIAlertAction(title: "Ok", style: .Default, handler: nil)
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func fetchData() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        service_success()
    }
    
    func postUpdate(dataEncoded: NSData, url: String) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let nc = NetworkCommunication()
        let _ = nc.postData(dataEncoded,
            successHandler: service_success_post,
            serviceErrorHandler: service_error,
            errorHandler: network_error,
            request: nil,
            relativeURL: url)
    }
    
    func cacheAnswers() {
        let count = allQAs.count
        if count > 0 {
            for i in (1...count) {
                let answerView = tableView.viewWithTag(i) as? UITextView
                let answer = answerView?.text
                if (answer != nil && !answer!.isEmpty) {
                    let qa = self.allQAs[i-1] as [String: AnyObject]
                    if let discussionID = qa["DiscussionID"] as? Int {
                        cachedAnswers[discussionID] = answer!
                    }
                }
            }
        }
    }
    
    // MARK: styles
    
    
    struct Appearance {
        static var tintColor = UIColor.grayColor()
        static var backgroundColor = UIColor.whiteColor()
        static var textViewTextColor = UIColor(red: 0.0/255.0, green: 122.0/255.0, blue: 255.0/255.0, alpha: 1.00)
        static var textViewBackgroundColor = UIColor.whiteColor()
        static var tableheaderBG = UIColor(red: 237.0/255.0, green: 247.0/255.0, blue: 250.0/255.0, alpha: 1.00)
    }
    
    func styleTheView(textView: UIView) {
        textView.layer.rasterizationScale = UIScreen.mainScreen().scale
        textView.layer.shouldRasterize = true
        textView.layer.cornerRadius = 5.0
        textView.layer.borderWidth = 1.0
        textView.layer.borderColor = UIColor(white: 0.0, alpha: 0.2).CGColor
    }
    func stylize() {
        tableView.backgroundColor = Appearance.textViewBackgroundColor
        tableView.tintColor = Appearance.tintColor
        tableView.backgroundColor = Appearance.backgroundColor
    }
    
    func getprofilePic(userid: String, frame: CGRect) -> UIImageView {
        let img:UIImage?
        if currentUserEmail == userid {
            img = getprofilePicForMe()
        } else {
            img = UIImage(named: userid)
        }
        let imageView = UIImageView(frame: frame)
        if let profielPic = img {
            imageView.image = profielPic
        }

        // circle
        imageView.layer.borderWidth=1.0
        imageView.layer.masksToBounds = false
        imageView.layer.borderColor = UIColor.whiteColor().CGColor
        imageView.layer.cornerRadius = 13
        imageView.layer.cornerRadius = imageView.frame.size.height/2
        imageView.clipsToBounds = true
        return imageView
    }

    private func getprofilePicForMe() -> UIImage? {
        if let userImage = imgData {
            return UIImage(data: userImage)
        } else {
            return UIImage(named: "Unknown")
        }
    }
    var fillData : [[String: AnyObject]] {
        get {
            if self.allQAs.isEmpty {
              let discussion1:[String : AnyObject] = ["DiscussionID":55,"ProspectID":53,"UserID":"himanshu.phirke@synerzip.com","Query":"What is the expected team size ?","Answer":[["UserID":"himanshu.phirke@synerzip.com","data":"About 20 odd people"], ["UserID":"uttam.gandhi@synerzip.com","data":"Are any QAs required?"]]]
                let discussion2:[String : AnyObject] = ["DiscussionID":56,"ProspectID":53,"UserID":"vinaya.mandke@synerzip.com","Query":"What is the expected start date ?","Answer":[["UserID":"sachin.avhad@synerzip.com","data":"End of this month"]]]
                let discussion3:[String : AnyObject] = ["DiscussionID":57,"ProspectID":53,"UserID":"uttam.gandhi@synerzip.com","Query":"What are the technologies involved ?","Answer":[String]()]
                let discussion4:[String : AnyObject] = ["DiscussionID":58,"ProspectID":53,"UserID":"sachin.avhad@synerzip.com","Query":"Is a webservice required ?","Answer":[["UserID":"himanshu.phirke@synerzip.com","data":"Yes"], ["UserID":"uttam.gandhi@synerzip.com","data":"Using Go?"]]]
                
                var fillData = [[String: AnyObject]]()
                fillData.append(discussion1)
                fillData.append(discussion2)
                fillData.append(discussion3)
                fillData.append(discussion4)
                return fillData
            } else {
                return self.allQAs
            }
            
        }
    }
    
}
