//
//  MainViewController.swift
//  Histogram_Equalization
//
//  Created by 이치훈 on 4/7/24.
//

import SnapKit
import SwiftUI
import UIKit

class HistEqualizationViewController: UIViewController {
  
  // MARK: - Properties
  // UI Properties
  let histImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.image = UIImage(named: "test image")
    return imageView
  }()
  let equalButton: UIButton = {
    let button = UIButton()
    button.setTitle("Let's Equalization! 🚀", for: .normal)
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
  var histChartView: ChartView!
  var histHostingController: UIHostingController<ChartView>!
  var sumChartView: ChartView!
  var sumHostingController: UIHostingController<ChartView>!
  
  // histogram Properties
  var histData: [HistDataPoint] = [HistDataPoint]() {
    didSet {
      histChartView.viewModel.updateData(newData: histData)
    }
  }
  var sumData: [HistDataPoint] = [HistDataPoint]() {
    didSet {
      sumChartView.viewModel.updateData(newData: sumData)
    }
  }
  
  var pixelData = [UInt8](repeating: 0, count: 256 * 256 * 4)
  var yCbCrPixelData = [YCbCrItem]()
  var lookUpTable = [Int](repeating: 0, count: 256)
  
  // MARK: - LifeCycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view.backgroundColor = .white
    
    // 그래프 생성
    self.histChartView = ChartView()
    self.histHostingController = UIHostingController(rootView: histChartView)
    self.sumChartView = ChartView()
    self.sumHostingController = UIHostingController(rootView: sumChartView)
    
    self.initHistogram(image: UIImage(named: "test image")!)
    
    self.setTarget()
    self.configureSubviews()
  }
  
  // MARK: - ButtonMethod
  
  func setTarget() {
    equalButton.addTarget(self, action: #selector(tappedEqualButton), for: .touchUpInside)
  }
  
  @objc func tappedEqualButton() {
    guard let cgImage = self.histogramEqualization() else { print("image nil"); return }
    self.histImageView.image = UIImage(cgImage: cgImage)
    self.equalButton.setTitle("Successful! 🎯", for: .normal)
  }
  
  // MARK: - Histogram Init
  
  func initHistogram(image: UIImage) {
    // 이미지를 픽셀데이터(UInt8)로 전환!
    guard let cgImage = image.cgImage else { return }
    let width = cgImage.width
    let height = cgImage.height
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytePerRow = 4 * width
    
    let context = CGContext(data: &pixelData,
                            width: width,
                            height: height,
                            bitsPerComponent: 8,
                            bytesPerRow: bytePerRow,
                            space: colorSpace,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    
    context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    
    self.createHistAndSum(pixelData: pixelData, height: height, width: width)
  }
  
  // MARK: - HistogramEqualization
  
  func histogramEqualization() -> CGImage? {
    // round(((L - 1) / MN) * sum_i) histogram equalization
    _=(0...255).map { i in
      // LookUpTable에 변경값 저장
      self.lookUpTable[i] = Int(round((255.0 / 65536.0) * Double(self.sumData[i].n)))
    }
    
    // 변경(histogram equalization)된 픽셀데이터 LookUpTable에 참조해 업데이트
    _=(0..<self.yCbCrPixelData.count).map { i in
      self.yCbCrPixelData[i].y = UInt8(lookUpTable[Int(self.yCbCrPixelData[i].y)])
    }
    
    self.pixelData = changeYCbCrtoRGB(yCbCrPixelData: self.yCbCrPixelData)
    
    self.createHistAndSum(pixelData: pixelData, height: 256, width: 256)
    
    // CG이미지 생성
    guard let providerRef = CGDataProvider(data: Data(pixelData) as CFData) else { print("no data"); return nil }
    
    let cgImgae = CGImage(width: 256,
                          height: 256,
                          bitsPerComponent: 8,
                          bitsPerPixel: 4 * 8,
                          bytesPerRow: 4 * 256,
                          space: CGColorSpaceCreateDeviceRGB(),
                          bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                          provider: providerRef,
                          decode: nil,
                          shouldInterpolate: true,
                          intent: .defaultIntent)
    
    return cgImgae
  }
  
  // MARK: - createHistAndSum
  
  func createHistAndSum(pixelData: [UInt8], height: Int, width: Int) {
    var histogram = [Int](repeating: 0, count: 256)
    var histogramSum = 0
    var tempHistData = [HistDataPoint]()
    var tempSumData = [HistDataPoint]()
    
    self.yCbCrPixelData = self.changeRGBtoYCbCr(pixelData: pixelData, height: height, width: width)
    
    _=self.yCbCrPixelData.map {
      histogram[Int($0.y)] += 1
    }
    
    _=(0...255).map { i in
      tempHistData.append(HistDataPoint(r: i, n: histogram[i], rgbID: "YCbCr"))
      
      // 누적 분포 함수 계산
      histogramSum += histogram[i]
      tempSumData.append(HistDataPoint(r: i, n: histogramSum, rgbID: "YCbCr"))
    }
    
    // Chart Update (didSet 실행)
    self.histData = tempHistData
    self.sumData = tempSumData
    
    print("Histogram: \(tempHistData.map { $0.n })")
    print("Sum: \(tempSumData.map { $0.n })")
    
    print("---------------------------------------------------------------------------------------------")
  }
  
  // MARK: - changeRGBtoYCbCr
  
  func changeRGBtoYCbCr(pixelData: [UInt8], height: Int, width: Int) -> [YCbCrItem] {
    var yCbCrPixelData = [YCbCrItem]()
    
    for y in 0..<height {
      for x in 0..<width {
        // pixelData -> R, G, B, Alpha 값들이 순서대로 보관돼있음
        var yCbCrItem = YCbCrItem()
        let offset = (y * width + x) * 4
        let red = pixelData[offset]
        let green = pixelData[offset + 1]
        let blue = pixelData[offset + 2]
        
        yCbCrItem.y = UInt8(0.299 * Double(red) + 0.587 * Double(green) + 0.114 * Double(blue))
        yCbCrItem.c_b = UInt8(-0.169 * Double(red) - 0.331 * Double(green) + 0.5 * Double(blue) + 128.0)
        yCbCrItem.c_r = UInt8(0.5 * Double(red) - 0.419 * Double(green) - 0.081 * Double(blue) + 128.0)
        
        yCbCrPixelData.append(yCbCrItem)
      }
    }
    
    return yCbCrPixelData
  }
  
  //MARK: - changeYCbCrtoRGM
  
  func changeYCbCrtoRGB(yCbCrPixelData: [YCbCrItem]) -> [UInt8] {
    var pixelData = [UInt8]()
    
    _=yCbCrPixelData.map {
      let y = Double($0.y)
      let c_rMacro = Double($0.c_r) - 128.0
      let c_bMacro = Double($0.c_b) - 128.0
      
      // 각 색상 값을 계산하고 클리핑하여 범위를 0-255 사이로 제한
      let red = y + 1.402 * c_rMacro
      let green = y - 0.344136 * c_bMacro - 0.714136 * c_rMacro
      let blue = y + 1.772 * c_bMacro
      
      pixelData.append(UInt8(max(0, min(255, red))))
      pixelData.append(UInt8(max(0, min(255, green))))
      pixelData.append(UInt8(max(0, min(255, blue))))
      pixelData.append(UInt8(255))
    }
    
    return pixelData
  }
  
}

// MARK: - LayoutSupport

extension HistEqualizationViewController: LayoutSupport {
  
  func configureSubviews() {
    addSubviews()
    setupSubviewsConstraints()
  }
  
  func addSubviews() {
    self.view.addSubview(self.histImageView)
    
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
    self.histImageView.snp.makeConstraints {
      $0.centerX.equalToSuperview()
      $0.top.equalToSuperview().offset(60)
    }
    
    self.histHostingController.view.snp.makeConstraints {
      $0.centerX.equalToSuperview()
      $0.top.equalTo(self.histImageView.snp.bottom).offset(30)
      $0.height.equalTo(150)
      $0.width.equalTo(250)
    }
    
    self.sumHostingController.view.snp.makeConstraints {
      $0.centerX.equalToSuperview()
      $0.top.equalTo(self.histHostingController.view.snp.bottom).offset(30)
      $0.height.equalTo(150)
      $0.width.equalTo(250)
    }
    
    self.equalButton.snp.makeConstraints {
      $0.centerX.equalToSuperview()
      $0.top.equalTo(self.sumHostingController.view.snp.bottom).offset(20)
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

