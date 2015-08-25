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
  let userRoles = ["Domain advisor", "Technical advisor","Probable team member"]
  var roleRow = 0
  var delegate: ParticipateInCallDelgate?
  @IBOutlet weak var rolePicker: UIPickerView!
  @IBOutlet weak var date_label: UILabel!
  @IBOutlet weak var date: UITextField!
  @IBOutlet weak var save: UIButton!
  override func viewDidLoad() {
    super.viewDidLoad()
    stylizeControls()
  }
  
  @IBAction func date_click(sender: UITextField) {
    loadDateSelectorNIB("AvailabilityDate")
  }
  private func loadDateSelectorNIB(type: String) {
    let dateVC = DateSelector(nibName: "DateSelector", bundle: nil)
    dateVC.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
    dateVC.modalPresentationStyle = UIModalPresentationStyle.OverFullScreen
    dateVC.delegate = self
    dateVC.type = type
    dateVC.pickerType = UIDatePickerMode.Date
    presentViewController(dateVC, animated: true, completion: nil)
  }

  @IBAction func save_click(sender: UIButton) {
    self.navigationController?.popViewControllerAnimated(true)
    delegate?.saveFinish()
  }
  private func stylizeControls() {
    navigationController?.navigationBar.backgroundColor = Theme.Prospects.navBarBG
    view.backgroundColor = Theme.Prospects.cellBGOddCell
    date.hidden = true
    date_label.hidden = true
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
      date_label.hidden = false
      date.becomeFirstResponder()
      save.enabled = false
    } else {
      date.hidden = true
      date_label.hidden = true
      save.enabled = true
    }
  }
  
  // MARK: Delegate Functions
  
  func textFieldDidEndEditing(textField: UITextField) {
    save.enabled = true
  }
  func dateSelectorDidFinish(controller: DateSelector, type: String?) {
    if let type = type {
      if type == "AvailabilityDate" {
        date.text = DateHandler.getPrintDate(controller.datePicker.date)
        date.resignFirstResponder()
      }
    }
  }

}
