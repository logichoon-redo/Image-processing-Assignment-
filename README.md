# Image Processing Assignment

### Histogram Equalization
<img width="445" alt="스크린샷 2024-05-08 오후 4 41 29" src="https://github.com/logichoon-redo/Image-processing-Assignment-/assets/117021317/c24ae8ed-1419-4bb2-8c01-def889ef09fa">



### K-Means Algorithm
<img width="445" alt="스크린샷 2024-05-08 오후 4 41 29" src="https://github.com/logichoon-redo/Image-processing-Assignment-/blob/6b92285e4052be80bff0bf1e3942ea73003fd690/%E1%84%89%E1%85%B3%E1%84%8F%E1%85%B3%E1%84%85%E1%85%B5%E1%86%AB%E1%84%89%E1%85%A3%E1%86%BA%202024-06-22%20%E1%84%8B%E1%85%A9%E1%84%8C%E1%85%A5%E1%86%AB%2010.55.18.png">



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
