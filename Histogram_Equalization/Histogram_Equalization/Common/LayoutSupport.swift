//
//  LayoutSupport.swift
//  Histogram_Equalization
//
//  Created by 이치훈 on 4/7/24.
//

import Foundation

///UIView type's default configure
protocol LayoutSupport {
  
  /// Combine setupview's all configuration
  func configureSubviews()
  
  /// Add view to view's subview
  func addSubviews()
  
  ///Use ConfigureUI.setupConstraints(detail:apply:)
  func setupSubviewsConstraints()
  
}
