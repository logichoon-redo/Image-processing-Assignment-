//
//  ViewController.swift
//  Histogram_Equalization
//
//  Created by 이치훈 on 4/7/24.
//

import SnapKit
import SwiftUI
import UIKit

class ViewController: UIViewController {
  
  // MARK: - Properties
  // UI Properties
  let inputImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.image = UIImage(named: "test image")
    return imageView
  }()
  let equalButton: UIButton = {
    let button = UIButton()
    button.setTitle("Let's Equalization!🚀", for: .normal)
    button.backgroundColor = .black
    button.layer.cornerRadius = 20
    return button
  }()
  let histLabel: UILabel = {
    let label = UILabel()
    label.text = "Histogram"
    return label
  }()
  let sumLabel: UILabel = {
    let label = UILabel()
    label.text = "Sum"
    return label
  }()
  
  // histogram Properties
  var histData: [StockDataPoint] = [StockDataPoint]() {
    didSet {
      histChartView = ChartView(data: self.histData)
      histHostingController = UIHostingController(rootView: histChartView)
    }
  }
  var sumData: [StockDataPoint] = [StockDataPoint]() {
    didSet {
      sumChartView = ChartView(data: self.sumData)
      sumHostingController = UIHostingController(rootView: sumChartView)
    }
  }
  var histChartView: ChartView!
  var histHostingController: UIHostingController<ChartView>!
  var sumChartView: ChartView!
  var sumHostingController: UIHostingController<ChartView>!
  
  // MARK: - LifeCycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.initHistogram(image: UIImage(named: "test image")!)
    
    self.configureSubviews()
  }
  
  // MARK: - Histogram Init
  
  func initHistogram(image: UIImage) {
    guard let cgImage = image.cgImage else { return }
    let width = cgImage.width
    let height = cgImage.height
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytePerRow = 4 * width
    var pixelData = [UInt8](repeating: 0, count: width * height * 4)
    
    let context = CGContext(data: &pixelData,
                            width: width,
                            height: height,
                            bitsPerComponent: 8,
                            bytesPerRow: bytePerRow,
                            space: colorSpace,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    
    context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    
    var rHistogram = [Int](repeating: 0, count: 256)
    var gHistogram = [Int](repeating: 0, count: 256)
    var bHistogram = [Int](repeating: 0, count: 256)
    
    for y in 0..<height {
      for x in 0..<width {
        let offset = (y * width + x) * 4
        let red = pixelData[offset]
        let green = pixelData[offset + 1]
        let blue = pixelData[offset + 2]
        
        rHistogram[Int(red)] += 1
        gHistogram[Int(green)] += 1
        bHistogram[Int(blue)] += 1
      }
    }
    
    var sumRHistogram = 0
    var sumGHistogram = 0
    var sumBHistogram = 0
    
    _=(0..<rHistogram.count).map { i in
      histData.append(StockDataPoint(r: i, n: rHistogram[i], stockID: "red"))
      sumRHistogram += rHistogram[i]
      sumData.append(StockDataPoint(r: i, n: sumRHistogram, stockID: "red"))
    }
    _=(0..<gHistogram.count).map { i in
      histData.append(StockDataPoint(r: i, n: gHistogram[i], stockID: "green"))
      sumGHistogram += gHistogram[i]
      sumData.append(StockDataPoint(r: i, n: sumGHistogram, stockID: "green"))
    }
    _=(0..<bHistogram.count).map { i in
      histData.append(StockDataPoint(r: i, n: bHistogram[i], stockID: "blue"))
      sumBHistogram += bHistogram[i]
      sumData.append(StockDataPoint(r: i, n: sumBHistogram, stockID: "blue"))
    }
    
    print("histRed: \(histData.filter { $0.stockID == "red" }.map { $0.n })")
    print("histGreen: \(histData.filter { $0.stockID == "green" }.map { $0.n })")
    print("histBlue: \(histData.filter { $0.stockID == "blue" }.map { $0.n })")
    
    print("--------------------------------------------------------------------------------------")
    
    print("sumRed: \(sumData.filter { $0.stockID == "red" }.map { $0.n })")
    print("sumGreen: \(sumData.filter { $0.stockID == "green" }.map { $0.n })")
    print("sumBlue: \(sumData.filter { $0.stockID == "blue" }.map { $0.n })")
  }
  
}

// MARK: - ViewController

extension ViewController: LayoutSupport {
  
  func configureSubviews() {
    addSubviews()
    setupSubviewsConstraints()
  }
  
  func addSubviews() {
    self.view.addSubview(self.inputImageView)
    
    addChild(self.histHostingController)
    self.view.addSubview(self.histHostingController.view)
    self.histHostingController.didMove(toParent: self)
    
    addChild(self.sumHostingController)
    self.view.addSubview(self.sumHostingController.view)
    self.sumHostingController.didMove(toParent: self)
    
    self.view.addSubview(self.equalButton)
    self.view.addSubview(self.histLabel)
    self.view.addSubview(self.sumLabel)
  }
  
  func setupSubviewsConstraints() {
    self.inputImageView.snp.makeConstraints {
      $0.centerX.equalToSuperview()
      $0.top.equalToSuperview().offset(90)
    }
    
    self.histHostingController.view.snp.makeConstraints {
      $0.centerX.equalToSuperview()
      $0.top.equalTo(self.inputImageView.snp.bottom).offset(40)
      $0.height.equalTo(150)
      $0.width.equalTo(250)
    }
    
    self.sumHostingController.view.snp.makeConstraints {
      $0.centerX.equalToSuperview()
      $0.top.equalTo(self.histHostingController.view.snp.bottom).offset(40)
      $0.height.equalTo(150)
      $0.width.equalTo(250)
    }
    
    self.equalButton.snp.makeConstraints {
      $0.centerX.equalToSuperview()
      $0.top.equalTo(self.sumHostingController.view.snp.bottom).offset(40)
      $0.height.equalTo(50)
      $0.width.equalTo(200)
    }
    
    self.histLabel.snp.makeConstraints {
      $0.bottom.equalTo(histHostingController.view.snp.top)
      $0.centerX.equalToSuperview()
    }
    
    self.sumLabel.snp.makeConstraints {
      $0.bottom.equalTo(sumHostingController.view.snp.top)
      $0.centerX.equalToSuperview()
    }
  }
  
}

