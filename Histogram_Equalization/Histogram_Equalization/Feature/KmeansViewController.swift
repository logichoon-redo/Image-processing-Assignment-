//
//  K-MeansViewController.swift
//  Histogram_Equalization
//
//  Created by 이치훈 on 6/14/24.
//

import SnapKit
import UIKit

class KmeansViewController: UIViewController {
  
  // MARK: - Properties
  // UI Properties
  let kmeansImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.image = UIImage(named: "test image")
    return imageView
  }()
  let kmeansLabel: UILabel = {
    let label = UILabel()
    label.text = "Cluster K: "
    label.font = .boldSystemFont(ofSize: 20)
    return label
  }()
  let kmeansTextField: UITextField = {
    let textfield = UITextField()
    textfield.placeholder = "cluster의 개수를 입력해주세요."
    textfield.keyboardType = .numberPad
    return textfield
  }()
  let kmeansButton: UIButton = {
    let button = UIButton()
    button.setTitle("Let's K-Means! 🚀", for: .normal)
    button.backgroundColor = .black
    button.layer.cornerRadius = 20
    return button
  }()
  
  // K-Means Properties
  var k: Int = 0
  
  // MARK: - LifeCycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view.backgroundColor = .white
    
    self.setTarget()
    self.configureSubviews()
  }
  
  // MARK: - ButtonMethod
  
  func setTarget() {
    kmeansButton.addTarget(self, action: #selector(tappedKMeansButton), for: .touchUpInside)
  }
  
  @objc func tappedKMeansButton() {
    k = Int(kmeansTextField.text ?? "0") ?? 0
    if k == 0 {
      let alert = UIAlertController(title: "잠깐!", message: "1에서 255 사이의 정수만 입력해주세요.", preferredStyle: .alert)
      alert.addAction(UIAlertAction.init(title: "확인", style: .cancel))
      self.present(alert, animated: true) {
        self.k = 0
        self.kmeansTextField.text = nil
      }
      
      return
    }
    
    // K-Means 알고리즘
    guard let image = UIImage(named: "test image"), let points = getRGBPoints(image: image) else {
      return
    }
    let (centroids, clusters) = kmeans(points: points, k: k)
    guard let resultImage = createImage(from: points, clusters: clusters, centroids: centroids, width: 256, height: 256) else { return }
    
    self.kmeansImageView.image = resultImage
    k = 0
  }
  
  // MARK: - initializeCentroids
  // random 값으로 초기 중심 선택
  func initializeCentroids(points: [RGBPoint], k: Int) -> [RGBPoint] {
    var centroids = [RGBPoint]()
    var usedIndex = Set<Int>()
    
    // usedIndex에 설정한 밝기값을 보관하여 밝기값 중복을 방지하고 있음
    while centroids.count < k {
      let index = Int.random(in: 0..<points.count)
      if !usedIndex.contains(index) {
        centroids.append(points[index])
        usedIndex.insert(index)
      }
    }
    
    return centroids
  }
  
  // MARK: assignClusters
  // 각 포인트를 가장 가까운 클러스터에 할당 -> 픽셀마다 가까운 centroid index값을 저장
  func assignClusters(pointS: [RGBPoint], centroids: [RGBPoint]) -> [Int] {
    var clusters = [Int]()
    
    for point in pointS {
      var minDistance = Double.greatestFiniteMagnitude
      var closestCentroidIndex = 0
      
      // point를 centroid마다 유클리드거리를 계산하고 가장 짧은 유클리드 거리의 index를 추출하고
      for (index, centroid) in centroids.enumerated() {
        let distance = euclideanDistance(a: point, b: centroid)
        if distance < minDistance {
          minDistance = distance
          closestCentroidIndex = index
        }
      }
      // index를 clusters 배열에 저장
      clusters.append(closestCentroidIndex)
    }
    
    return clusters
  }
  
  // MARK: updateCentroids
  // cluster 중심 업데이트
  func updateCentroids(points: [RGBPoint], clusters: [Int], k: Int) -> [RGBPoint] {
    var newCentroids = Array(repeating: RGBPoint(r: 0, g: 0, b: 0), count: k)
    var counts = Array(repeating: 0, count: k) // S_i의 sample 수
    
    // pixel의 밝기값을 클러스터집합에 누적합을 구하는 코드 & S_i를 구하는 코드
    // pixel index, cluster index
    for (index, cluster) in clusters.enumerated() {
      newCentroids[cluster].r += points[index].r
      newCentroids[cluster].g += points[index].g
      newCentroids[cluster].b += points[index].b
      counts[cluster] += 1
    }
    
    // sum(z) / S_i
    for i in 0..<k {
      newCentroids[i].r /= Double(counts[i])
      newCentroids[i].g /= Double(counts[i])
      newCentroids[i].b /= Double(counts[i])
    }
    
    return newCentroids
  }
  
  // MARK: - kmeans
  // K-Means 알고리즘
  func kmeans(points: [RGBPoint], 
              k: Int,
              maxLoop: Int = 100,
              tol: Double = 1e-4) -> ([RGBPoint], [Int]) {
    var centroids = initializeCentroids(points: points, k: k)
    
    for _ in 0..<maxLoop {
      let clusters = assignClusters(pointS: points, centroids: centroids)
      let newCentroids = updateCentroids(points: points, clusters: clusters, k: k)
      
      // centroid의 변화 distance(크기)를 구함
      var diff = 0.0
      for i in 0..<k {
        diff += euclideanDistance(a: centroids[i], b: newCentroids[i])
      }
      // 변화량이 임계치T보다 작으면 알고리즘 종료
      if diff < tol { break }
      
      // centroids값 update
      centroids = newCentroids
    }
    
    let finalClusters = assignClusters(pointS: points, centroids: centroids)
    return (centroids, finalClusters)
  }
  
  // MARK: euclideanDistance
  // 유클리드 거리 계산 함수
  func euclideanDistance(a: RGBPoint, b: RGBPoint) -> Double {
    return sqrt(pow(a.r - b.r, 2) + pow(a.g - b.g, 2) + pow(a.b - b.b, 2))
  }
  
  // MARK: getRGBPoints
  // image -> RGBPoint 전환
  func getRGBPoints(image: UIImage) -> [RGBPoint]? {
    guard let cgImage = image.cgImage else { return nil }
    guard let data = cgImage.dataProvider?.data else { return nil }
    guard let bytes = CFDataGetBytePtr(data) else { return nil }
    
    let width = cgImage.width
    let height = cgImage.height
    let bytesPerPixel = cgImage.bitsPerPixel / 8
    
    var points = [RGBPoint]()
    
    for y in 0..<height {
      for x in 0..<width {
        let pixelIndex = (y * width + x) * bytesPerPixel
        let r = Double(bytes[pixelIndex]) / 255.0
        let g = Double(bytes[pixelIndex + 1]) / 255.0
        let b = Double(bytes[pixelIndex + 2]) / 255.0
        points.append(RGBPoint(r: r, g: g, b: b))
      }
    }
    
    return points
  }
  
  // MARK: createImage
  // 결과를 이미지로 변환
  func createImage(from points: [RGBPoint], 
                   clusters: [Int],
                   centroids: [RGBPoint],
                   width: Int,
                   height: Int) -> UIImage? {
    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * width
    var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
    
    for y in 0..<height {
      for x in 0..<width {
        let pixelIndex = (y * width + x) * bytesPerPixel
        let clusterIndex = clusters[y * width + x]
        let centroid = centroids[clusterIndex]
        
        pixelData[pixelIndex] = UInt8(centroid.r * 255.0)
        pixelData[pixelIndex + 1] = UInt8(centroid.g * 255.0)
        pixelData[pixelIndex + 2] = UInt8(centroid.b * 255.0)
        pixelData[pixelIndex + 3] = 255 // Alpha value
      }
    }
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(data: &pixelData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    
    guard let cgImage = context?.makeImage() else { return nil }
    return UIImage(cgImage: cgImage)
  }
  
}

// MARK: - LayoutSupport

extension KmeansViewController: LayoutSupport {
  
  func configureSubviews() {
    self.addSubviews()
    self.setupSubviewsConstraints()
  }
  
  func addSubviews() {
    self.view.addSubview(self.kmeansImageView)
    self.view.addSubview(self.kmeansLabel)
    self.view.addSubview(self.kmeansTextField)
    self.view.addSubview(self.kmeansButton)
  }
  
  func setupSubviewsConstraints() {
    self.kmeansImageView.snp.makeConstraints {
      $0.centerX.equalToSuperview()
      $0.top.equalToSuperview().offset(120)
    }
    
    self.kmeansLabel.snp.makeConstraints {
      $0.top.equalTo(self.kmeansImageView.snp.bottom).offset(50)
      $0.leading.equalToSuperview().inset(40)
    }
    
    self.kmeansTextField.snp.makeConstraints {
      $0.centerY.equalTo(self.kmeansLabel.snp.centerY)
      $0.leading.equalTo(self.kmeansLabel.snp.trailing).offset(10)
    }
    
    self.kmeansButton.snp.makeConstraints {
      $0.centerX.equalToSuperview()
      $0.top.equalTo(self.kmeansTextField.snp.bottom).offset(35)
      $0.height.equalTo(50)
      $0.width.equalTo(200)
    }
  }
  
}
