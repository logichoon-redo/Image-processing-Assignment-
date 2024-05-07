//
//  YCbCr.swift
//  Histogram_Equalization
//
//  Created by 이치훈 on 5/7/24.
//

import Foundation

struct YCbCrItem {
  var y: UInt8 = 0
  var c_b: UInt8 = 0
  var c_r: UInt8 = 0
  
  init(y: UInt8 = 0, c_b: UInt8 = 0, c_r: UInt8 = 0) {
    self.y = y
    self.c_b = c_b
    self.c_r = c_r
  }
}
