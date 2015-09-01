//
//  DeadProspect.swift
//  PreSales-Huddle
//
//  Created by Himanshu Phirke on 31/08/15.
//  Copyright (c) 2015 synerzip. All rights reserved.
//

import UIKit

class DeadProspect: UIViewController, UITextFieldDelegate, UITextViewDelegate {
  var itemToView: [String: AnyObject]?
  
  @IBOutlet weak var technology: UITextField!
  @IBOutlet weak var name: UITextField!
  @IBOutlet weak var salesID: UITextField!
  @IBOutlet weak var notes: UITextView!
  @IBOutlet weak var domain: UITextField!
  
  override func viewDidLoad() {
    addLabels()
    if let item = itemToView {
      showData(item)
    }
  }
  
  private func addLabels() {
    let technologyLabel = UILabel(frame: CGRectZero)
    technologyLabel.font = UIFont.systemFontOfSize(12)
    technologyLabel.text = " Technology "
    technologyLabel.sizeToFit()
    technologyLabel.textColor = UIColor(red: 0.000, green: 0.478, blue: 1.000, alpha: 0.50)
    technology.leftViewMode = UITextFieldViewMode.Always
    technology.leftView = technologyLabel
    
    let nameLabel = UILabel(frame: CGRectZero)
    nameLabel.font = UIFont.systemFontOfSize(12)
    nameLabel.text = " Name "
    nameLabel.sizeToFit()
    nameLabel.textColor = UIColor(red: 0.000, green: 0.478, blue: 1.000, alpha: 0.50)
    name.leftViewMode = UITextFieldViewMode.Always
    name.leftView = nameLabel
    
    let salesIDLabel = UILabel(frame: CGRectZero)
    salesIDLabel.font = UIFont.systemFontOfSize(12)
    salesIDLabel.text = " Sales "
    salesIDLabel.sizeToFit()
    salesIDLabel.textColor = UIColor(red: 0.000, green: 0.478, blue: 1.000, alpha: 0.50)
    salesID.leftViewMode = UITextFieldViewMode.Always
    salesID.leftView = salesIDLabel
    
    let domainLabel = UILabel(frame: CGRectZero)
    domainLabel.font = UIFont.systemFontOfSize(12)
    domainLabel.text = " Domain "
    domainLabel.sizeToFit()
    domainLabel.textColor = UIColor(red: 0.000, green: 0.478, blue: 1.000, alpha: 0.50)
    domain.leftViewMode = UITextFieldViewMode.Always
    domain.leftView = domainLabel
    
    
    notes.layer.borderWidth = 1.0
    notes.layer.cornerRadius = 5.0
    notes.layer.borderColor = UIColor(red: 0.835, green: 0.835, blue: 0.835, alpha: 1.00).CGColor
    
    
  }
  
  private func showData(dict: [String: AnyObject]) {
    name.text = dict["Name"] as? String
    technology.text = dict["TechStack"] as? String
    domain.text = dict["Domain"] as? String
    salesID.text = dict["SalesID"] as? String
    notes.text = dict["Notes"] as? String
  }
  
  func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
    return false
  }
  
  func textViewShouldBeginEditing(textView: UITextView) -> Bool {
    return false
  }

}
