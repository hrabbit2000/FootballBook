//
//  BookProcess.swift
//  FootballBook
//
//  Created by eric on 03/10/2016.
//  Copyright © 2016 王 逸平. All rights reserved.
//

import Cocoa
import Foundation

class BookProcess: NSObject {

    //data
    private var mBookState = Utils.EBookState.e_logouted
    private var mEBookSucessState = Utils.EBookSucessState.e_unknown
    private var mBookParams = ["":""]
    private var mVerifyCode = ""
    private var mTimer = Timer()
    
    //api
    open func getBookState()->Utils.EBookState {
        return mBookState
    }

    open func getBookResult()->Utils.EBookSucessState {
        return mEBookSucessState
    }

    open func reset() {
        mBookState = Utils.EBookState.e_logouted
        mEBookSucessState = Utils.EBookSucessState.e_unknown
        mVerifyCode = ""
        mBookParams = ["":""]
        mTimer.invalidate()
    }
    
    private func refreshVerifyImg()->String {
        
        let url = URL.init(string: g_book_image_url)
        var imgData = Data()
        var succ = false
        var vCode = ""
        
        while(!succ) {
            
            do {
                try imgData = Data.init(contentsOf: url!)
                var savePath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
                savePath = savePath.appending("/football_img.jpg")
                let data = NSData.init(data: imgData)
                data.write(toFile: savePath, atomically: false)
                let str:String! = [ImgRecBridger .getString(savePath)][0]
                if (4 == str.characters.count) {
                    vCode = str
                    succ = true
                }
            } catch {}
            
        } //while
        
        return vCode
    }

    
    private func login(user: String, pwd: String)->Bool {
        var res = false
        let params = ["CardNo": user,
                      "PassWord": pwd
        ]
        do {
            //1. log in
            let opt = try HTTP.POST(g_login_url, parameters: params)
            opt.start { response in
                if (nil != response.error) {
                    return
                }
                res = true
            }
        
            //refereence point in file 'Operation.swift': Eric: Exchanged execution
            opt.waitUntilFinished()

        } catch {}
        
        return res
    }
    
    private func visitBookCenter()->Bool {
        var res = false
        do {
            let opt = try HTTP.GET(g_book_center_url, parameters: nil)
            opt.start { response in
                if (nil != response.error) {
                    return
                }
                self.mBookParams = Utils.analyzeViewForm((response.text)!)
                res = true
            }
            
            opt.waitUntilFinished()
            
        } catch {}//1. end

        return res
    }
    
    private func visitStadiumDetail(stadium: String)->Bool {
        var res = false
        do {
            var dic = self.mBookParams
            dic["StadiumID"] = Utils.getLocalSId(name: stadium)
            dic["CardType"] = "普通卡"
            let opt = try HTTP.POST(g_book_stadium_url, parameters: dic)
            opt.start { response in
                if (nil != response.error) {
                    return
                }
                self.mBookParams = Utils.analyzeViewForm((response.text)!)
                res = true
            }
            
            opt.waitUntilFinished()
            
        } catch {}
        
        return res
    }
    
    private func confirmStartTime(stadium: String, date: Date)->Bool {
        var res = false
        do {
            var dic = self.mBookParams
            dic["AreaID"] = Utils.getLocalAId(name: stadium)
            dic["ApplyTime"] = Utils.generateBookStartTimeInfo(date: date)
            let opt = try HTTP.POST(g_book_url, parameters: dic)
            opt.start { response in
                if (nil != response.error) {
                    return
                }
                self.mBookParams = Utils.analyzeViewForm((response.text)!)
                res = true
            }
            
            opt.waitUntilFinished()
            
        } catch {}
        
        return res
    }
    
    private func confirmVerifyCode(start: Date)->Bool {
        var res = true
//        let vCode = refreshVerifyImg()
//        do {
//            let flags:Set<Calendar.Component> = [Calendar.Component.hour]
//            let dataComp = Calendar.current.dateComponents(flags, from: start)
//            var dic = self.mBookParams
//            dic["rblEndTime"] = "-1:00"
//            dic["btnSave"] = "预+订"
//            dic["tbxCode"] = vCode
//            dic["__LASTFOCUS"] = ""
//            let opt = try HTTP.POST(g_book_url, parameters: dic)
//            opt.start { response in
//                if (nil != response.error) {
//                    return
//                }
//
//                self.mBookParams = Utils.analyzeViewForm((response.text)!)
//                if(!Utils.getBookResult(text: response.text!).contains("验证码错误")) {
//                    self.mVerifyCode = vCode
//                    res = true;
//                }
//            }
//
//            opt.waitUntilFinished()
//
//        } catch {}
        
        return res
    }
    
    private func book(start: Date, duration: Int)->String {
        var res = ""
        if (mVerifyCode == "")
        {
            mVerifyCode = refreshVerifyImg()
        }
        do {
            var dic = self.mBookParams
            let flags:Set<Calendar.Component> = [Calendar.Component.hour]
            let dataComp = Calendar.current.dateComponents(flags, from: start)
            
            dic["rblEndTime"] = String.init(format: "%d:00", dataComp.hour! + duration)
            dic["btnSave"] = "预+订"
            dic["tbxCode"] = mVerifyCode
            dic["__LASTFOCUS"] = ""
            let opt = try HTTP.POST(g_book_url, parameters: dic)
            opt.start { response in
                if (nil != response.error) {
                    return
                }
                
                self.mBookParams = Utils.analyzeViewForm((response.text)!)
                res = Utils.getBookResult(text: response.text!)
                if (res.contains("验证码错误"))
                {
                    self.mVerifyCode = ""
                }
                DispatchQueue.main.async(execute: {
                    Utils.log(res)
                });
            }
            
            opt.waitUntilFinished()
            
        } catch {}
        
        return res
    }
    
    func booking(timer: Timer) {
        let dic = timer.userInfo as! Dictionary<String, Any>
        let resStr = book(start: dic["start"]! as! Date, duration: dic["duration"] as! Int)
        if ("" != resStr) {
            mEBookSucessState = Utils.checkBookSucessState(text: resStr)
            if (Utils.EBookSucessState.e_continue != mEBookSucessState) {
                mBookState = Utils.EBookState.e_bookFinished
                mTimer.invalidate()
            }
        }
    }
    
    //
    open func doLogin(user: String, pwd: String)->Bool {
        if(true == login(user: user, pwd: pwd)) {
            mBookState = Utils.EBookState.e_logined
        }
        
        return Utils.EBookState.e_logined == mBookState
    }
    
    open func doPrepare(stadium: String, date: Date)->Bool {
        if (true == visitBookCenter()) {
            if (true == visitStadiumDetail(stadium: stadium)) {
                if (true == confirmStartTime(stadium: stadium, date: date)) {
                    mBookState = Utils.EBookState.e_prepared
                }
            }
        }
        
        return Utils.EBookState.e_prepared == mBookState
    }
    
    open func doConfirmVerifyCode(start: Date)->Bool {
        if (true == confirmVerifyCode(start: start)) {
            mBookState = Utils.EBookState.e_codeConfirmed
        }
        
        return Utils.EBookState.e_codeConfirmed == mBookState
    }
    
    open func doBook(start: Date, duration: Int) {
        //posix_spawnp
        mBookState = Utils.EBookState.e_booking
        let dic = ["start":start, "duration":duration] as [String : Any]
        mTimer = Timer.scheduledTimer(timeInterval: 1.0 / 6, target:self, selector: #selector(BookProcess.booking), userInfo: dic, repeats: true)
    }
    
}





















