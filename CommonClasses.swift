//
//  CommonClass.swift
//  PreSales-Huddle
//
//  Created by Himanshu Phirke on 20/08/15.
//  Copyright (c) 2015 synerzip. All rights reserved.
//

import Foundation

class TupleWrapper {
  let tuple : (id:Int, data:String)
  init(tuple : (Int, String)) {
    self.tuple = tuple
  }
}