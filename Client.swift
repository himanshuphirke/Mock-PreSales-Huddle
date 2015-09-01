//
//  Client.swift
//  PreSales-Huddle
//
//  Created by Himanshu Phirke on 28/07/15.
//  Copyright (c) 2015 synerzip. All rights reserved.
//

import UIKit

class Client: UIViewController {
  var itemToView: [String: AnyObject]?

  @IBOutlet weak var name: UITextField!
  @IBOutlet weak var techStack: UITextField!
  @IBOutlet weak var domain: UITextField!
  @IBOutlet weak var buHead: UITextField!
  @IBOutlet weak var teamSize: UITextField!
  @IBOutlet weak var salesManager: UITextField!
  @IBOutlet weak var notes: UITextView!
  @IBOutlet weak var notesLabel: UILabel!

  override func viewDidLoad() {
    initMockData()
    stylizeControls()
    if let item = itemToView {
      showData(item)
    }
  }
  
  private func initMockData() {
    for subView in view.subviews {
        if let textfield = subView as? UITextField {
            let rightView = UILabel(frame: CGRectZero)
            rightView.text = " \(textfield.text) "
            rightView.font = UIFont.systemFontOfSize(12)
            rightView.sizeToFit()
            rightView.textColor = UIColor(red: 0.000, green: 0.478, blue: 1.000, alpha: 0.50)
            textfield.leftViewMode = UITextFieldViewMode.Always
            textfield.leftView = rightView
        }
    }
  }
    
  private func stylizeControls() {
    notes.layer.borderWidth = 1.0
    notes.layer.cornerRadius = 5.0
    notes.layer.borderColor = UIColor(red: 0.835, green: 0.835, blue: 0.835, alpha: 1.00).CGColor
  }
  private func showData(dict: [String: AnyObject]) {
    
    name.text = dict["Name"] as? String
    techStack.text = dict["TechStack"] as? String
    domain.text = dict["Domain"] as? String
    buHead.text = dict["BUHead"] as? String
    if let size = dict["TeamSize"] as? Int {
      teamSize.text = "\(size)"
    }
    salesManager.text = dict["SalesID"] as? String
    notes.text = dict["Notes"] as? String
  }
}
