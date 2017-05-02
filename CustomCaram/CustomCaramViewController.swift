
//
//  CustomCaramViewController.swift
//  CustomCaram
//
//  Created by 黄家树 on 2017/4/26.
//  Copyright © 2017年 huangjiashu. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class CustomCaramViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    ///拍照按钮
    let takePicBtn      = UIButton(type: .custom)
    ///图库按钮
    let iamgeAlbumBtn   = UIButton(type: .custom)
    ///关闭按钮
    let closeBtn        = UIButton(type: .custom)
    ///闪光灯
    let flashBtn        = UIButton(type: .custom)
    ///切换相机
    let cramaBtn        = UIButton(type: .custom)
    ///手电筒
    let torchBtn        = UIButton(type: .custom)
    ///底部工具栏
    let bottomView      = UIView()
    ///聚焦视图
    let focusView       = UIView()
    ///滑块
    let slider          = UISlider()
    ///接受触摸事件
    let reciveGesture   = UIView()
    ///摄像头焦倍
    var deviceScale     = CGFloat()
    
    ///会话
    var captureSession:    AVCaptureSession?
    ///设备
    var captureDevice:     AVCaptureDevice?
    ///连接
    var captureConnection: AVCaptureConnection?
    ///预览层
    var preViewLayer:      AVCaptureVideoPreviewLayer?
    ///输入
    var deviceInput:       AVCaptureDeviceInput?
    ///输出
    var imageOutPut:       AVCaptureStillImageOutput?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.cyan
        self.setUpUI()
        self.configSession()
        self.addGesture()
        
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
        case .notDetermined:()//未确定
            self.requestAccess()

            
        case .authorized:()//已授权
            //启动回话
            if (!self.captureSession!.isRunning) {
                self.captureSession?.startRunning()
            }
            
        case .restricted://拒绝
            self.denyByUser()
            
        case .denied://拒绝
            self.denyByUser()

        }

        
    }


    /// 请求授权
    func requestAccess() {
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { (granted:Bool) in
            if granted {
                if (self.captureSession?.isRunning == false) {
                    self.captureSession?.startRunning()
                }
            } else {
                self.denyByUser()
            }
            
        }
    }
    
    
    /// 被用户拒绝
    func denyByUser() {
        let alertCtr = UIAlertController(title: nil, message: "请到设置里授予相机权限", preferredStyle: .alert)
        alertCtr.addAction(UIAlertAction(title: "确认", style: .default, handler: { (action) in
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alertCtr, animated: true, completion: nil)
    }
    
    
    /// 启动UI
    func setUpUI() {
        
        let topAndBottomHeight: CGFloat = 64
        //顶部栏
        let topView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: topAndBottomHeight))
        self.view.addSubview(topView)
        //底部栏

        self.bottomView.frame = CGRect(x: 0, y: self.view.frame.height - topAndBottomHeight - 20, width: self.view.frame.width, height: topAndBottomHeight + 20)
        
        self.view.addSubview(self.bottomView)
        //mask层
        let maskView = UIView(frame: bottomView.bounds)
        maskView.backgroundColor = UIColor.lightGray
        maskView.alpha = 0.3
        self.bottomView.addSubview(maskView)
        
        
        let iconWidth:CGFloat = 40
        let iconHeight:CGFloat = iconWidth
        let topSpace:CGFloat = 20
        let rightSpace:CGFloat = 5
        
        //在顶部栏 添加闪光灯 相机切换 关闭按钮
        
        self.closeBtn.frame = CGRect(x: topView.frame.width - iconWidth - rightSpace, y: topSpace, width: iconWidth, height: iconHeight)
        self.closeBtn.setImage(UIImage.init(named: "顶部工具条-关闭"), for: .normal)
        self.closeBtn.addTarget(self, action: #selector(close), for: .touchUpInside)
        topView.addSubview(self.closeBtn)
        
        self.cramaBtn.frame = CGRect(x: (topView.frame.width - iconWidth)/2, y: topSpace, width: iconWidth, height: iconHeight)
        self.cramaBtn.setImage(UIImage.init(named: "顶部工具条-切换换摄像头"), for: .normal)
        self.cramaBtn.addTarget(self, action: #selector(switchCarma), for: .touchUpInside)
        topView.addSubview(self.cramaBtn)
        
        self.flashBtn.frame = CGRect(x: rightSpace, y: topSpace, width: iconWidth, height: iconHeight)
        self.flashBtn.setImage(UIImage.init(named: "顶部工具条-闪光灯自动"), for: .normal)
        self.flashBtn.addTarget(self, action: #selector(switchFlashMode), for: .touchUpInside)
        topView.addSubview(self.flashBtn)
        
        
        //在底部增加拍照
        //滑块
        let sliderW: CGFloat = self.view.frame.width * 2/3
        self.slider.frame = CGRect(x: (self.view.frame.width - sliderW)/2, y: 10, width: sliderW, height: 20)
        self.slider.minimumValue = 1
        self.slider.maximumValue = 5
        self.slider.value = 1
        self.slider.isContinuous = true
        self.slider.addTarget(self, action: #selector(sliderChange), for: .valueChanged)
        self.bottomView.addSubview(self.slider)
        
        self.takePicBtn.frame = CGRect(x: (self.bottomView.frame.width - iconWidth)/2, y: 2 * topSpace, width: iconWidth, height: iconHeight)
        self.takePicBtn.setBackgroundImage(UIImage.init(named: "底部工具条-打开相机"), for: .normal)
        self.takePicBtn.addTarget(self, action: #selector(takePick), for: .touchUpInside)
        bottomView.addSubview(self.takePicBtn)
        
        self.iamgeAlbumBtn.frame = CGRect(x: bottomView.frame.width - iconWidth - rightSpace, y: 2 * topSpace, width: iconWidth, height: iconHeight)
        self.iamgeAlbumBtn.setImage(UIImage.init(named: "底部工具条-打开相册"), for: .normal)
        self.iamgeAlbumBtn.addTarget(self, action: #selector(openAlbum), for: .touchUpInside)
        bottomView.addSubview(self.iamgeAlbumBtn)
        
        //初始化聚焦视图
        let focusImage = UIImage(named: "手动对焦")
        self.focusView.frame = CGRect(x: 0, y: 0, width: focusImage!.size.width, height: focusImage!.size.height)
        self.focusView.isHidden = true
        self.focusView.layer.contents = focusImage!.cgImage as Any
        self.view.addSubview(self.focusView)
        
        //中间区域 接受手势
        self.reciveGesture.frame = CGRect(x: 0, y: topView.frame.maxY, width: self.view.frame.width, height: bottomView.frame.minY - topView.frame.maxY)
        self.reciveGesture.backgroundColor = UIColor.clear
        self.view.addSubview(self.reciveGesture)
    }
    
    
    /// 配置会话
    func configSession() {
        
        //相机首次设置为默认值 后置相机
        self.captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        self.flashBtn.isHidden = !self.captureDevice!.isFlashAvailable
        
        do {
            try self.captureDevice!.lockForConfiguration()//在swift中返回值为空
            
            if  self.captureDevice!.isFlashModeSupported(.auto) {
                self.captureDevice!.flashMode = .auto
            }
            
            if self.captureDevice!.isFocusModeSupported(.autoFocus) {
                self.captureDevice!.focusMode = .autoFocus
            }
            
            if self.captureDevice!.isWhiteBalanceModeSupported(.autoWhiteBalance) {
                self.captureDevice!.whiteBalanceMode = .autoWhiteBalance
            }
            self.captureDevice!.unlockForConfiguration()
            
        } catch  {
            print("设备锁定出错:\(error.localizedDescription)")
        }
        
        //设置输入
        self.deviceInput = try? AVCaptureDeviceInput(device: self.captureDevice!)
        //设置输出
        self.imageOutPut = AVCaptureStillImageOutput()
        self.imageOutPut?.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
        
        //设置session
        self.captureSession = AVCaptureSession()
        if self.captureSession!.canSetSessionPreset(AVCaptureSessionPresetPhoto) {
            self.captureSession?.sessionPreset = AVCaptureSessionPresetPhoto
        }
        
        if self.captureSession!.canAddInput(self.deviceInput) {
            self.captureSession!.addInput(self.deviceInput)
        }
        
        if self.captureSession!.canAddOutput(self.imageOutPut) {
            self.captureSession?.addOutput(self.imageOutPut)
        }
        
        self.captureConnection = self.imageOutPut?.connection(withMediaType: AVMediaTypeVideo)
        self.captureConnection?.videoOrientation = .portrait
        self.captureConnection?.videoScaleAndCropFactor = 1.0
        
        if self.captureSession!.canAdd(self.captureConnection) {
            self.captureSession?.add(self.captureConnection)
        }
        //设置layer
        self.preViewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession!)
        self.preViewLayer?.frame = UIScreen.main.bounds
        self.preViewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.view.layer.insertSublayer(self.preViewLayer!, at: 0)
        
        self.captureSession?.startRunning()
    }
    
  // MARK: - 事件处理
    
    /// 关闭
    func close() {
        self.dismiss(animated: true, completion: nil)
    }
    
    /// 切换相机
    func switchCarma(){
        
        guard self.captureDevice != nil else {
            return
        }
        
        let currentPostion = self.captureDevice!.position
        var resultPostion = AVCaptureDevicePosition.unspecified
        
        switch currentPostion {
        case .unspecified:
        ()
        case .back:
            resultPostion = .front
        case .front:
            resultPostion = .back
        }
        
        //过度动画
        let transition = CATransition()
        transition.type = "oglFlip"
        transition.duration = 0.5
        transition.subtype = resultPostion == .front ? kCATransitionFromLeft : kCATransitionFromRight
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        self.preViewLayer?.add(transition, forKey: nil)
        
        //开始配置
        self.captureSession?.beginConfiguration()
        
        self.captureSession?.removeInput(self.deviceInput!)
        
        let devices:[AVCaptureDevice] = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as! [AVCaptureDevice]
        
        for device in devices {
            if device.position == resultPostion {
                self.captureDevice = device
                break
            }
        }
        
       try? self.deviceInput = AVCaptureDeviceInput(device: self.captureDevice)
        
        if self.captureSession!.canAddInput(self.deviceInput) {
            self.captureSession?.addInput(self.deviceInput)
        }
        
        self.captureSession?.commitConfiguration()
        
    }
    
    /// 切换闪光模式
    func switchFlashMode(){
        let flashMode = self.captureDevice!.flashMode
        var resultFlashModel = AVCaptureFlashMode.auto
        var infoTips = ""
        
        switch flashMode {
        case .off:
            resultFlashModel = .on
            infoTips = "顶部工具条-闪光灯开"
        case .on:
            resultFlashModel = .auto
            infoTips = "顶部工具条-闪光灯自动"
        case .auto:
            resultFlashModel = .off
            infoTips = "顶部工具条-闪光灯关"
        }
        
        if self.captureDevice!.isFlashModeSupported(resultFlashModel) {
            do {
                try self.captureDevice!.lockForConfiguration()
                self.captureDevice?.flashMode = resultFlashModel
                self.captureDevice!.unlockForConfiguration()
                self.flashBtn.setImage(UIImage.init(named: infoTips), for: .normal)
            } catch  {
                print("错定失败")
            }
        }
        
    }
    
    /// 滑块改变
    func sliderChange(){
        self.setZoomScaleWithFactor(zoomScaleFactor: CGFloat(self.slider.value))
        self.deviceScale = CGFloat(self.slider.value)
    }
    
    /// 拍照
    func takePick(){
        guard self.captureSession!.isRunning else {
            return
        }
        
        self.takePicBtn.isEnabled = false
        UIView.animate(withDuration: 0.25) { 
            self.bottomView.isHidden = true
            self.takePicBtn.isHidden = true
            self.cramaBtn.isHidden   = true
            self.flashBtn.isHidden   = true
        }
        
        self.imageOutPut?.captureStillImageAsynchronously(from: self.captureConnection, completionHandler: { (imageDataSampleBuffer, error) in
            
            guard imageDataSampleBuffer != nil else {
                //未获取数据
                UIView.animate(withDuration: 0.25, animations: { 
                    self.bottomView.isHidden = false
                    self.takePicBtn.isHidden = false
                    self.cramaBtn.isHidden   = false
                    self.flashBtn.isHidden   = false
                })
                return
            }
            self.captureSession?.stopRunning()
            
            let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
            let image = UIImage(data: imageData!)
            
            //保存图片
//            DispatchQueue.global().async {
//                UIImageWriteToSavedPhotosAlbum(image!, self, #selector(self.image(image:didFinishSavingWithError:contextInfo:)), nil)
//            }

            if self.saveImageToAlbum(image: image!) == true {
                print("图片保存成功")
            } else {
                print("图片保存失败")
            }
            
            //把图片发给服务器处理
            
        })
    }
    
    //注意如果需要弹窗提醒,请切换到主线程,这里只是做了打印
    func saveImageToAlbum(image:UIImage) -> Bool {

        var success = false
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            success = self.tosaveImageToAlbum(image:image)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (stauts) in
                if stauts == .authorized {
                    success = self.tosaveImageToAlbum(image: image)
                }
            })
        case .denied:
            print("请到设置中授予相机权限")
            
        case .restricted:
            print("系统受限,无法使用相机")
        }
        
        return success
    }
    
    
    func tosaveImageToAlbum(image:UIImage) -> Bool {
        
        //1.先保存到系统相册 才能保存到自己的相册 在相机删除时 会同步从其他相簿删除
        //从自己的相簿删除时 也会有两个选项 一个是从相簿中移除,一个是删除相片,删除的话也会从系统相机移除
        var isSuccess = false //保存到系统相册成败
        var assertId: String?
        
        do {
            try PHPhotoLibrary.shared().performChangesAndWait({
                let phasetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                assertId = phasetRequest.placeholderForCreatedAsset?.localIdentifier
            })
        } catch let error {
            //保存失败
            print("图片保存失败",error.localizedDescription)
        }
        //没有捕获到错误
        isSuccess = true
        //2.拿到保存的图片 再保存到自己的相册 之所谓没在上述块中完成,是因为试验结果是 只保存到了相机但没有保存到自己定义的相册
        let phassets =  PHAsset.fetchAssets(withLocalIdentifiers: [assertId!], options: nil)
        
        //3.拿到创建的相册
        
        if  let asetCollection = createAssetCollectionIfNeed() {
            
            //修改相册 给相册增加图片
            do {
                try PHPhotoLibrary.shared().performChangesAndWait {
                    
                    let collectionChangeRequeset =  PHAssetCollectionChangeRequest(for: asetCollection)
                    collectionChangeRequeset?.insertAssets(phassets, at: IndexSet(integer: 0))
                }
            } catch  {
                //同步保存到自定义相册出错
            }
            
        }
        
        return isSuccess
        
        
    }
    
    
    
    func createAssetCollectionIfNeed() -> PHAssetCollection? {
        
        var assetCollection: PHAssetCollection?
        
        //获取名字 这个是名字 下个是唯一标示 不要搞混了
        let name: String =  Bundle.main.infoDictionary![String(kCFBundleNameKey)] as! String
        
        let collections =  PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
        
        collections.enumerateObjects({ (collection, _, _) in
            if collection.localizedTitle == name {
                assetCollection = collection
            }
        })
        
        if assetCollection != nil {
            return assetCollection
        }
        
        //如果没有 创建一个
        var collectionID:String?
        try? PHPhotoLibrary.shared().performChangesAndWait {
         let collectionrequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
        collectionID = collectionrequest.placeholderForCreatedAssetCollection.localIdentifier
        }
        
        assetCollection =  PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [collectionID!], options: nil).firstObject
        
        return assetCollection
    }
    
 
    
    func image(image:UIImage, didFinishSavingWithError:NSError?, contextInfo: AnyObject) {
       
        if didFinishSavingWithError != nil {
            print("图片保存失败")
        }
        
        
    }
    
  
    
    /// 打开相册
    func openAlbum(){
        
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            print("相册不可用")
            return
        }
        
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        picker.delegate = self
        
        self.present(picker, animated: true) { 
            self.captureSession?.stopRunning()
        }
    }
    
    /// 添加手势
    func addGesture() {
        //聚焦
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(manuFaous(sender:)))
        self.reciveGesture.addGestureRecognizer(tapGesture)
        
        //放大
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(zoomView(sender:)))
        self.reciveGesture.addGestureRecognizer(pinchGesture)
        
        
    }
    
    /// 聚焦手势
    ///
    /// - Parameter sender: 手势
    func manuFaous(sender:UITapGestureRecognizer) {
        guard self.captureSession!.isRunning else {
            return
        }
        //将触摸点转换到预览层
        let devicePoint = self.preViewLayer?.captureDevicePointOfInterest(for: sender.location(in: sender.view))
        //锁定设备
        do {
            try self.captureDevice?.lockForConfiguration()
            
            if self.captureDevice!.isFocusPointOfInterestSupported && self.captureDevice!.isFlashModeSupported(.auto) {
                self.captureDevice?.focusPointOfInterest = devicePoint!
                self.captureDevice?.focusMode = .autoFocus
            }
            
            if self.captureDevice!.isExposurePointOfInterestSupported && self.captureDevice!.isFlashModeSupported(.auto) {
                self.captureDevice?.exposurePointOfInterest = devicePoint!
                self.captureDevice?.exposureMode = .autoExpose
            }
            
            self.captureDevice?.unlockForConfiguration()
        } catch  {
            print("设备锁定失败:\(error.localizedDescription)")
        }
        
        //聚焦动画
        self.focusView.center = sender.location(in: sender.view)
        self.focusView.isHidden = false
        
        UIView.animate(withDuration: 0.25, animations: { 
            self.focusView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        }) { (finished:Bool) in
            UIView.animate(withDuration: 0.5, animations: { 
                self.focusView.transform = CGAffineTransform.identity
            }, completion: { (finished) in
                self.focusView.isHidden = true
            })
        }
    }
    
    /// 缩放
    ///
    /// - Parameter sender: 手势
    func zoomView(sender:UIPinchGestureRecognizer) {
        
        var scale: CGFloat = self.deviceScale + (sender.scale - 1)
        
        if scale > 5 {
            scale = 5
        } else if scale < 1 {
            scale = 1
        }
        
        self.slider.setValue(Float(scale), animated: true)
        self.setZoomScaleWithFactor(zoomScaleFactor: scale)
        
        if sender.state == .ended {
            self.deviceScale = scale
        }
    }
    
    /**
    设置缩放比例
     
    - Parameter zoomScaleFactor: 缩放比例
    */
    func setZoomScaleWithFactor(zoomScaleFactor: CGFloat) {
        
        do {
            try self.captureDevice?.lockForConfiguration()
            self.captureDevice?.videoZoomFactor = zoomScaleFactor
            self.captureDevice?.unlockForConfiguration()
        } catch  {
            
        }
    }
    
    // MARK: - 图片选择控制器代理
    
    /// 取消选择
    ///
    /// - Parameter picker: 控制器
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) { 
            if self.captureSession!.isRunning == false {
                self.captureSession?.startRunning()
            }
        }
    }
    
    /// 获取到内容
    ///
    /// - Parameters:
    ///   - picker: 控制器
    ///   - info: 信息
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        //获取图片
        var image:UIImage? = info[UIImagePickerControllerEditedImage] as? UIImage
        
        if var image = image {
            let rectValue:NSValue = info[UIImagePickerControllerCropRect] as! NSValue
            let compareRect = rectValue.cgRectValue
            if __CGSizeEqualToSize(image.size, compareRect.size) { //视为无编辑 当然这不是很靠谱
                image = info[UIImagePickerControllerOriginalImage] as! UIImage
            }
        } else {
            image = info[UIImagePickerControllerOriginalImage] as? UIImage
            if image?.imageOrientation != UIImageOrientation.up {
                image = self.fixOrientationWithImage(image: image!)
            }
            
            
        }
    }
    
    /// 纠正图片方向
    ///
    /// - Parameter image: 图片
    /// - Returns: 纠正后的图片
    func fixOrientationWithImage(image:UIImage) -> UIImage {
        
        let reulstImage = image;
        
        
        
        if (reulstImage.imageOrientation == UIImageOrientation.up) {return reulstImage;}
        
        // We need to calculate the proper transformation to make the image upright.
        // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
        var transform = CGAffineTransform.identity;
        
        switch (reulstImage.imageOrientation)
        {
        case .down, .downMirrored:
            
            transform = transform.translatedBy(x: reulstImage.size.width, y: reulstImage.size.height)
            transform = transform.rotated(by: CGFloat.pi);
            
            case .left, .leftMirrored:
                transform = transform.translatedBy(x: reulstImage.size.width, y: 0)
                transform = transform.rotated(by: CGFloat.pi/2);
            
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: reulstImage.size.height)
            transform = transform.rotated(by: -CGFloat.pi/2);
        case .up, .upMirrored:()
            
        }
        
        switch (reulstImage.imageOrientation)
        {
        case .upMirrored,.downMirrored:
            transform = transform.translatedBy(x:reulstImage.size.width, y:0)
            transform = transform.scaledBy(x: -1, y: 1)
          
        case .leftMirrored,.rightMirrored:
            transform = transform.translatedBy(x:reulstImage.size.height, y:0)
            transform = transform.scaledBy(x: -1, y: 1)
            
        case .up,.down,.left,.right:()
            
        }
        
        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        let ctx = CGContext(data: nil, width: Int(reulstImage.size.width), height: Int(reulstImage.size.height),
                            bitsPerComponent: reulstImage.cgImage!.bitsPerComponent, bytesPerRow: 0,
                            space: reulstImage.cgImage!.colorSpace!,
                            bitmapInfo: reulstImage.cgImage!.bitmapInfo.rawValue);
        
        
        
        
        ctx!.concatenate(transform);
        
        switch (reulstImage.imageOrientation)
        {
        case .left,.leftMirrored,.right,.rightMirrored:
            ctx!.draw(reulstImage.cgImage!, in: CGRect(x:0,y:0,width:reulstImage.size.height,height:reulstImage.size.width))
        default:
             ctx!.draw(reulstImage.cgImage!, in: CGRect(x:0,y:0,width:reulstImage.size.width,height:reulstImage.size.height))
        }
        let cgimg = ctx!.makeImage();
        let img = UIImage(cgImage: cgimg!)
        return img;
        
    }
    
    
}
