//
//  MainViewController.swift
//  Histogram_Equalization
//
//  Created by 이치훈 on 4/7/24.
//

import SnapKit
import SwiftUI
import UIKit

class MainViewController: UIViewController {
  
  // MARK: - Properties
  // UI Properties
  let mainImageView: UIImageView = {
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
  var histChartView: ChartView!
  var histHostingController: UIHostingController<ChartView>!
  var sumChartView: ChartView!
  var sumHostingController: UIHostingController<ChartView>!
  var pixelData = [UInt8](repeating: 0, count: 256 * 256 * 4)
  var rLookUpTable = [Int: Int]()
  var gLookUpTable = [Int: Int]()
  var bLookUpTable = [Int: Int]()
  
  // MARK: - LifeCycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view.backgroundColor = .white
    
    // 그래프 생성
    histChartView = ChartView()
    histHostingController = UIHostingController(rootView: histChartView)
    sumChartView = ChartView()
    sumHostingController = UIHostingController(rootView: sumChartView)
    
    self.initHistogram(image: UIImage(named: "test image")!)
    
    self.setTarget()
    self.configureSubviews()
  }
  
  // MARK: - ButtonMethod
  
  func setTarget() {
    equalButton.addTarget(self, action: #selector(tappedEqualButton), for: .touchUpInside)
  }
  
  @objc func tappedEqualButton() {
    guard let cgImage = self.histogramEqualization(sumData: sumData) else { print("image nil"); return }
    self.mainImageView.image = UIImage(cgImage: cgImage)
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
    
    createHistAndSum(pixelData: pixelData, height: height, width: width)
  }
  
  // MARK: - HistogramEqualization
  
  func histogramEqualization(sumData: [HistDataPoint]) -> CGImage? {
    
    // round(((L - 1) / MN) * sum_i) histogram equalization
    _=(0...255).map { i in
      // LookUpTable에 변경값 저장
      rLookUpTable[sumData[i].r] = Int(round((255.0 / 65536.0) * Double(sumData[i].n)))
    }
    _=(256...511).map { i in
      gLookUpTable[sumData[i].r] = Int(round((255.0 / 65536.0) * Double(sumData[i].n)))
    }
    _=(512...767).map { i in
      bLookUpTable[sumData[i].r] = Int(round((255.0 / 65536.0) * Double(sumData[i].n)))
    }
    
    // 변경(histogram equalization)된 픽셀데이터 LookUpTable에 참조해 업데이트
    // 여기서 참조되는 pixelData는 원본 이미지영상을 참조한 데이터임
    for i in stride(from: 0, to: pixelData.count, by: 4) {
      pixelData[i] = UInt8(rLookUpTable[Int(exactly: pixelData[i])!]!)
    }
    for i in stride(from: 1, to: pixelData.count, by: 4) {
      pixelData[i] = UInt8(gLookUpTable[Int(exactly: pixelData[i])!]!)
    }
    for i in stride(from: 2, to: pixelData.count, by: 4) {
      pixelData[i] = UInt8(bLookUpTable[Int(exactly: pixelData[i])!]!)
    }
    for i in stride(from: 3, to: pixelData.count, by: 4) {
      pixelData[i] = 255 // alpha
    }
    
    createHistAndSum(pixelData: pixelData, height: 256, width: 256)
    
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
    var rHistogram = [Int](repeating: 0, count: 256)
    var gHistogram = [Int](repeating: 0, count: 256)
    var bHistogram = [Int](repeating: 0, count: 256)
    
    for y in 0..<height {
      for x in 0..<width {
        // pixelData -> R, G, B, Alpha 값들이 순서대로 보관돼있음
        let offset = (y * width + x) * 4
        let red = pixelData[offset]
        let green = pixelData[offset + 1]
        let blue = pixelData[offset + 2]
        
        // 히스토그램 생성(밝기값(r)별 픽셀의 개수(n) count)
        rHistogram[Int(red)] += 1
        gHistogram[Int(green)] += 1
        bHistogram[Int(blue)] += 1
      }
    }
    
    var tempHistData = [HistDataPoint]()
    var tempSumData = [HistDataPoint]()
    var sumRHistogram = 0
    var sumGHistogram = 0
    var sumBHistogram = 0
    
    _=(0..<rHistogram.count).map { i in
      tempHistData.append(HistDataPoint(r: i, n: rHistogram[i], rgbID: "red"))
      
      // 누적 분포 함수 계산
      sumRHistogram += rHistogram[i]
      tempSumData.append(HistDataPoint(r: i, n: sumRHistogram, rgbID: "red"))
    }
    _=(0..<gHistogram.count).map { i in
      tempHistData.append(HistDataPoint(r: i, n: gHistogram[i], rgbID: "green"))
      sumGHistogram += gHistogram[i]
      tempSumData.append(HistDataPoint(r: i, n: sumGHistogram, rgbID: "green"))
    }
    _=(0..<bHistogram.count).map { i in
      tempHistData.append(HistDataPoint(r: i, n: bHistogram[i], rgbID: "blue"))
      sumBHistogram += bHistogram[i]
      tempSumData.append(HistDataPoint(r: i, n: sumBHistogram, rgbID: "blue"))
    }
    
    // Chart Update (didSet 실행)
    histData = tempHistData
    sumData = tempSumData
    
    print("histRed: \(tempHistData.filter { $0.rgbID == "red" }.map { $0.n })")
    print("histGreen: \(tempHistData.filter { $0.rgbID == "green" }.map { $0.n })")
    print("histBlue: \(tempHistData.filter { $0.rgbID == "blue" }.map { $0.n })")
    
    print("sumRed: \(tempSumData.filter { $0.rgbID == "red" }.map { $0.n })")
    print("sumGreen: \(tempSumData.filter { $0.rgbID == "green" }.map { $0.n })")
    print("sumBlue: \(tempSumData.filter { $0.rgbID == "blue" }.map { $0.n })")
    
    print("---------------------------------------------------------------------------------------------")
  }
  
}

// MARK: - LayoutSupport

extension MainViewController: LayoutSupport {
  
  func configureSubviews() {
    addSubviews()
    setupSubviewsConstraints()
  }
  
  func addSubviews() {
    self.view.addSubview(self.mainImageView)
    
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
    self.mainImageView.snp.makeConstraints {
      $0.centerX.equalToSuperview()
      $0.top.equalToSuperview().offset(90)
    }
    
    self.histHostingController.view.snp.makeConstraints {
      $0.centerX.equalToSuperview()
      $0.top.equalTo(self.mainImageView.snp.bottom).offset(40)
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
      $0.top.equalTo(self.sumHostingController.view.snp.bottom).offset(30)
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

