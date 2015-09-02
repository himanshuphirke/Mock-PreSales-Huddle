//
//  ParticipateInCall.swift
//  PreSales-Huddle
//
//  Created by Himanshu Phirke on 21/08/15.
//  Copyright (c) 2015 synerzip. All rights reserved.
//

import UIKit

protocol ParticipateInCallDelgate: class {
  func saveFinish()
}

class ParticipateInCall:UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate,
    DateSelectorDelegate {
  let userRoles = ["Domain Advisor", "Technical Advisor","Probable Team member"]
  var roleRow = 0
  var delegate: ParticipateInCallDelgate?
  @IBOutlet weak var rolePicker: UIPickerView!
  @IBOutlet weak var date: UITextField!
  @IBOutlet weak var save: UIButton!
  override func viewDidLoad() {
    super.viewDidLoad()
    date.hidden = true
    
    let dateFieldLabel = UILabel(frame: CGRectZero)
    dateFieldLabel.text = " Earliest Availability Date "
    dateFieldLabel.font = UIFont.systemFontOfSize(12)
    dateFieldLabel.sizeToFit()
    dateFieldLabel.textColor = UIColor(red: 0.000, green: 0.478, blue: 1.000, alpha: 0.50)
    date.leftViewMode = UITextFieldViewMode.Always
    date.leftView = dateFieldLabel

    // stylizeControls()
  }
  
  @IBAction func save_click(sender: UIButton) {
    self.navigationController?.popViewControllerAnimated(true)
    delegate?.saveFinish()
  }
  private func stylizeControls() {
    navigationController?.navigationBar.backgroundColor = Theme.Prospects.navBarBG
    view.backgroundColor = Theme.Prospects.cellBGOddCell
    date.hidden = true
    date.backgroundColor = Theme.Prospects.textFieldBG
    save.backgroundColor = Theme.Prospects.okButtonBG
    Theme.applyButtonBorder(save)
  }
  
  func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return userRoles.count
  }
  
  func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
    return 1
  }
    
  func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView!) -> UIView {
    var lView = view as? UILabel
    if lView == nil {
      lView = UILabel()
    }
    lView!.font = UIFont.systemFontOfSize(14)
    lView!.text = userRoles[row]
    return lView!
  }
  
  func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    if row == 2 {
      date.hidden = false
      save.enabled = false
    } else {
      date.hidden = true
      date.text = ""
      save.enabled = true
    }
  }
  
  // MARK: Delegate Functions
  
  func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
    if textField.tag == 333 {
      let dateVC = DateSelector(nibName: "DateSelector", bundle: nil)
      dateVC.modalPresentationStyle = UIModalPresentationStyle.OverFullScreen
      dateVC.delegate = self
      dateVC.type = "AvailabilityDate"
      dateVC.pickerType = UIDatePickerMode.Date
      dateVC.senderFrame = textField.frame
      presentViewController(dateVC, animated: false, completion: nil)
      return false
    } else {
      return true
    }
    
  }
  func dateSelectorDidFinish(dateFromVC: NSDate, type: String?) {
    if let type = type {
      if type == "AvailabilityDate" {
        date.text = DateHandler.getPrintDate(dateFromVC)
        save.enabled = true
      }
    }
  }

}
