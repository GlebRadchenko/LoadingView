//
//  ViewController.swift
//  LoadingView
//
//  Created by Gleb Radchenko on 4/9/17.
//  Copyright © 2017 Gleb Radchenko. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var loadingView: LoadStatusView!
    
    var progress: Float = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateProgress()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func updateProgress() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.progress += 0.25
            self.progress = truncf(self.progress * 10) / 10
            if self.progress > 1 {
                self.progress = 0
            }
            self.loadingView.set(progress: self.progress)
            self.updateProgress()
        }
    }
}

