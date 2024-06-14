//
//  TabBarController.swift
//  Histogram_Equalization
//
//  Created by 이치훈 on 6/14/24.
//

import UIKit

class TabBarController: UITabBarController {
  
  let histEqualizationController = HistEqualizationViewController()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setTabBarItem()
  }
  
  private func setTabBarItem() {
    histEqualizationController.tabBarItem = UITabBarItem(title: "Hist_Equalization", image: UIImage(systemName: "chart.bar.xaxis.ascending"), tag: 0)
    
    self.viewControllers = [histEqualizationController]
  }
  
}

extension TabBarController {
  
  func setTabBarLayout() {
    
  }
  
}
