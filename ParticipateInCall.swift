//
//  ParticipateInCall.swift
//  PreSales-Huddle
//
//  Created by Himanshu Phirke on 21/08/15.
//  Copyright (c) 2015 synerzip. All rights reserved.
//

import UIKit

class ParticipateInCall:UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
  let userRoles = ["Domain advisor", "Technical advisor","Probable team member"]
  var roleRow = 0
  @IBOutlet weak var rolePicker: UIPickerView!
  
  @IBOutlet weak var date_label: UILabel!
  @IBOutlet weak var date: UITextField!
  override func viewDidLoad() {
    super.viewDidLoad()
    stylizeControls()
    date.enabled = false
  }
  

  private func stylizeControls() {
    navigationController?.navigationBar.backgroundColor = Theme.Prospects.navBarBG
    view.backgroundColor = Theme.Prospects.cellBGOddCell
    date.hidden = true
    date_label.hidden = true
    date.backgroundColor = Theme.Prospects.textFieldBG
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
    lView!.font = UIFont.systemFontOfSize(12)
    lView!.text = userRoles[row]
    return lView!
  }
  
  func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    if row == 2 {
      date.hidden = false
      date_label.hidden = false
      date.becomeFirstResponder()
    } else {
      date.hidden = true
      date_label.hidden = true
    }
  }

}
