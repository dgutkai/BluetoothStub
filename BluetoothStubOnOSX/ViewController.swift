//
//  ViewController.swift
//  BluetoothStubOnOSX
//
//  Created by ZTELiuyw on 15/9/30.
//  Copyright © 2015年 liuyanwei. All rights reserved.
//

import Cocoa
import CoreBluetooth



class ViewController: NSViewController,CBPeripheralManagerDelegate{

//MARK:- static parameter

    let localNameKey =  "Jcar-c";
    let ServiceUUID =  "CAA1";
    let notiyCharacteristicUUID =  "CAB2";
    let readCharacteristicUUID =  "FFF1";
    let readwriteCharacteristicUUID =  "2A06";
    
    var peripheralManager:CBPeripheralManager!
    var timer:Timer!
    var mNotiyCharacteristic: CBMutableCharacteristic!
    override func viewDidLoad() {
        super.viewDidLoad()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
         publishService();
    }
    
    //publish service and characteristic
    func publishService(){
        
        let notiyCharacteristic = CBMutableCharacteristic(type: CBUUID(string: notiyCharacteristicUUID), properties:  [CBCharacteristicProperties.notify], value: nil, permissions: CBAttributePermissions.readable)
        let readCharacteristic = CBMutableCharacteristic(type: CBUUID(string: readCharacteristicUUID), properties:  [CBCharacteristicProperties.read], value: nil, permissions: CBAttributePermissions.readable)
        let writeCharacteristic = CBMutableCharacteristic(type: CBUUID(string: readwriteCharacteristicUUID), properties:  [CBCharacteristicProperties.write], value: nil, permissions: [CBAttributePermissions.readable,CBAttributePermissions.writeable])
        
        //设置description
        let descriptionStringType = CBUUID(string: CBUUIDCharacteristicUserDescriptionString)
        let description1 = CBMutableDescriptor(type: descriptionStringType, value: "canNotifyCharacteristic")
        let description2 = CBMutableDescriptor(type: descriptionStringType, value: "canReadCharacteristic")
        let description3 = CBMutableDescriptor(type: descriptionStringType, value: "canWriteAndWirteCharacteristic")
        notiyCharacteristic.descriptors = [description1];
        readCharacteristic.descriptors = [description2];
        writeCharacteristic.descriptors = [description3];
        
        //设置service
        let service:CBMutableService =  CBMutableService(type: CBUUID(string: ServiceUUID), primary: true)
        service.characteristics = [notiyCharacteristic,readCharacteristic,writeCharacteristic]
        peripheralManager.add(service);
        
    }
    @IBAction func btnclick(_ sender: Any) {
//        timer = Timer.scheduledTimer(timeInterval: 0.03, target: self, selector:"sendData:" , userInfo: mNotiyCharacteristic, repeats: true)
        let data = Data(bytes: [0xfe, 0xcf, 0, 1, 0, 13, 0x40, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01])
        //执行回应Central通知数据
        peripheralManager.updateValue(data, for: mNotiyCharacteristic, onSubscribedCentrals: nil)
    }
    //发送数据，发送当前时间的秒数
    func sendData(_ t:Timer)->Bool{
        let characteristic = t.userInfo as!  CBMutableCharacteristic;
        let dft = DateFormatter();
        dft.dateFormat = "ss";
        NSLog("%@",dft.string(from: Date()))
        let data = Data(bytes: [0xfe, 0xcf, 0, 1, 0, 13, 0x40, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01, 1, 0, 13, 0x40, 0x01, 0x00, 0x00, 0xfe, 0xcf, 0, 1, 0, 13, 0x40, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01, 1, 0, 13, 0x40, 0x01, 0x00, 0x00])
        //执行回应Central通知数据
        return peripheralManager.updateValue(data, for: characteristic, onSubscribedCentrals: nil)
    }

    //MARK:- CBPeripheralManagerDelegate
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if #available(OSX 10.13, *) {
            switch peripheral.state{
            case CBManagerState.poweredOn:
                NSLog("power on")
                publishService();
            case CBManagerState.poweredOff:
                NSLog("power off")
            default:break;
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        peripheralManager.startAdvertising(
            [
                CBAdvertisementDataServiceUUIDsKey : [CBUUID(string: ServiceUUID)]
                ,CBAdvertisementDataLocalNameKey : localNameKey
            ]
        )
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        NSLog("in peripheralManagerDidStartAdvertisiong");
    }
    
    //订阅characteristics
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        NSLog("订阅了 %@的数据",characteristic.uuid)
        mNotiyCharacteristic = characteristic as! CBMutableCharacteristic
        //每秒执行一次给主设备发送一个当前时间的秒数
//        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector:"sendData:" , userInfo: characteristic, repeats: true)
    }
    
    
    //取消订阅characteristics
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        NSLog("取消订阅 %@的数据",characteristic.uuid)
        //取消回应
//        timer.invalidate()
    }
   
    
    //读characteristics请求
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        NSLog("didReceiveReadRequest")
        //判断是否有读数据的权限
        if(request.characteristic.properties.contains(CBCharacteristicProperties.read))
        {
            request.value = request.characteristic.value;
            peripheral .respond(to: request, withResult: CBATTError.Code.success);
        }
        else{
            peripheral .respond(to: request, withResult: CBATTError.Code.readNotPermitted);
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        
        let request:CBATTRequest = requests[0];
        print((request.value! as NSData))
        //判断是否有写数据的权限
        if (request.characteristic.properties.contains(CBCharacteristicProperties.write)) {
            //需要转换成CBMutableCharacteristic对象才能进行写值
            let c:CBMutableCharacteristic = request.characteristic as! CBMutableCharacteristic
            c.value = request.value;
            peripheral .respond(to: request, withResult: CBATTError.Code.success);
        }else{
             peripheral .respond(to: request, withResult: CBATTError.Code.readNotPermitted);
        }
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
            NSLog("peripheralManagerIsReadyToUpdateSubscribers")
    }
}

