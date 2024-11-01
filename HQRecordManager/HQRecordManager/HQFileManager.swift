//
//  HQFileManager.swift
//  HQRecordManager
//
//  Created by hcq on 2024/11/1.
//

import Foundation
import ObjectMapper

//文件管理类 HQFileManager
extension HQFileManager {
    
    //创建文件夹:需要全路径
    func createFolder(fullPath:String){
        let path = (fullPath).deletingLastPathComponent //去除最后一个参数
        
        let url = URL.init(fileURLWithPath: path)
        
        let fm = FileManager.default
        let exist = fm.fileExists(atPath: url.path)
        if !exist {
            print("文件夹: \(path)")
            try! fm.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
        
    }
    
}


//MARK: - 获取文件大小
extension HQFileManager {
     //获取单个文件的大小
       class func sizeForLocalFilePath(filePath:String) -> UInt64 {
            do {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: filePath)
                if let fileSize = fileAttributes[FileAttributeKey.size]  {
                    return (fileSize as! NSNumber).uint64Value
                } else {
                    print("Failed to get a size attribute from path: \(filePath)")
                }
            } catch {
                print("Failed to get file attributes for local path: \(filePath) with error: \(error)")
            }
            return 0
        }
        
        //计算句子集合，文件的总的大小
        class func calculateSentencesFilesSize(sentences:[Sentence]) -> String{
            //多少K，超过1024K的用M为单位
            var filesSize:UInt64 = 0
            for sentence in sentences {
                //需要先判断文件是否存在：
                if let audioUrl = sentence.audioUrl {
                    
                    let localNormalAudioFullURL = KQTLocalAudioPath.normalAudioPathString(audioUrl)//本地音频路径
                    let isExists = FileManager.default.fileExists(atPath: localNormalAudioFullURL)
                    if isExists {
                        let size = HQFileManager.sizeForLocalFilePath(filePath: localNormalAudioFullURL)
                        filesSize += size
                    }
                }
            }
            return HQFileManager.covertToFileString(with: filesSize)
        }
        
        class func covertToFileString(with size: UInt64) -> String {
            var convertedValue: Double = Double(size)
            var multiplyFactor = 0
            let tokens = ["KB", "MB", "GB", "TB", "PB",  "EB",  "ZB", "YB"]
            convertedValue /= 1024
            while convertedValue > 1024 {
                convertedValue /= 1024
                multiplyFactor += 1
            }
            return String(format: "%4.2f %@", convertedValue, tokens[multiplyFactor])
        }
    
    /*
    class func covertToFileString1(with size: UInt64) -> String {
        var convertedValue: Double = Double(size)
        var multiplyFactor = 0
        let tokens = ["Bytes", "KB", "MB", "GB", "TB", "PB",  "EB",  "ZB", "YB"]
        while convertedValue > 1024 {
            convertedValue /= 1024
            multiplyFactor += 1
        }
        return String(format: "%4.2f %@", convertedValue, tokens[multiplyFactor])
    }*/
        
        //计算一个文件夹下的文件大小
        class func calculateFolderFilesSize(folderPath:String) -> String{
            //多少K，超过1024K的用M为单位
            var filesSize:UInt64 = 0
            
    //        FileManager.default.enumerator(atPath: T##String)
            
            if let fileArr = FileManager.default.subpaths(atPath: folderPath) {
                DDLogInfo("subpaths count:\(fileArr.count)")
                for filePath in fileArr {
                    let fullFilePath = folderPath + "/" + filePath
                    filesSize += HQFileManager.sizeForLocalFilePath(filePath: fullFilePath)
                }
            }
            return HQFileManager.covertToFileString(with: filesSize)
        }
    
    
        //粗略计算一个文件夹下的文件大小
        class func calculateEstimatedFolderFilesSize(folderPath:String) -> String{
            //多少K，超过1024K的用M为单位
            var filesSize:UInt64 = 0
            
    //        FileManager.default.enumerator(atPath: T##String)
            
            var fileIndex = 0  //平均100个文件的大小，来算总文件大小
            if let fileArr = FileManager.default.subpaths(atPath: folderPath) {
                DDLogInfo("subpaths count:\(fileArr.count)")
                for filePath in fileArr {
                    let fullFilePath = folderPath + "/" + filePath
                    filesSize += HQFileManager.sizeForLocalFilePath(filePath: fullFilePath)
                    fileIndex += 1
                    if fileIndex >= 100 {
                        break;
                    }
                }
                if fileIndex >= 100{
                    let fileCount = fileArr.count
                    filesSize = UInt64(Int(filesSize)/fileIndex * fileCount)
                }
            }
            
            return HQFileManager.covertToFileString(with: filesSize)
        }
    
    
    
    /**  计算单个文件或文件夹的大小 */
    class func fileSizeAtPath(filePath:String) -> Float {
      
      let manager = FileManager.default
      var fileSize:Float = 0.0
      if manager.fileExists(atPath: filePath) {
          do {
              let attributes = try manager.attributesOfItem(atPath: filePath)
              
               if attributes.count != 0 {
                  
                  fileSize = attributes[FileAttributeKey.size]! as! Float
                }
             }catch{
          
             }
        }
      
       return fileSize;
    }
}


//MARK: - 删除文件
extension HQFileManager {
    //清空作业和课程数据
    class func deleteFiles(){
        do {
            let fm = FileManager.default
            let docsurl = try! fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let courseFolder = docsurl.appendingPathComponent("KQTCourseList")
            let wrokFolder = docsurl.appendingPathComponent("Homework")
            let gameFolder = docsurl.appendingPathComponent("Gamefile")
            let outClassBookFolder = docsurl.appendingPathComponent("KQTOutClassBookList")
            if  fm.fileExists(atPath: courseFolder.path) {
                try FileManager.default.removeItem(at: courseFolder)
            }
            if  fm.fileExists(atPath: wrokFolder.path) {
                try FileManager.default.removeItem(at: wrokFolder)
            }
            if  fm.fileExists(atPath: gameFolder.path) {
                try FileManager.default.removeItem(at: gameFolder)
            }
            if  fm.fileExists(atPath: outClassBookFolder.path) {
                try FileManager.default.removeItem(at: outClassBookFolder)
            }
        } catch {
            DDLogInfo("Delete KQTCourseList Homework 文件夹失败")
        }
    }
    
    //删除本地音频文件
    class func deleteAudioFiles(fullPath:String){
        do {
            let fm = FileManager.default
            if  fm.fileExists(atPath: fullPath) {
                try FileManager.default.removeItem(atPath: fullPath)
            }
        } catch {
            DDLogInfo("Delete \(fullPath) 文件夹失败")
        }
    }
    
    
    
    //删除指定句子的音频文件
    class func deleteSentenceAudioFiles(sentences:[Sentence]) {
        for sentence in sentences {
            //需要先判断文件是否存在：
            if let audioUrl = sentence.audioUrl {
                
                let localNormalAudioFullURL = KQTLocalAudioPath.normalAudioPathString(audioUrl)//本地音频路径
                let isExists = FileManager.default.fileExists(atPath: localNormalAudioFullURL)
                
                if isExists {
                    do{
                        try FileManager.default.removeItem(atPath: localNormalAudioFullURL)
                        DDLogInfo("Delete 文件成功: \(localNormalAudioFullURL) ")
                    }catch{
                        DDLogInfo("Delete 文件失败: \(localNormalAudioFullURL) ")
                    }
                    
                }
            }
        }
    }
}


//MARK: -
class HQFileManager {
    
    //把课程一直放在内存中
    static let sharedInstance = HQFileManager()
    
//    var courseListModel:CourseListModel?
    var fm = FileManager.default
    
    //Document文件目录
    static var documentDirectoryPath:String? = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
    
    //缓存文件目录
    static var cacheDirectoryPath:String? = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
    
    
    private init() {  //单例：所以用私有这个方法
//         =  HQFileManager.readCourseData()
//        let json = JSON(localData)
//        self.courseModel = KQTCourseRootClass.init(fromJson: json)
        
        
    }
    

    //自动下载音频文件
    class func autoDownloadFiles(sentences:[Sentence]?){
        if sentences == nil || sentences!.count == 0 {
            return;
        }
        
        //批量下载前需要先移除所有任务，否则任务越来越多
        appDelegate.sessionManager.totalRemove() //刚删除，马上就下载：不知道会不会有问题
        
        let urls = HQFileManager.findUndownloadFileURLs(sentences: sentences!)
        if urls.serverNormalAudioURLs.count == 0 {
            return;
        }
        
        appDelegate.sessionManager.multiDownload(urls.serverNormalAudioURLs,  fileNames: urls.localNormalAudioURLs, onMainQueue: true)
        
    }
    
  
    //找到未下载的文件URLs
    class func findUndownloadFileURLs(sentences:[Sentence]) ->(serverNormalAudioURLs:[String],localNormalAudioURLs:[String]) {
        var serverNormalAudioURLs = [String]()
        var localNormalAudioURLs = [String]()
        
        //创建文件夹 只执行一次判断
        HQFileManager.sharedInstance.createFolder(fullPath: KQTLocalAudioPath.normalAudioPathString("createFolder"))
        
        for sentence in sentences {
            //需要先判断文件是否存在：
            if let audioUrl = sentence.audioUrl {
                let localNormalAudioFullURL = KQTLocalAudioPath.normalAudioPathString(audioUrl)//本地音频路径
                let isExists = FileManager.default.fileExists(atPath: localNormalAudioFullURL)
                if !isExists {
                    let downloadURL = audioUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    serverNormalAudioURLs.append(downloadURL)
                    let localAudioShortPath = KQTLocalAudioPath.normalAudioShortPathString(audioUrl) //短路径
                    localNormalAudioURLs.append(localAudioShortPath)
                }
            }
        }
        return (serverNormalAudioURLs,localNormalAudioURLs)
    }
    
    //计算下载的进度
    class func calculateDownloadProgress(sentences:[Sentence]) -> Float {
        
        let allCount = sentences.count
        guard allCount != 0 else { return Float(1.0); }
        
        var downloadCount:Int = 0
        
        for sentence in sentences {
            //需要先判断文件是否存在：
            if let audioUrl = sentence.audioUrl {
                let localNormalAudioFullURL = KQTLocalAudioPath.normalAudioPathString(audioUrl)//本地音频路径
                let isExists = FileManager.default.fileExists(atPath: localNormalAudioFullURL)
                if isExists {
                    downloadCount += 1
                }
            }
        }
        return Float(downloadCount)/Float(allCount)
    }
    
    //计算下载的粗略进度：刚进到APP的时候需要使用
    class func calculateEstimateDownloadProgress(sentences:[Sentence]) -> Float {
        
        let allCount = sentences.count
        guard allCount != 0 else { return Float(1.0); }
        
        //创建索引数组
        let divisionCount = 10 //分割成多少份
        var indexArr = [Int]()
        if allCount <= divisionCount {
            for index in 0..<allCount {
                indexArr.append(index)
            }
        }else{
            let perCount = allCount/divisionCount
            for index in 0...divisionCount-1-1 { //最后一个单独添加
                indexArr.append(index*perCount)
            }
            indexArr.append(allCount - 1) //添加最后一个
        }
//        DDLogInfo("indexArr:" + indexArr.description + "allCount:\(allCount)")
        
        var downloadCount:Int = 0
        for index in indexArr {
            let sentence = sentences[index]
            //需要先判断文件是否存在：
            if let audioUrl = sentence.audioUrl {
                let localNormalAudioFullURL = KQTLocalAudioPath.normalAudioPathString(audioUrl)//本地音频路径
                let isExists = FileManager.default.fileExists(atPath: localNormalAudioFullURL)
                if isExists {
                    downloadCount += 1
                }
            }
        }
        
        return Float(downloadCount)/Float(indexArr.count)
    }
    
    
    
    
    
    //MARK: - 0公共的Data数据存储和读取
    //存储Data到Document文件夹及子文件夹
    class func saveDataToFileInDocument(data:Data,fileName:String) {
        let fm = FileManager.default
        // 获取documents 文件夹所在的URL
        let docsurl = try! fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let courseFile = docsurl.appendingPathComponent(fileName)
        
        HQFileManager.sharedInstance.createFolder(fullPath: courseFile.path)
        // 哪些数据类型可以使用 write(to:) 方法，下面会介绍
        try! data.write(to: courseFile)
    }
    
    //读取Data到Document文件夹及子文件夹
    class func readDataOfDocument(fileName:String) -> Data{
        let fm = FileManager.default
        // 获取documents 文件夹所在的URL
        do{
            let docsurl = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let courseFile = docsurl.appendingPathComponent(fileName)
            
            // 将 personFile 路径下文件的内容读取为 NSData 格式
            let courseData = NSData(contentsOf: courseFile)
            if courseData == nil {
                return Data()
            }else{
                return courseData! as Data
            }
            
        }catch{
            return Data()
        }
    }
    
    //MARK: - 0滚动图的数据存储:type=0  以后可能新增type
    class func saveCarouseImageList(models:[CarouseImageModel],type:Int) {
//        print("time test1:\(CACurrentMediaTime())")
        let jsonString = models.toJSONString() ?? ""
        let data = jsonString.data(using: .utf8)!
        HQFileManager.saveDataToFileInDocument(data: data, fileName: "CarouseImageList_\(type).json")
        
    }
    

    class func readCarouseImagelList(type:Int,result: @escaping(_ models:[CarouseImageModel])->()){
        
        //解析模型比较耗时间
        DispatchQueue.global().async {
            let localData =  HQFileManager.readDataOfDocument(fileName: "CarouseImageList_\(type).json")
            let json = String(data: localData, encoding: .utf8) ?? ""
            
            var models:[CarouseImageModel]?
            models = Mapper<CarouseImageModel>().mapArray(JSONString: json)
            
            DispatchQueue.main.async {
                return result(models ?? [])
            }
        }

    }
    
    //MARK: - 1课程项列表的数据存储
    //课程项列表，不包含课程详情，需要通知存储数据完成
    class func saveCourseListModel(models:[BookModel],result: @escaping(_ finished:Bool)->()) {
        DispatchQueue.global().async {
            let jsonString = models.toJSONString() ?? ""
            let data = jsonString.data(using: .utf8)!
            HQFileManager.saveDataToFileInDocument(data: data, fileName: "KQTCourseList/\(Defaults.userID).json")
            
            DispatchQueue.main.async {
                return result(true)
            }
        }
    }
    
    
    class func readCourseListModel(result: @escaping(_ models:[BookModel])->()){
        
        //解析模型比较耗时间
        DispatchQueue.global().async {
            let localData =  HQFileManager.readDataOfDocument(fileName: "KQTCourseList/\(Defaults.userID).json")
            let json = String(data: localData, encoding: .utf8) ?? ""
            
            var models:[BookModel]?
            models = Mapper<BookModel>().mapArray(JSONString: json)
            
            DispatchQueue.main.async {
                return result(models ?? [])
            }
        }
        
    }
    
    
    
    
    
    //MARK: - 1.1单个课本的存储
    //1存储课程文件
    class func saveCourseModel(model:BookModel) {
        DispatchQueue.global().async {
            let jsonString = model.toJSONString() ?? ""
            let data = jsonString.data(using: .utf8)!
            let fileName = "KQTCourseList/\(Defaults.userID)/\(model.bookId!).json" //课程ID有时候没有
            HQFileManager.saveDataToFileInDocument(data: data, fileName: fileName)
        }
    }
    
    
    //2.1读取课程模型
    class func readCourseModel(courseId:Int,result: @escaping(_ courseRootModel:BookModel?)->()){
         
         //解析模型比较耗时间
         DispatchQueue.global().async {
            let localData =  HQFileManager.readDataOfDocument(fileName: "KQTCourseList/\(Defaults.userID)/\(courseId).json")
             var courseModel:BookModel?
             if localData.count > 1000 {
                 let json = String(data: localData, encoding: .utf8) ?? ""
                 let model = BookModel(JSONString: json)
                 courseModel = model
             }else{
                 courseModel = nil
             }
             
             DispatchQueue.main.async {
                 result(courseModel)
             }
         }
         
     }

    
    //MARK: - 2课外书籍列表的数据存储
    //课程项列表，不包含课程详情，需要通知存储数据完成
    class func saveOutClassBookListModel(models:[BookInfo],result: @escaping(_ finished:Bool)->()) {
        DispatchQueue.global().async {
            let jsonString = models.toJSONString() ?? ""
            let data = jsonString.data(using: .utf8)!
            HQFileManager.saveDataToFileInDocument(data: data, fileName: "KQTOutClassBookList/\(Defaults.userID).json")
            
            DispatchQueue.main.async {
                return result(true)
            }
        }
    }
    
    
    class func readOutClassBookListModel(result: @escaping(_ models:[BookInfo])->()){
        
        //解析模型比较耗时间
        DispatchQueue.global().async {
            let localData =  HQFileManager.readDataOfDocument(fileName: "KQTOutClassBookList/\(Defaults.userID).json")
            let json = String(data: localData, encoding: .utf8) ?? ""
            
            var models:[BookInfo]?
            models = Mapper<BookInfo>().mapArray(JSONString: json)
            
            DispatchQueue.main.async {
                return result(models ?? [])
            }
        }
        
    }
    
    
    //MARK: - 2.1单个课外课本的存储
    //1存储课程文件
    class func saveOutClassBookModel(model:BookModel) {
        DispatchQueue.global().async {
            let jsonString = model.toJSONString() ?? ""
            let data = jsonString.data(using: .utf8)!
            let fileName = "KQTOutClassBookList/\(Defaults.userID)/\(model.courseId!).json"
            HQFileManager.saveDataToFileInDocument(data: data, fileName: fileName)
        }
    }
    
    
    //2.1读取课程模型
    class func readOutClassBookModel(courseId:Int,result: @escaping(_ courseRootModel:BookModel?)->()){
         
         //解析模型比较耗时间
         DispatchQueue.global().async {
            let localData =  HQFileManager.readDataOfDocument(fileName: "KQTOutClassBookList/\(Defaults.userID)/\(courseId).json")
             var courseModel:BookModel?
             if localData.count > 1000 {
                 let json = String(data: localData, encoding: .utf8) ?? ""
                 let model = BookModel(JSONString: json)
                 courseModel = model
             }else{
                 courseModel = nil
             }
             
             DispatchQueue.main.async {
                 result(courseModel)
             }
         }
         
     }
    
    

    
    //MARK: - 3作业数据存储
    class func saveWorkModelList(models:[KQTHomeworkModel],type:KQTHomeWorkQueryState) {
        let jsonString = models.toJSONString() ?? ""
        let data = jsonString.data(using: .utf8)!
        
        /*
         1. 超时和未完成：在一个文件
         2. 首页3个：在一个文件
         3. 完成：在一个文件
         */
        
        var fileName:String = ""
        switch type {
        case .all:
            fileName = "FirstPageHomework"
        case .did:
            fileName = "FinishHomework"
        default:
            fileName = "DoingHomework"
        }
        HQFileManager.saveDataToFileInDocument(data: data, fileName: "Homework/workList/\(Defaults.userID)_\(fileName).json")
    }
    

    class func readWorkModelList(type:KQTHomeWorkQueryState,result: @escaping(_ workModelList:[KQTHomeworkModel])->()){
        
        //解析模型比较耗时间
        DispatchQueue.global().async {
            
            var fileName:String = ""
            switch type {
            case .all:
                fileName = "FirstPageHomework"
            case .did:
                fileName = "FinishHomework"
            default:
                fileName = "DoingHomework"
            }
            
            let localData =  HQFileManager.readDataOfDocument(fileName: "Homework/workList/\(Defaults.userID)_\(fileName).json")
            let json = String(data: localData, encoding: .utf8) ?? ""
            
            var models:[KQTHomeworkModel]?
            models = Mapper<KQTHomeworkModel>().mapArray(JSONString: json)
            
            DispatchQueue.main.async {
                return result(models ?? [])
            }
        }

    }
    
    
    //MARK: - 3.1作业详情的存储
        class func saveHomeworkModel(model:KQTHomeworkModel,result: @escaping(_ finished:Bool)->()) {
            DispatchQueue.global().async {
                let jsonString = model.toJSONString() ?? ""
                let data = jsonString.data(using: .utf8)!
                
                if let workId = model.homeworkId {
                    let fileName = "Homework/user\(Defaults.userID)/work\(workId).json"
                    HQFileManager.saveDataToFileInDocument(data: data, fileName: fileName)
                }
                DispatchQueue.main.async {
                    return result(true)
                }
            }
        }
        
        class func readHomeworkModel(workId:Int,result: @escaping(_ courseRootModel:KQTHomeworkModel?)->()){
             //解析模型比较耗时间
            DispatchQueue.global().async {
                let localData =  HQFileManager.readDataOfDocument(fileName: "Homework/user\(Defaults.userID)/work\(workId).json")
                
                let json = String(data: localData, encoding: .utf8) ?? ""
                let model = KQTHomeworkModel(JSONString: json)
                DispatchQueue.main.async {
                    result(model)
                }
                
                //             var courseModel:GameUnit?
                //                 courseModel = model
                //            if localData.count > 1000 {
                //             }else{
                //                 courseModel = nil
                //             }
                
            }
             
         }
    
    
    
    //MARK: - 4闯关列表的数据存储
       class func saveGameListModel(models:[GameModel],result: @escaping(_ finished:Bool)->()) {
           DispatchQueue.global().async {
               let jsonString = models.toJSONString() ?? ""
               let data = jsonString.data(using: .utf8)!
               HQFileManager.saveDataToFileInDocument(data: data, fileName: "Gamefile/\(Defaults.userID)/gameList.json")
               
               DispatchQueue.main.async {
                   return result(true)
               }
           }
       }
       
       
       class func readGameListModel(result: @escaping(_ models:[GameModel])->()){
           
           //解析模型比较耗时间
           DispatchQueue.global().async {
               let localData =  HQFileManager.readDataOfDocument(fileName: "Gamefile/\(Defaults.userID)/gameList.json")
               let json = String(data: localData, encoding: .utf8) ?? ""
               
               var models:[GameModel]?
               models = Mapper<GameModel>().mapArray(JSONString: json)
               
               DispatchQueue.main.async {
                   return result(models ?? [])
               }
           }
           
       }
       
    
    
    //MARK: - 5闯关详情的存储
    
    class func saveGameUnitModel(model:GameUnit,courseId:Int) {
        DispatchQueue.global().async {
            let jsonString = model.toJSONString() ?? ""
            let data = jsonString.data(using: .utf8)!
            let fileName = "Gamefile/\(Defaults.userID)/\(courseId)_\(model.unitId!).json"
            HQFileManager.saveDataToFileInDocument(data: data, fileName: fileName)
        }
    }
    
    class func readGameUnit(courseId:Int,unitId:Int,result: @escaping(_ courseRootModel:GameUnit?)->()){
         //解析模型比较耗时间
         DispatchQueue.global().async {
            let localData =  HQFileManager.readDataOfDocument(fileName: "Gamefile/\(Defaults.userID)/\(courseId)_\(unitId).json")
//             var courseModel:GameUnit?
             
                 let json = String(data: localData, encoding: .utf8) ?? ""
                 let model = GameUnit(JSONString: json)
//                 courseModel = model
//            if localData.count > 1000 {
//             }else{
//                 courseModel = nil
//             }
             DispatchQueue.main.async {
                 result(model)
             }
         }
         
     }
    
    
    
    //MARK: - 6推荐经典书籍的列表的数据存储
    //经典推荐和热门精选和用户无关
    //经典推荐: APP启动的时候才去获取，刷新时不获取
    class func saveRecommendBookListModel(models:[RecommendBook],result: @escaping(_ finished:Bool)->()) {
        DispatchQueue.global().async {
            let jsonString = models.toJSONString() ?? ""
            let data = jsonString.data(using: .utf8)!
            HQFileManager.saveDataToFileInDocument(data: data, fileName: "KQTNoUser/RecommendBook.json")
            
            DispatchQueue.main.async {
                return result(true)
            }
        }
    }
    
    
    class func readRecommendBookListModel(result: @escaping(_ models:[RecommendBook])->()){
        
        //解析模型比较耗时间
        DispatchQueue.global().async {
            let localData =  HQFileManager.readDataOfDocument(fileName: "KQTNoUser/RecommendBook.json")
            let json = String(data: localData, encoding: .utf8) ?? ""
            
            var models:[RecommendBook]?
            models = Mapper<RecommendBook>().mapArray(JSONString: json)
            
            DispatchQueue.main.async {
                return result(models ?? [])
            }
        }
        
    }
    
    
    //MARK: - 7热门精选的列表的数据存储
    //经典推荐和热门精选和用户无关
    //热门精选: 有数据就不获取，只进行手动获取
    class func saveTopPickListModel(models:[BookInfo],result: @escaping(_ finished:Bool)->()) {
        DispatchQueue.global().async {
            let jsonString = models.toJSONString() ?? ""
            let data = jsonString.data(using: .utf8)!
            HQFileManager.saveDataToFileInDocument(data: data, fileName: "KQTNoUser/TopPick.json")
            
            DispatchQueue.main.async {
                return result(true)
            }
        }
    }
    
    
    class func readTopPickListModel(result: @escaping(_ models:[BookInfo])->()){
        
        //解析模型比较耗时间
        DispatchQueue.global().async {
            let localData =  HQFileManager.readDataOfDocument(fileName: "KQTNoUser/TopPick.json")
            let json = String(data: localData, encoding: .utf8) ?? ""
            
            var models:[BookInfo]?
            models = Mapper<BookInfo>().mapArray(JSONString: json)
            
            DispatchQueue.main.async {
                return result(models ?? [])
            }
        }
        
    }
    
    
    //MARK: - 课程，作业，收藏本，错词本相关处理
    //3更新课程文件
    
}







//MARK:  - 本地音频路径地址
let LocalAudioPath = HQFileManager.documentDirectoryPath! + "/LocalAudio"
public class HQLocalAudioPath  {
    /*
    case basePath = 1           //基本路径
    case baseFilePath           //基本路径+File(因为下载到File路径)
    case normalAudioPath        //标准音频本地路径(需要入参：标准)
    case userAudioPath          //用户音频本地路径
    */
    
    //本地音频文件存放的根路径
    //basePath pathString
    class  func basePathString() -> String {
        return LocalAudioPath
    }
    
    class func baseFilePathString() -> String {
        return LocalAudioPath + "/File"
    }
    
    class func normalAudioFolderPathString() -> String {
        return LocalAudioPath + "/File" + "/normalVoice"
    }
    
    //标准音文件夹路径
    class func normalAudioPathString(_ normalVoiceServerURL:String) -> String {
        return LocalAudioPath + "/File" + "/normalVoice/" + normalVoiceServerURL.md5() + ".wav"
    }
    
    //标准音频的短路径
    class func normalAudioShortPathString(_ normalVoiceServerURL:String) -> String {
        return "/normalVoice/" + normalVoiceServerURL.md5() + ".wav"
    }
    
    
    //用户音文件夹路径
    class func userAudioFolderPathString() -> String {
        return LocalAudioPath + "/File" + "/userVoice"
    }
    
    //中转音频路径：用户录音的临时wav文件，后续保存为mp3格式
    class func userTmpRecordAudioPathString() -> String {
        return LocalAudioPath + "/File" + "/userVoice/" + "userTmpRecord.wav"
    }
    
    //课程模块：用户录音
    class func userAudioPathStringForCourse(_ normalVoiceServerURL:String) -> String {
        return LocalAudioPath + "/File" + "/userVoice/Course/\(Defaults.currentCourseId)" + "/UserID\(Defaults.userID)/" + normalVoiceServerURL.md5() + ".wav"
    }
    //课程模块：用户录音:短路径，用来保存下载文件
    class func userAudioShortPathStringForCourse(_ normalVoiceServerURL:String) -> String {
        return "/userVoice/Course/\(Defaults.currentCourseId)" + "/UserID\(Defaults.userID)/" + normalVoiceServerURL.md5() + ".wav"
    }
    
    //错题本模块：用户录音
    class func userAudioPathStringForErrors(_ normalVoiceServerURL:String) -> String {
        return LocalAudioPath + "/File" + "/userVoice/Errors" + "/UserID\(Defaults.userID)/" + normalVoiceServerURL.md5() + ".wav"
    }
    
    //作业模块：用户录音
    class func userAudioPathStringForHomework(_ normalVoiceServerURL:String) -> String {
        return LocalAudioPath + "/File" + "/userVoice/Homework/\(Defaults.currentHomeworkId)" + "/UserID\(Defaults.userID)/" + normalVoiceServerURL.md5() + ".wav"
    }
    
    //闯关游戏模块：用户录音
    class func userAudioPathStringForGame(_ normalVoiceServerURL:String) -> String {
        return LocalAudioPath + "/File" + "/userVoice/Game/\(Defaults.currentGameCourseId)" + "/UserID\(Defaults.userID)/" + normalVoiceServerURL.md5() + ".wav"
    }
    
}
