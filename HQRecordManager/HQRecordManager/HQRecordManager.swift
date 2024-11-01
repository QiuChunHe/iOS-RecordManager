//
//  HQRecordManager.swift
//  HQRecordManager
//
//  Created by hcq on 2024/11/1.
//

import Foundation
import AVFoundation

//声明音频文件上传协议
@objc protocol HQUploadAudioFileDelegate{
     @objc func uploadAudioFile(result:String) -> Void
}


@objc class HQRecordManager:NSObject,AVAudioPlayerDelegate{
    
    
    //录音和播放音：整个APP共享一个
    static let sharedInstance = HQRecordManager()
    
     @objc weak var delegate :HQUploadAudioFileDelegate?
     var recorder: AVAudioRecorder?
     var player: AVAudioPlayer?
    let file_path = HQFileManager.documentDirectoryPath?.appending("/record.wav")
    
    
    var normalVoicoAudioFilePath = ""  //标准音路径
    
    //私有化初始化方法
    private override init() {
        
    }
    

    //MARK:开始录音
    @objc func beginRecord(localPath:String) {
        
        HQFileManager.sharedInstance.createFolder(fullPath: localPath)
        
        configAudioSession()
    //录音设置，注意，后面需要转换成NSNumber，如果不转换，你会发现，无法录制音频文件，我猜测是因为底层还是用OC写的原因
        let recordSetting: [String: Any] = [AVSampleRateKey: NSNumber(value: 16000),//采样率
            AVFormatIDKey: NSNumber(value: kAudioFormatLinearPCM),//音频格式
            AVLinearPCMBitDepthKey: NSNumber(value: 16),//采样位数
            AVNumberOfChannelsKey: NSNumber(value: 1),//通道数
            AVEncoderAudioQualityKey: NSNumber(value: AVAudioQuality.medium.rawValue)//录音质量
        ];
        
    
        //开始录音
        do {
            let url = URL(fileURLWithPath: localPath)
            recorder = try AVAudioRecorder(url: url, settings: recordSetting)
            recorder!.prepareToRecord()
            recorder!.record()
            print("开始录音")
                        
        } catch let err {
            print("录音失败:\(err.localizedDescription)")
        }
    }
    
    
    //结束录音
    @objc func stopRecord(localFullURL: String, uploadURL: String) {
        if let recorder = self.recorder {
            if recorder.isRecording {
                print("正在录音，马上结束它，文件保存到了：\(localFullURL)")
            }else {
                print("没有录音，但是依然结束它")
            }
            recorder.stop()
            self.recorder = nil
            printFileSize(filePath: KQTLocalAudioPath.userTmpRecordAudioPathString())
            
            HQFileManager.sharedInstance.createFolder(fullPath: localFullURL)
            
            //转成Mp3：保存到本地和上传到服务器
//            LameConver.init().converWav(KQTLocalAudioPath.userTmpRecordAudioPathString(), toMp3:localFullURL) {
//                self.printFileSize(filePath: localFullURL)
//            }
            
            
            
            
            //录制结束后，需要上传文件到OSS
            do {
                var newUploadURL:String = uploadURL
                // uploadURL 去掉前缀
                if uploadURL.hasPrefix(KQT_RES_WEBSITE + "/") {
                    newUploadURL = uploadURL.substring(fromIndex: KQT_RES_WEBSITE.count + 1)
                    DDLogInfo("putObject/newUploadURL:" + newUploadURL)
                }
                let audioData = try Data(contentsOf: URL(fileURLWithPath: localFullURL))
                self.putObject(audioData: audioData , urlstring: newUploadURL)
            }catch {
                printFileSize(filePath: localFullURL)
            }
            
            
            //创建压缩文件.zip：
//            SSZipArchive.createZipFile(atPath: self.tempZipPath(), withContentsOfDirectory: file_path!, withPassword: nil)
//            SSZipArchive.createZipFile(atPath: self.tempZipPath(), withFilesAtPaths: [file_path!])
            
        }else {
            print("没有初始化")
        }
    }
    
    
    //打印录音文件的大小
    @objc func printFileSize(filePath:String) {
        let manager = FileManager.default
        if manager.fileExists(atPath: filePath) {
            do {
                let attr = try manager.attributesOfItem(atPath: filePath)
                var fileSize : UInt64 = 0
                fileSize = attr[FileAttributeKey.size] as! UInt64
                print(filePath + "[size:\(fileSize)]")
                //16K/16位/单通道/medium 5秒 164096
            } catch let err {
                print("打印文件Size失败:\(err.localizedDescription)")
            }
        }else {
            print("文件不存在")
        }
    }
    
    
    
    
    
    //播放
    @objc func play() -> TimeInterval {
        //解压缩文件
        SSZipArchive.unzipFile(atPath: self.tempZipPath(), toDestination: self.tempUnzipPath()!)
        
        configAudioSession()
        
        do {
            player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: file_path!))
            player?.numberOfLoops = 0
            player?.delegate = self
            player?.volume = 0.8  //0-1
//            print("歌曲长度：\(player!.duration)")
            player?.prepareToPlay()
            player!.play()
            
            return player!.duration
            //还得有暂停，用户自己主动去开始重新播放
            //设置已经播放时长：然后看是否需要播放暂停前的1-3秒
        } catch let err {
            print("播放失败:\(err.localizedDescription)")
            return TimeInterval.init(0.0)
        }
    }
    
    @objc func play(filePath:String) -> TimeInterval{
        
//        configAudioSession()
        
        do {
            player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: filePath))
            player?.numberOfLoops = 0
            player?.delegate = self
            player?.volume = 0.8  //0-1
//            print("歌曲长度：\(player!.duration)")
            player?.prepareToPlay()
            player!.play()
            
            return player!.duration
            //还得有暂停，用户自己主动去开始重新播放
            //设置已经播放时长：然后看是否需要播放暂停前的1-3秒
        } catch let err {
            print("播放失败:\(err.localizedDescription)")
            return TimeInterval.init(0.0)
        }
    }
    
    
    //音频文件路径   开始时间   结束时间,调用方控制(,endTime:TimeInterval)
    @objc func play(filePath:String,startTime:TimeInterval) -> TimeInterval{
            
    //        configAudioSession()
            do {
                player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: filePath))
                player?.numberOfLoops = 0
                player?.delegate = self
                player?.volume = 0.8  //0-1
//                print("歌曲长度：\(player!.duration)")
                player?.currentTime = startTime
                
                player?.prepareToPlay()
                player!.play()
                
                return player!.duration
                //还得有暂停，用户自己主动去开始重新播放
                //设置已经播放时长：然后看是否需要播放暂停前的1-3秒
            } catch let err {
                print("播放失败:\(err.localizedDescription)")
                return TimeInterval.init(0.0)
            }
        }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool){
        print("audioPlayerDidFinishPlaying")
    }
    
    
    /* if an error occurs while decoding it will be reported to the delegate. */
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?){
        print("audioPlayerDecodeErrorDidOccur")
    }
    
    
    deinit {
        print("RecordManager deinit")
    }
    
}


extension HQRecordManager {
    func configAudioSession() {
        let session = AVAudioSession.sharedInstance()
         //设置session类型
         do {
             try session.setCategory(AVAudioSession.Category.playAndRecord)
         } catch let err{
             print("设置类型失败:\(err.localizedDescription)")
         }
         //设置session动作
         do {
             try session.setActive(true)
         } catch let err {
             print("初始化动作失败:\(err.localizedDescription)")
         }
        
         //设置Session播放模式为：扬声器模式，默认是听筒模式
         do {
             try session.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
         } catch let error as NSError {
             print("audioSession error: \(error.localizedDescription)")
         }
    }
    
    
    /// 检测是否开启麦克风
    func hw_openRecordServiceWithBlock(action :@escaping ((Bool)->())) {
        let permissionStatus = AVAudioSession.sharedInstance().recordPermission
        if permissionStatus == AVAudioSession.RecordPermission.undetermined {
            AVAudioSession.sharedInstance().requestRecordPermission { (granted) in
                action(granted)
            }
        } else if permissionStatus == AVAudioSession.RecordPermission.denied {
            action(false)
        } else {
            action(true)
        }
    }
    
    // MARK: - 跳转系统设置界面
    func hw_OpenURL() {
        let url = URL(string: UIApplication.openSettingsURLString)
        let alertController = UIAlertController(title: "访问受限",
                                                message: "点击“设置”，允许访问权限",
                                                preferredStyle: .alert)
        let cancelAction = UIAlertAction(title:"取消", style: .cancel, handler:nil)
        let settingsAction = UIAlertAction(title:"设置", style: .default, handler: {
            (action) -> Void in
            if  UIApplication.shared.canOpenURL(url!) {
                UIApplication.shared.open(url!, options: [:],completionHandler: {(success) in})
                
            }
        })
        alertController.addAction(cancelAction)
        alertController.addAction(settingsAction)
        UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
    
}


extension HQRecordManager {
    func tempZipPath() -> String {
        var path = HQFileManager.documentDirectoryPath!
//        path += "/\(UUID().uuidString).zip"
        path += "/\(123).zip"
        return path
    }

    func tempUnzipPath() -> String? {
        var path = HQFileManager.documentDirectoryPath!
        path += "/\(UUID().uuidString)"
//        path += "/\(123)"
        let url = URL(fileURLWithPath: path)

        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return nil
        }
        return url.path
    }
}



extension HQRecordManager {
    
    func putObject(audioData: Data,urlstring:String) -> Void {
        
        /*音频存储的路径：js返回URL.wav*/
        let objectKey:String = urlstring
        let request = OSSPutObjectRequest()
        request.uploadingData = audioData
        request.bucketName = OSS_BUCKET_PRIVATE
        request.objectKey = objectKey
        //        request.uploadProgress = { (bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) -> Void in
        //            print("bytesSent:\(bytesSent),totalBytesSent:\(totalBytesSent),totalBytesExpectedToSend:\(totalBytesExpectedToSend)");
        //        };
        
        let provider = OSSStsTokenCredentialProvider.init(accessKeyId: OSS_ACCESSKEY_ID, secretKeyId: OSS_SECRETKEY_ID, securityToken: "")
        let client = OSSClient(endpoint: OSS_ENDPOINT, credentialProvider: provider)
        let task = client.putObject(request)
        task.continue({ (t) -> Any? in
            self.showResult(task: t,objectKey:objectKey  ,client: client)
        })//.waitUntilFinished()
        
    }
    
    
    func showResult(task: OSSTask<AnyObject>?,objectKey:String,client:OSSClient) -> Void {
        
        if (task?.error != nil) {
            //显示上传错误
            let error: NSError = (task?.error)! as NSError
            print(error.description)
           
        }else{
            let result = task?.result?.description ?? "空"
            DDLogInfo("OSSClient result:" + result)
        }
    }
    

   
}
