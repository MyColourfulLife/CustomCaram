//
//  ViewController.swift
//  CustomCaram
//
//  Created by 黄家树 on 2017/4/26.
//  Copyright © 2017年 huangjiashu. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    lazy var takeImageBtn:UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("takeImage", for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        return button
    }()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.view.addSubview(self.takeImageBtn)
        
        self.takeImageBtn.center = self.view.center
        
        self.takeImageBtn.addTarget(self, action: #selector(takeImageBtnClick), for: .touchUpInside)
        
        
        
    }

    
    func takeImageBtnClick() {
        
        let customCaramViewController = CustomCaramViewController()
        
        self.present(customCaramViewController, animated: true) { 
            
        }
        
        
        
    }

    

}

