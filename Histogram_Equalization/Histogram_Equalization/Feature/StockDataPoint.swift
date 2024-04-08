//
//  StockDataPoint.swift
//  Histogram_Equalization
//
//  Created by 이치훈 on 4/7/24.
//

import Foundation

struct StockDataPoint: Identifiable {
  let id = UUID()
  var r: Int // 픽셀의 밝기값
  var n: Int // 픽셀의 개수
  var stockID: String // RGB
}
