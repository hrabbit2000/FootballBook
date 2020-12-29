//
//  ViewController.swift
//  FootballBook
//
//  Created by eric on 29/09/2016.
//  Copyright © 2016 王 逸平. All rights reserved.
//

import Cocoa

class BookViewController: NSViewController, callBackDelegate {

    //scroll view
    @IBOutlet var mMainView: NSView!
    @IBOutlet var mShowTimeWidget: NSTextField!
    @IBOutlet var mLogView: NSView!
    @IBOutlet var mInfoText: NSTextView!
    private var mControllers = [NSViewController]()
    private var mTimer: Timer = Timer()
    private var mLogText: String = String("")
    private var mLock: Int = 0
    //api
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        createOneCellCtl()
        Utils.setLogDelegate(self)
        HTTP.globalRequest { req in
            req.timeoutInterval = 6
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        setupTimer()
        uiInitial()
    }
    
    private func uiInitial() {
        //function view
        mControllers[0].view.frame.origin.y = mMainView.frame.size.height - mControllers[0].view.frame.size.height
        //log view
        mLogView.frame = mMainView.frame
        mLogView.frame.size.height = mInfoText.frame.size.height - mControllers[0].view.frame.size.height
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    private func createOneCellCtl()->Any? {
        let ctl = NSStoryboard(name:"Main", bundle: nil).instantiateController(withIdentifier: "BookCellViewController") as! NSViewController
        mMainView.addSubview(ctl.view)
        mControllers.append(ctl)
        
        return ctl
    }
    
    private func setupTimer() {
        if #available(OSX 10.12, *) {
            mTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30, repeats: true, block: {timer in self.maiLoop()})
        } else {
            // Fallback on earlier versions
            mTimer = Timer.scheduledTimer(timeInterval: 1.0 / 30, target: self, selector: #selector(maiLoopCaller), userInfo: nil, repeats: true)
        }
    }
    
    @objc private func maiLoopCaller() -> Void {
        maiLoop()
    }
    
    private func maiLoop() {
        
        updateShowTime()
        updateLogView()
        
        for ctl in mControllers {
            if (ctl.isKind(of: BookCellViewController.self)) {
                (ctl as! BookCellViewController).update()
            }
        }
    }
    
    private func updateShowTime() {
        let dateComp = Calendar.current.dateComponents([Calendar.Component.hour, Calendar.Component.minute, Calendar.Component.second], from: Date())
        mShowTimeWidget.stringValue = String.init(format: "%02ld : %02ld : %02ld", dateComp.hour!, dateComp.minute!, dateComp.second!);
    }
    
    var count = 0;
    private func updateLogView() {
        
        self.count += 1
        
        if (self.count % 4 == 0) {
            objc_sync_enter(mLock)
            mInfoText.string! = mLogText
            objc_sync_exit(mLock)
            mInfoText.scrollRangeToVisible(NSMakeRange((mInfoText.string?.lengthOfBytes(using: String.Encoding.utf8))!, 0))
            
            self.count = 0
        }
    }
    
    private func remove_string(_ sub: String) {
        if let range = mLogText.range(of:sub, options: .backwards) {
            if !range.isEmpty {
                mLogText.removeSubrange(range)
            }
        }
    }
    
    func callbackDelegatefuc(_ backMsg: String) {
        objc_sync_enter(mLock)
        let sub = "Booking"
        if (backMsg.contains(sub)) {
            remove_string("Booking .....\n")
            remove_string("Booking ....\n")
            remove_string("Booking ...\n")
            remove_string("Booking ..\n")
            remove_string("Booking .\n")
        }
        mLogText += (backMsg + "\n")
        objc_sync_exit(mLock)
//        let str : String! = mInfoText.string
    }

}








