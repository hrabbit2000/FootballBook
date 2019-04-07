//
//  BookCellViewController.swift
//  FootballBook
//
//  Created by eric on 01/10/2016.
//  Copyright © 2016 王 逸平. All rights reserved.
//

import Foundation
import Cocoa


class BookCellViewController: NSViewController {
    
    //widget & data
    
    @IBOutlet private var mLocalListWidget: NSComboBox!
    @IBOutlet private var mUserListWidget: NSComboBox!
    @IBOutlet private var mTriggerBtn: NSButton!
    @IBOutlet private var mDatePicker: NSDatePicker!
    @IBOutlet private var mDurationWidget: NSComboBox!
    @IBOutlet private var mBookInAdvanceWidget: NSComboBox!
    
    private var mBookProcess = BookProcess()
    private var mBookingImmediately = false
    
    //api
    override func viewDidLoad() {
        super.viewDidLoad()
        mUserListWidget.removeAllItems()
        mUserListWidget.addItems(withObjectValues: Utils.allUsers())
        mUserListWidget.selectItem(at: 0)
        
        mLocalListWidget.removeAllItems()
        mLocalListWidget.addItems(withObjectValues: Utils.allLocals())
        mLocalListWidget.selectItem(at: 2)
        
        mDatePicker.dateValue = Utils.getDefaultBookDate()
        mDurationWidget.selectItem(at: 1)
        mBookInAdvanceWidget.selectItem(at: 0)
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    open func update() {
        switch mBookProcess.getBookState() {
        case Utils.EBookState.e_logouted:
            if (hasOverPrepareTriggerTime() || mBookingImmediately) {
                doLogin()
            }
            break
        case Utils.EBookState.e_logined:
            doPrepare()
            break
        case Utils.EBookState.e_prepared:
            doConfirmVerifyCode()
            break
        case Utils.EBookState.e_codeConfirmed:
            if (hasOverBookTriggerTime() || mBookingImmediately) {
                doBook()
            }
            break
        case Utils.EBookState.e_bookFinishing:
            if (true == mBookProcess.isAllBookingRequestsFinished())
            {
                if (Utils.EBookSucessState.e_failed == mBookProcess.getBookResult()) {
                    Utils.log("Book Failed !!!")
                } else if (Utils.EBookSucessState.e_sucessed == mBookProcess.getBookResult()) {
                    Utils.log("Book Successfull !!!")
                } else {
                    Utils.log("Book Finished !!!")
                }
                
                mTriggerBtn.isEnabled = true
            }
            break
        case Utils.EBookState.e_bookFinished:
            break
        default:
            break
        }
    }

    private func hasOverPrepareTriggerTime()-> Bool {
        if (Date().compare(Utils.getPrepareTriggerTime()) != ComparisonResult.orderedAscending) {
            return true
        }
        return false
    }

    private func hasOverBookTriggerTime()-> Bool {
        if (Date().compare(Utils.getBookTriggerTime()) != ComparisonResult.orderedAscending) {
            return true
        }
        return false
    }
    
    @IBAction func triggerBtnClicked(sender: NSButton) {
        let start = "Start"
        let cancel = "Cancel"
        if (start == sender.title) {
            sender.title = cancel
            mBookProcess.reset()
            Utils.setInAdvanceMins(Int.init(mBookInAdvanceWidget.stringValue)!)
            Utils.log("Starting !!!")
        } else {
            sender.title = start
            mTriggerBtn.isEnabled = false
            mBookProcess.cancle()
            Utils.log("Canceled !!!")
        }
    }
    
    @IBAction func immediatelyBtnClicked(sender: NSButton) {
        mBookingImmediately = (sender.state == 1) ? true : false
    }
    
    private func generateBookStartTimeInfo()->String {
        let flags:Set<Calendar.Component> = [Calendar.Component.year, Calendar.Component.month, Calendar.Component.day, Calendar.Component.hour]
        let dataComp = Calendar.current.dateComponents(flags, from: mDatePicker.dateValue)
        return String.init(format: "%ld-%ld-%ld %ld:00", dataComp.year!, dataComp.month!, dataComp.day!, dataComp.hour!);
    }
    
    private func doLogin() {
        if (mBookProcess.doLogin(user: mUserListWidget.stringValue, pwd: Utils.userInfo(id: mUserListWidget.stringValue))) {
            Utils.log("Login Finishe !!!")
        }
    }
    
    private func doPrepare() {
        if (mBookProcess.doPrepare(stadium: self.mLocalListWidget.stringValue, date: mDatePicker.dateValue)) {
            Utils.log("Prepare Finishe !!!")
        }
    }
    
    private func doConfirmVerifyCode() {
        if (mBookProcess.doConfirmVerifyCode(start: mDatePicker.dateValue, duration: Int.init(mDurationWidget.stringValue)!)) {
            Utils.log("Confirm verify code finished !!!")
        }
    }
    
    private func doBook() {
        mBookProcess.doBook(start: mDatePicker.dateValue, duration: Int.init(mDurationWidget.stringValue)!)
    }
    
}
























