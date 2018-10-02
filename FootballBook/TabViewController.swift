//
//  TestTabController.swift
//  FootballBook
//
//  Created by eric on 29/09/2016.
//  Copyright © 2016 王 逸平. All rights reserved.
//

import Cocoa
import Foundation

class TabViewController: NSTabViewController {
    
    override func viewDidLoad() {
        
        Utils.restoreUsers()
        
        let bundlePath = Bundle.main.pathForImageResource("0.png")
        let lettersPath = bundlePath!.components(separatedBy: "0.png")[0]
        [ImgRecBridger .initImgRec(lettersPath)]

        super.viewDidLoad()
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    
}
