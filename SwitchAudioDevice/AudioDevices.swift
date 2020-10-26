//
//  AudioDevices.swift
//  SwitchAudioDevice
//
//  Created by Blair Wilcox on 10/20/20.
//

/**
 * Creates a high-level API for interacting with CoreAudio audio devices. There are pros and cons
 * to this approach:
 *
 * Pros:
 * - functions can be smaller and more "functional"
 *
 * Cons:
 * - more duplicate code. Not able to reuse variables as much
 */


/**
 * It's kind of difficult to picture all of these things in my head, so I'm thinking about
 * making classes/structs for the main CoreAudio Audio Objects.
 *
 * - [ ] AudioObject // may not need this
 * - [ ] AudioSystemObject
 *  - [ ] kAudioHardwarePropertyDevices
 *  - [ ] kAudioHardwarePropertyDefaultInputDevice
 *  - [ ] kAudioHardwarePropertyDefaultOutputDevice
 *  - [ ] kAudioHardwarePropertyDefaultSystemOutputDevice
 *  - [ ] kAudioHardwarePropertyPlugInList
 * - [ ] AudioDevice
 *  - **Scopes**
 *  - [ ] kAudioObjectPropertyScopeGlobal
 *  - [ ] kAudioObjectPropertyScopeInput
 *  - [ ] kAudioObjectPropertyScopeOutput
 *  - [ ] kAudioObjectPropertyScopePlayThrough
 * - **Properties**
 *  - [ ]
 * - [ ] AudioStream
 */


/**
 * https://github.com/phracker/MacOSX-SDKs/blob/master/MacOSX10.15.sdk/System/Library/Frameworks/CoreAudio.framework/Versions/A/Headers/AudioHardware.h
 *
 */


import Foundation
import CoreAudio

struct Device {
    var id: AudioDeviceID
    var name: String
    var input: Bool
    var output: Bool
}

class AudioDeviceManager {
//    var devices: [AudioDeviceID] = []
    
    private var deviceList: [Device] = []
    
    var devices: [Device] {
        return self.deviceList
    }
    
    init() {
        // create a list of audio devices
        guard let devices = self.getDevices() else {
            return
        }
        for deviceID in devices {
            guard let name = self.getDeviceName(id: deviceID) else {
                continue
            }
            guard let isInputDevice = self.isInputDevice(id: deviceID) else {
                continue
            }
            guard let isOutputDevice = self.isOutputDevice(id: deviceID) else {
                continue
            }
            deviceList.append(Device(id: deviceID, name: name, input: isInputDevice, output: isOutputDevice))
        }
    }
    
    // get the IDs of all the Audio Devices
    private func getDevices() -> [AudioObjectID]? {
        // determine if the AudioSystemObject has a "devices" property
        var devicesAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)
        guard AudioObjectHasProperty(AudioObjectID(kAudioObjectSystemObject), &devicesAddress) else {
            return nil
        }
        
        // get the size and number of devices
        var devicesAddressSize: UInt32 = 0
        AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &devicesAddress, 0, nil, &devicesAddressSize)
        let numDevices = Int(devicesAddressSize) / MemoryLayout<AudioDeviceID>.size
        
        // create an array of all the device IDs
        var devices = [AudioDeviceID](repeating: 0, count: numDevices)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &devicesAddress, 0, nil, &devicesAddressSize, &devices)
        return devices
    }
    
    // get the name of a device
    private func getDeviceName(id: AudioDeviceID) -> String? {
        // determine if the device has a name property
        var deviceNameAddress = AudioObjectPropertyAddress(mSelector: kAudioObjectPropertyName, mScope: kAudioDevicePropertyScopeOutput, mElement: kAudioObjectPropertyElementName)
        guard AudioObjectHasProperty(id, &deviceNameAddress) else {
            return nil
        }
        
        // get the size of the device name string
        var deviceNameAddressSize: UInt32 = 0
        AudioObjectGetPropertyDataSize(id, &deviceNameAddress, 0, nil, &deviceNameAddressSize)
        
        // get the name property
        var deviceName: CFString = "" as CFString
        AudioObjectGetPropertyData(id, &deviceNameAddress, 0, nil, &deviceNameAddressSize, &deviceName)
        
        return String(deviceName)
    }
    
    // functions for getting the "type" of the device (input, output, aggregate, multi-output)
    
    private func isInputDevice(id: AudioDeviceID) -> Bool? {
        // determine if the device has a stream configuration property
        // for an input device. We do this by checking for a stream configuration
        // property in its "input" scope
        var inputStreamConfigAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyStreamConfiguration, mScope: kAudioDevicePropertyScopeInput, mElement: kAudioObjectPropertyElementName)
        guard AudioObjectHasProperty(id, &inputStreamConfigAddress) else {
            return nil
        }
        
        // get the size of the device stream configuration
        var inputStreamConfigAddressSize: UInt32 = 0
        AudioObjectGetPropertyDataSize(id, &inputStreamConfigAddress, 0, nil, &inputStreamConfigAddressSize)
        
        // get the stream configuration
        var inputStreamConfig = AudioBufferList()
        guard AudioObjectGetPropertyData(id, &inputStreamConfigAddress, 0, nil, &inputStreamConfigAddressSize, &inputStreamConfig) == noErr else {
            return nil
        }
        
        // if the number of buffers in the input scope is greater than 0, that
        // means it can act as an "input" device
        return inputStreamConfig.mNumberBuffers > 0
    }
    
    private func isOutputDevice(id: AudioDeviceID) -> Bool? {
        // determine if the device has a stream configuration property
        // for an output device. We do this by checking for a stream configuration
        // property in its "output" scope
        var outputStreamConfigAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyStreamConfiguration, mScope: kAudioDevicePropertyScopeOutput, mElement: kAudioObjectPropertyElementName)
        guard AudioObjectHasProperty(id, &outputStreamConfigAddress) else {
            return nil
        }
        
        // get the size of the device stream configuration
        var outputStreamConfigAddressSize: UInt32 = 0
        AudioObjectGetPropertyDataSize(id, &outputStreamConfigAddress, 0, nil, &outputStreamConfigAddressSize)
        
        // get the stream configuration
        var outputStreamConfig = AudioBufferList()
        guard AudioObjectGetPropertyData(id, &outputStreamConfigAddress, 0, nil, &outputStreamConfigAddressSize, &outputStreamConfig) == noErr else {
            return nil
        }
        
        // if the number of buffers in the output scope is greater than 0, that
        // means it can act as an "output" device
        return outputStreamConfig.mNumberBuffers > 0
    }
    
    // get the "default" input device
    // get the "default" output device
    // get the "default" system output device
}
