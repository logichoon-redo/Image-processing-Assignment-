# Image Processing Assignment

### Histogram Equalization

<img width="445" alt="스크린샷 2024-05-08 오후 4 41 29" src="https://github.com/logichoon-redo/Image-processing-Assignment-/assets/117021317/c24ae8ed-1419-4bb2-8c01-def889ef09fa">

<br/>

> YCbCr 밝기 값릐 픽셀 수를 구해 histogram 지역 변수에 담고 있습니다.
> histogram를 tempHistData에 담으면서 데이터 합을 구해 누적분포함수를 나타내는 데이터를 만들고있습니다.
> 완성된 tempHistData, tempSumData를 전역 변수에 담으면 didSet이 발동되고 ChartView를 새롭게 그리고있습니다.
> 이 함수는 initHistogram()을 실행 할 때 호출되는데, 원본 이미지의 histogram 및 누적분포함수의 그래프를 그리기 위해서입니다.

```swift
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
    }
```

<br/>

> LookUpTable에 픽셀의 밝기 값별로 평탄화될 밝기 값을 계산하고 있습니다.
> 여기서 픽셀의 밝기 값은 lookUpTable[i]로 나타내고 있으며, 평탄화될 발기 값은 `Int(round((255.0 / 65536.0) * Double(self.sumData[i].n)))`연산에 의해 결정됩니다.
> 평탄화된 YCbCr Data를 다시 그릴 때는 LookUpTable의 index를 참조해 평탄화된 밝기 값을 얻어옵니다.
> 이 함수에서도 역시 createHistAndSum()를 사용해 평탄화된 이미지의 histogram 및 누적분포함수의 그래프를 그리고 있습니다.

```swift
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
```

<br/><br/>

### K-Means Algorithm
<img width="445" alt="스크린샷 2024-05-08 오후 4 41 29" src="https://github.com/logichoon-redo/Image-processing-Assignment-/blob/6b92285e4052be80bff0bf1e3942ea73003fd690/%E1%84%89%E1%85%B3%E1%84%8F%E1%85%B3%E1%84%85%E1%85%B5%E1%86%AB%E1%84%89%E1%85%A3%E1%86%BA%202024-06-22%20%E1%84%8B%E1%85%A9%E1%84%8C%E1%85%A5%E1%86%AB%2010.55.18.png">

> centroid(중앙 값)을 초기화하고 있습니다. 일반적으로 0 혹은 랜덤값을 초기화하지만 이 코드에선 랜덤 값으로 초기화 하되 index가 겹치지 않게 구현해 좀 더 효율적으로 만들었습니다.

```swift
func initializeCentroids(points: [RGBPoint], k: Int) -> [RGBPoint] {
    var centroids = [RGBPoint]()
    var usedIndex = Set<Int>()
    
    // usedIndex에 설정한 밝기값을 보관하여 밝기값 중복을 방지하고 있음
    while centroids.count < k {
      let index = Int.random(in: 0..<points.count) // random한 pixel의 index를 고름
      if !usedIndex.contains(index) { // 이미 선택한 index이면 append하지 않음
        centroids.append(points[index])
        usedIndex.insert(index)
      }
    }
    
    return centroids
  }
```

<br/>

> 픽셀의 index를 순회하면서 centroid의 euclideanDistance를 구하고 있습니다.
> euclideanDistance가 가장 짧았던 centroid를 참조하도록 clusters 변수에 담고 있습니다.

```swift
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
      // index를 clusters 배열에 저장 -> clusters의 index와 pixel의 index는 같음
      // pixel이 가르켜야 할 centroid의 index 저장
      clusters.append(closestCentroidIndex)
    }
    
    return clusters
  }
```

<br/>

> 픽셀의 밝기값을 클러스터별로 모아 sum을 구하고 있습니다.
> 이렇게 구해진 sum은 sample의 개수인 count로 나누면 새로운 centroid 값을 얻을 수 있습니다.

```swift
func updateCentroids(points: [RGBPoint], clusters: [Int], k: Int) -> [RGBPoint] {
    var newCentroids = Array(repeating: RGBPoint(r: 0, g: 0, b: 0), count: k)
    var counts = Array(repeating: 0, count: k) // S_i sample 수
    
    // pixel의 밝기값을 클러스터집합에 누적합을 구하는 코드 & S_i를 구하는 코드
    // pixel index, centroid index
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
```

<br/>

> 유클리드 거리를 계산하는 함수입니다.
> 식 `||Z_i - M_i||^2 = sqrt((Z_1 - M_i1)^2 + (Z_2 - M_i2)^2)`을 나타내고 있습니다.

```swift
func euclideanDistance(a: RGBPoint, b: RGBPoint) -> Double {
    // ||Z_i - M_i||^2 = sqrt((Z_1 - M_i1)^2 + (Z_2 - M_i2)^2)
    return sqrt(pow(a.r - b.r, 2) + pow(a.g - b.g, 2) + pow(a.b - b.b, 2))
  }
```

<br/>

> 1. centroid를 랜덤 한 픽셀의 밝기 값으로 초기화합니다.
> 2. 각 픽셀마다 centroid와의 유클리드 거리를 계산해 유클리드 거리가 짧은 centroid를 참조하는 cluster를 생성합니다.
> 3. centroid 값을 이전에 만든 cluster를 반영해 update 합니다.
> 4. k개의 clusters의 유클리드 총 변화량을 측정하고 이 변화량 임계치 tol보다 작으면 프로그램을 종료하고 assignClusters()를 마지막으로 한 번 더 실행한 후 cluster로 이미지를 만듭니다. (그렇지 않을 경우 2번 부터 반복...)

```swift
func kmeans(points: [RGBPoint],
              k: Int,
              maxLoop: Int = 100,
              tol: Double = 1e-4) -> ([RGBPoint], [Int]) {
    // 1. random 값으로 초기 중심 선택
    var centroids = initializeCentroids(points: points, k: k)
    
    for _ in 0..<maxLoop {
      // 2. ||Z_i - M_i||^2 < ||Z_j - M_j||^2 일 때 Z_i -> S_i
      // 각 포인트를 가장 가까운 클러스터에 할당 -> 픽셀마다 가까운 centroid index값을 저장
      let clusters = assignClusters(pointS: points, centroids: centroids)
      
      // 3. M_i = sum(Z) / S_i
      // cluster 중심 업데이트
      let newCentroids = updateCentroids(points: points, clusters: clusters, k: k)
      
      // 4. 클러스터의 M_i 변화값 임계치 보다 작으면 종료
      // centroid의 변화 distance(크기)를 구함 -> diff 유클리드 거리 변화량
      var diff = 0.0 // 유클리드 변화량 합계
      for i in 0..<k {
        diff += euclideanDistance(a: centroids[i], b: newCentroids[i])
      }
      // 변화량이 임계치T보다 작으면 알고리즘 종료
      if diff < tol { break }
      
      // 실제로 centroids값이 update
      centroids = newCentroids
    }
    
    let finalClusters = assignClusters(pointS: points, centroids: centroids)
    return (centroids, finalClusters)
  }
```

<br/><br/>

# Public Function

### Image to RGBData
> 이미지 데이터를 참조해 RGBPoint Struct에 담고있는 코드 입니다. 이미지데이터는 픽셀마다 R, G, B, A 순으로 1차원 배열에 담겨 반환되므로 코드의 가독성을 높이기 위해 RGBPoint에 담고있습니다.
> R G B 데이터를 정수타입으로 알고리즘을 돌리게 되면 일부 값유실이 발생할 수 있으므로 Double타입으로 바꿔주고있습니다.

```swift
func getRGBPoints(image: UIImage) -> [RGBPoint]? {
    guard let cgImage = image.cgImage else { return nil }
    guard let data = cgImage.dataProvider?.data else { return nil }
    guard let bytes = CFDataGetBytePtr(data) else { return nil } // 8비트 밝기값 추출
    
    let width = cgImage.width
    let height = cgImage.height
    let bytesPerPixel = cgImage.bitsPerPixel / 8
    
    var points = [RGBPoint]()
    
    for y in 0..<height {
      for x in 0..<width {
        let offset = (y * width + x) * bytesPerPixel
        let r = Double(bytes[offset]) / 255.0 // 계산의 일관성을 유지하기 위해 실수 값으로 변환
        let g = Double(bytes[offset + 1]) / 255.0
        let b = Double(bytes[offset + 2]) / 255.0
        points.append(RGBPoint(r: r, g: g, b: b))
      }
    }
    
    return points
  }
  ```

### RGBData to Image
> cluster의 index는 pixel의 index와 똑같은 위치를 가지고있습니다. 그리고 그 cluster는 centroid의 index를 참조하고있습니다.
> 이미지 데이터를 생성 할 때 각 cluster가 참조하고있는 centroid의 밝기값으로 생성하고있습니다.
> 생성된 이미지 데이터는 CGContext를 통해 이미지를 그릴 수 있습니다.

```swift
func createImage(clusters: [Int],
                   centroids: [RGBPoint],
                   width: Int,
                   height: Int) -> UIImage? {
    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * width
    var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
    
    for y in 0..<height {
      for x in 0..<width {
        let offset = (y * width + x) * bytesPerPixel // 4씩 이동하는 index이기 때문에 bytesPerPixel 곱함
        let centroidIndex = clusters[y * width + x]
        let centroid = centroids[centroidIndex]
        
        // centroid의 RGBPoint값으로 할당함
        pixelData[offset] = UInt8(centroid.r * 255.0)
        pixelData[offset + 1] = UInt8(centroid.g * 255.0)
        pixelData[offset + 2] = UInt8(centroid.b * 255.0)
        pixelData[offset + 3] = 255 // Alpha value
      }
    }
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(data: &pixelData, 
                            width: width,
                            height: height,
                            bitsPerComponent: 8,
                            bytesPerRow: bytesPerRow,
                            space: colorSpace,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    
    guard let cgImage = context?.makeImage() else { return nil }
    return UIImage(cgImage: cgImage)
  }
```
