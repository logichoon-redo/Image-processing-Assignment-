//
//  ChartView.swift
//  Histogram_Equalization
//
//  Created by 이치훈 on 4/7/24.
//

import Charts
import SwiftUI

struct ChartView: View {
  
  var data: [StockDataPoint]
  
  var body: some View {
    Chart(data) { dp in 
      LineMark(
        x: .value("픽셀 밝기 값", dp.r),
        y: .value("픽셀의 수", dp.n)
      )
      .foregroundStyle(by: .value("Stock ID", dp.stockID))
      
    }
    .chartForegroundStyleScale([
      "red": .red, "green": .green, "blue": .blue
    ])
    .chartXAxis {
      AxisMarks(preset: .aligned, position: .bottom)
    }
    .chartYAxis {
      AxisMarks(preset: .aligned, position: .leading)
    }
    .chartLegend(.visible)
  }
  
}
