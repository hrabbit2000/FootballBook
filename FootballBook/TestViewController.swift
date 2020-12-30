//
//  TestViewController.swift
//  FootballBook
//
//  Created by eric on 29/09/2016.
//  Copyright © 2016 王 逸平. All rights reserved.
//

import Cocoa
import Foundation






class TestViewController: NSViewController {
    
    
    //data
    var params = ["":""]
    var vCode = ""
    
    @IBOutlet private var mUserWidget: NSTextField!
    @IBOutlet private var mPwdWidget: NSTextField!
    
    
    
    
    
    //api
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    @IBAction func loginClicked(sender: NSButton) {
        let params = ["CardNo": "26733",
                      "PassWord": "135792468fb"
                     ]
        do {
            let opt = try HTTP.POST(g_login_url, parameters: params)
            opt.start { response in
                if let err = response.error {
                    print("error: \(err.localizedDescription)")
                    return
                }
                print("获取到数据: \(String(describing: response.text))")            }
        } catch let error {
            print("请求失败: \(error)")
        }
    }

    
    @IBAction func step2Clicked(sender: NSButton) {
        NSLog("Step Two");
        //
        do {
            let opt = try HTTP.GET(g_book_center_url, parameters: nil)
            opt.start { response in
                if let err = response.error {
                    print("error: \(err.localizedDescription)")
                    return
                }
                print("获取到数据: \(String(describing: response.text))")
                self.params = Utils.analyzeViewForm((response.text)!)
            }
        } catch let error {
            print("请求失败: \(error)")
        }
    }

    
    @IBAction func step3Clicked(sender: NSButton) {
        NSLog("Step Three");
        //
        do {
            var dic = self.params
            dic["StadiumID"] = "1841e8a7-b2b5-4196-9e24-f4a53552ef0a"
            dic["CardType"] = "普通卡"
            let opt = try HTTP.POST(g_book_stadium_url, parameters: dic)
            opt.start { response in
                if let err = response.error {
                    print("error: \(err.localizedDescription)")
                    return
                }
                //print("获取到数据: \(response.text)")
                self.params = Utils.analyzeViewForm((response.text)!)
            }
        } catch let error {
            print("请求失败: \(error)")
        }
    }

    @IBAction func bookClicked(sender: NSButton) {
        NSLog("Step book");
        //
        do {
            var dic = self.params
            dic["AreaID"] = "a3915c4a-6bdc-43e6-8931-5293843fc540"
            dic["ApplyTime"] = "2016-10-4 14:00"
            let opt = try HTTP.POST(g_book_url, parameters: dic)
            opt.start { response in
                if let err = response.error {
                    print("error: \(err.localizedDescription)")
                    return
                }
                print("获取到数据: \(String(describing: response.text))")
                self.params = Utils.analyzeViewForm((response.text)!)
            }
        } catch let error {
            print("请求失败: \(error)")
        }
    }
    
    
    @IBAction func realBookClicked(sender: NSButton) {
        
        refreshImgClicked(sender: NSButton())
        //
        do {
            var dic = self.params
            dic["rblEndTime"] = "15:00"
            dic["btnSave"] = "预+订"
            dic["tbxCode"] = vCode
            dic["__LASTFOCUS"] = ""
            let opt = try HTTP.POST(g_book_url, parameters: dic)
            opt.start { response in
                if let err = response.error {
                    print("error: \(err.localizedDescription)")
                    return
                }
                print("获取到数据: \(String(describing: response.text))")
            }
        } catch let error {
            print("请求失败: \(error)")
        }
        
    }
    
    
    @IBAction func listClicked(sender: NSButton) {
        NSLog("Step list");
        
        self.params = ["page": "1", "Type": "Booked", "CardID": "73eb4673-2024-4c03-8052-6990daa1b07c"]
        do {
            let opt = try HTTP.GET(g_book_list_rec, parameters: self.params)
            opt.start { response in
                if let err = response.error {
                    print("error: \(err.localizedDescription)")
                    return
                }
                print("获取到数据: \(String(describing: response.text))")
            }
        } catch let error {
            print("请求失败: \(error)")
        }
    }

    
    
    @IBAction func cancelClicked(sender: NSButton) {
        NSLog("Step list");
                
        self.params = ["ID": "c9d9da27-d6fc-49af-a085-2e159e302c35"]
        do {
            let opt = try HTTP.GET(g_book_detail_rec, parameters: self.params)
            opt.start { response in
                if let err = response.error {
                    print("error: \(err.localizedDescription)")
                    return
                }
                self.params = Utils.analyzeViewForm((response.text)!)
                
                do {
                    self.params["ctl00$ContentPlaceHolder1$btnCancel"] = "取消预订"
                    let cancelUrl = g_book_detail_rec.appending("?ID=b4f0b4a4-f10a-4cfc-93b5-48aa84b484c4")
                    let opt1 = try HTTP.GET(cancelUrl, parameters: self.params)
                    opt1.start { response1 in
                        if let err = response1.error {
                            print("error: \(err.localizedDescription)")
                            return
                        }
                    }
                } catch {}
                
                
            }
        } catch let error {
            print("请求失败: \(error)")
        }
    }

    
    

    @IBAction func refreshImgClicked(sender: NSButton) {
        
        let url = URL.init(string: g_book_image_url)
        var imgData = Data()
        var succ = false
        
        while(!succ) {
            
            do {
                try imgData = Data.init(contentsOf: url!)
                var savePath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
                savePath = savePath.appending("/football_img.jpg")
                let data = NSData.init(data: imgData)
                data.write(toFile: savePath, atomically: false)
                let str:String! = [ImgRecBridger .getString(savePath)][0]
                if (4 == str.count) {
                    vCode = str
                    succ = true;
                }
            } catch {}

        } //while
    }
    
    
    @IBAction func addUserClicked(sender: NSButton) {
        Utils.addUser(id: mUserWidget.stringValue, pwd: mPwdWidget.stringValue)
    }
    
    
    
}








