//
//  TabBarController.swift
//  Histogram_Equalization
//
//  Created by 이치훈 on 6/14/24.
//

import UIKit

class TabBarController: UITabBarController {
  
  let histEqualizationController = HistEqualizationViewController()
  let kmeansViewController = KmeansViewController()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setTabBarItem()
  }
  
  private func setTabBarItem() {
    histEqualizationController.tabBarItem = UITabBarItem(title: "Hist_Equalization", image: UIImage(systemName: "chart.bar.xaxis.ascending"), tag: 0)
    kmeansViewController.tabBarItem = UITabBarItem(title: "K-Means", image: UIImage(systemName: "chart.pie.fill"), tag: 1)
    
    self.viewControllers = [histEqualizationController, kmeansViewController]
  }
  
}
