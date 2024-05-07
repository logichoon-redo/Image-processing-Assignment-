//
//  ChartView.swift
//  Histogram_Equalization
//
//  Created by 이치훈 on 4/7/24.
//

import Charts
import SwiftUI

class ChartViewModel: ObservableObject {
  @Published var data: [HistDataPoint] = [HistDataPoint]()
  
  func updateData(newData: [HistDataPoint]) {
    self.data = newData
  }
}

struct ChartView: View {
  
  @ObservedObject var viewModel = ChartViewModel()
  
  var body: some View {
    Chart(viewModel.data) { dp in
      LineMark(
        x: .value("픽셀 밝기 값", dp.r),
        y: .value("픽셀의 수", dp.n)
      )
      .foregroundStyle(by: .value("rgb ID", dp.rgbID))
      
    }
//    .chartForegroundStyleScale([
//      "red": .red, "green": .green, "blue": .blue
//    ])
    .chartXAxis {
      AxisMarks(preset: .aligned, position: .bottom)
    }
    .chartYAxis {
      AxisMarks(preset: .aligned, position: .leading)
    }
    .chartLegend(.visible)
    .onAppear()
  }
  
}
