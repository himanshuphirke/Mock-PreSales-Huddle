//
//  DateSelector.swift
//  PreSales-Huddle
//
//  Created by Himanshu Phirke on 27/07/15.
//  Copyright (c) 2015 synerzip. All rights reserved.
//

import UIKit

protocol DateSelectorDelegate{
  func dateSelectorDidFinish(date: NSDate, type: String?)
}
class DateSelector: UIViewController {

  var delegate: DateSelectorDelegate?
  var type: String?
  var pickerType: UIDatePickerMode?
  var senderFrame: CGRect?
  @IBOutlet weak var datePicker: UIDatePicker!
  @IBOutlet weak var toolBar: UIToolbar!

  @IBAction func tapped(sender: UITapGestureRecognizer) {
    animateAndExit()
  }
  override func viewDidLoad() {
      super.viewDidLoad()
      // Do any additional setup after loading the view.
  }
  override func viewWillAppear(animated: Bool) {
    if let pickerType = pickerType {
      datePicker.datePickerMode = pickerType
    }
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    stylizeControls()
  }

  private func stylizeControls() {
    datePicker.backgroundColor = UIColor.whiteColor()
    datePicker.layer.borderWidth = 1.0
    datePicker.layer.cornerRadius = 10.0
    datePicker.layer.borderColor = UIColor.whiteColor().CGColor
    datePicker.layer.masksToBounds = true
    
    
    toolBar.backgroundColor = UIColor.whiteColor()
    toolBar.layer.borderWidth = 1.0
    toolBar.layer.cornerRadius = 10.0
    toolBar.layer.borderColor = UIColor.whiteColor().CGColor
    toolBar.layer.masksToBounds = true
    
    
    if let senderFrame = senderFrame {
      UIView.animateWithDuration(0.4, animations: {
        if let senderFrame = self.senderFrame {
          self.toolBar.frame = CGRectMake(0, senderFrame.origin.y + senderFrame.height + 10,
              self.toolBar.frame.width, self.toolBar.frame.height)
          self.datePicker.frame = CGRectMake(0, self.toolBar.frame.origin.y + self.toolBar.frame.height, 0, 0)
        }
      }, completion: {
        val in
          UIView.animateWithDuration(0.3, animations: {
            self.toolBar.frame = CGRectMake(0, self.toolBar.frame.origin.y - 5 ,
              self.toolBar.frame.width, self.toolBar.frame.height)
            self.datePicker.frame = CGRectMake(0, self.datePicker.frame.origin.y + 5, 0, 0)
        }, completion: {
          val in
          UIView.animateWithDuration(0.1, animations: {
            self.toolBar.frame = CGRectMake(0, self.toolBar.frame.origin.y + 5 ,
              self.toolBar.frame.width, self.toolBar.frame.height)
            self.datePicker.frame = CGRectMake(0, self.datePicker.frame.origin.y - 5, 0, 0)
          })
        })
      })
    }
  }
  
  private func animateAndExit() {
    UIView.animateWithDuration(0.7, animations: {
      self.view.alpha = 0
      }, completion: {
        val in
        self.dismissViewControllerAnimated(true, completion: nil)
      })
  }
  
// MARK: action functions
  @IBAction func cancel(sender: UIBarButtonItem) {
    animateAndExit()
  }
  

  @IBAction func done(sender: UIBarButtonItem) {
    animateAndExit()
    delegate?.dateSelectorDidFinish(datePicker.date, type: type)
  }

}
