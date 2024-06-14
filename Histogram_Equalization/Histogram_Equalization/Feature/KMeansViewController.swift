//
//  K-MeansViewController.swift
//  Histogram_Equalization
//
//  Created by 이치훈 on 6/14/24.
//

import SnapKit
import UIKit

class KMeansViewController: UIViewController {
  
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
  
  // MARK: - LifeCycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view.backgroundColor = .white
    self.configureSubviews()
  }
  
}

// MARK: - LayoutSupport

extension KMeansViewController: LayoutSupport {
  
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
