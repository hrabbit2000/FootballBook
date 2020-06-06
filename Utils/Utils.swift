//
//  Utils.swift
//  FootballBook
//
//  Created by eric on 01/10/2016.
//  Copyright © 2016 王 逸平. All rights reserved.
//

import Foundation
import Cocoa

let g_login_url         = "http://www.jiadingsports.com/JdSportBureau_new/Yikatong/HtmlHelper/NewLoginHandler.ashx"
let g_book_center_url   = "http://www.jiadingsports.com/JdSportBureau_new/Yikatong/NewBookingCenter.aspx"
let g_book_stadium_url  = "http://www.jiadingsports.com/JdSportBureau_new/Yikatong/NewBookingIndex.aspx"
let g_book_url          = "http://www.jiadingsports.com/JdSportBureau_new/Yikatong/BookingSheet.aspx"
let g_book_image_url    = "http://www.jiadingsports.com/JdSportBureau_new/Yikatong/GetImage.aspx"
let g_book_list_rec     = "http://www.jiadingsports.com/JdSportBureau_new/Yikatong/HtmlHelper/GetRecordsList.ashx"
let g_book_detail_rec   = "http://www.jiadingsports.com/JdSportBureau_new/Yikatong/BookingDetail.aspx"


//定义协议
public protocol callBackDelegate {
    func callbackDelegatefuc(_ backMsg:String)
}

open class ProcessData: NSObject{
    //定义一个符合改协议的代理对象
    var delegate:callBackDelegate?
    func processMethod(_ cmdStr:String?){
        if((delegate) != nil){
            delegate?.callbackDelegatefuc(cmdStr!)
        }
    }
}

open class Utils : NSObject {
    
    public enum EBookState {
        case e_logouted
        case e_logined
        case e_prepared
        case e_codeConfirmed
        case e_booking
        case e_bookFinishing
        case e_bookFinished
    }

    public enum EBookSucessState {
        case e_unknown
        case e_sucessed
        case e_failed
        case e_continue
    }

    /*
     体育场 sid: e6aff278-d523-42fa-9566-6bad1bca37f2, atd: 0e759218-3806-4118-9e32-503fd4b4c096
     迎园中学 sid: 1841e8a7-b2b5-4196-9e24-f4a53552ef0a, aid: a3915c4a-6bdc-43e6-8931-5293843fc540
     南翔: sid: 666a18fd-ac6e-40a7-9322-e6b54f46cedb, aid: 73a96bbe-4e4c-43af-af65-6b0fd2efee77
     */
    
    
    //data
    static private var mInAdvanceMins = 1
    static private var mUsers = Dictionary<String, String>()
    static private var mBookTriggerTime: Date!
    static private var mPrepareTriggerTime: Date!
    static private var mLocalInfos = [
                                      "迎园中学" : ["1841e8a7-b2b5-4196-9e24-f4a53552ef0a", "a3915c4a-6bdc-43e6-8931-5293843fc540"],
                                      "体育场" : ["e6aff278-d523-42fa-9566-6bad1bca37f2", "0e759218-3806-4118-9e32-503fd4b4c096"],
                                      "南翔" : ["666a18fd-ac6e-40a7-9322-e6b54f46cedb", "73a96bbe-4e4c-43af-af65-6b0fd2efee77"]
                                     ]
    
    //static private var mLogString: String!
    static private var mLogDelegate = ProcessData()
    
    //api
    
    open class func setLogDelegate(_ delegate: callBackDelegate) {
        mLogDelegate.delegate = delegate
    }
    
    open class func log(_ text: String) {
        mLogDelegate.processMethod(text)
    }
    
    open class func analyzeViewForm(_ text: String)->Dictionary<String, String> {
        let viewState = getStringValue(text: text, key: "\"__VIEWSTATE\" value=\"")
        return ["__EVENTTARGET": "", "__EVENTARGUMENT": "", "__VIEWSTATE": viewState]
    }
    
    open class func setInAdvanceMins(_ mins: Int) {
        mInAdvanceMins = mins
    }
    
    private class func getStringValue(text: String, key: String)->String {
        var resStr = ""
        
        do {
            let pattern = key.appending("[^\"]+")
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSMakeRange(0, text.utf16.count)
            let res = regex.rangeOfFirstMatch(in: text, options: NSRegularExpression.MatchingOptions.reportCompletion, range: range)
            
            if (0 != res.length) {
                resStr = (text as NSString).substring(with: res)
                resStr = (resStr as NSString).substring(from: key.utf16.count)
            }
        } catch {
            print(error)
        }
        
        return resStr
    }
    
    open class func getBookResult(text: String)->String {
        var resStr = ""
        var key: String = "alert\\(\'"
        
        do {
            let pattern = key.appending("[^\']+")
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSMakeRange(0, text.utf16.count)
            let res = regex.rangeOfFirstMatch(in: text, options: NSRegularExpression.MatchingOptions.reportCompletion, range: range)
            
            if (0 != res.length) {
                resStr = (text as NSString).substring(with: res)
                resStr = (resStr as NSString).substring(from: key.utf16.count - 1)
            }
        } catch {
            print(error)
        }
        
        return resStr
    }
    
    
    open class func checkBookSucessState(text: String)->EBookSucessState {
        var state = EBookSucessState.e_failed
        let needCntinue = "天以内的场馆"
        let sucessed = "预定成功"
        let booked = "一个场地"
        let code_error = "验证码错误"
        let other_booked = "已被申请"
        if (text.contains(sucessed)) {
            state = EBookSucessState.e_sucessed
        } else if (text.contains(needCntinue)) {
            state = EBookSucessState.e_continue
        } else if (text.contains(booked)) {
            state = EBookSucessState.e_sucessed
        } else if (text.contains(code_error)) {
            state = EBookSucessState.e_continue
        } else if (text.contains(other_booked)) {
            state = EBookSucessState.e_failed
        }

        return state
    }
    
    open class func addUser(id: String, pwd: String) {
        mUsers[id] = pwd
        UserDefaults.standard.set(mUsers, forKey: "users")
        UserDefaults.standard.synchronize()
    }
    
    open class func allUsers() -> [String] {
        var users = [String]()
        for key in mUsers.keys {
            users.append(key)
        }
        return users
    }
    
    open class func userInfo(id: String)->String {
        var pwd = ""
        for key in mUsers.keys {
            if (id == key) {
                pwd = mUsers[id]!
                break
            }
        }
        
        return pwd
    }
    
    open class func restoreUsers() {
        if (nil != UserDefaults.standard.dictionary(forKey: "users")) {
            mUsers = UserDefaults.standard.dictionary(forKey: "users") as! Dictionary<String, String>
        } else {
            mUsers["26733"] = "135792468fb";
        }
    }
    
    open class func getPrepareTriggerTime()->Date {
        if (nil == mPrepareTriggerTime) {
            var dateComp = Calendar.current.dateComponents(in: Calendar.current.timeZone, from: Date())
            dateComp.hour = 21; dateComp.minute = 60 - mInAdvanceMins; dateComp.second = 30
            mPrepareTriggerTime = Calendar.current.date(from: dateComp)
        }
        
        return mPrepareTriggerTime
    }

    open class func getBookTriggerTime()->Date {
        if (nil == mBookTriggerTime) {
            var dateComp = Calendar.current.dateComponents(in: Calendar.current.timeZone, from: Date())
            dateComp.hour = 21; dateComp.minute = 60 - mInAdvanceMins; dateComp.second = 56
            mBookTriggerTime = Calendar.current.date(from: dateComp)
        }
        
        return mBookTriggerTime
    }
    
    open class func getDefaultBookDate()->Date {
        var dateComp = Calendar.current.dateComponents(in: Calendar.current.timeZone, from: Date())
        dateComp.day = dateComp.day! + 3; dateComp.hour = 19; dateComp.minute = 0; dateComp.second = 0
        return Calendar.current.date(from: dateComp)!
    }
    
    open class func allLocals()->[String] {
        var locals = [String]()
        for key in mLocalInfos.keys {
            locals.append(key)
        }
        return locals
    }
    
    open class func getLocalSId(name: String)->String {
        var info = mLocalInfos[name]
        return info![0]
    }

    open class func getLocalAId(name: String)->String {
        var info = mLocalInfos[name]
        return info![1]
    }
    
    open class func generateBookStartTimeInfo(date: Date)->String {
        let flags:Set<Calendar.Component> = [Calendar.Component.year, Calendar.Component.month, Calendar.Component.day, Calendar.Component.hour]
        let dataComp = Calendar.current.dateComponents(flags, from: date)
        return String.init(format: "%ld-%ld-%ld %ld:00", dataComp.year!, dataComp.month!, dataComp.day!, dataComp.hour!);
    }


}






