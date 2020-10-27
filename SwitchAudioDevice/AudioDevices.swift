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

    private var deviceList: [Device] = []
    private var currentInputDeviceID: AudioDeviceID? = nil
    private var currentOutputDeviceID: AudioDeviceID? = nil
    private var currentSystemOutputDeviceID: AudioDeviceID? = nil

    var devices: [Device] {
        return self.deviceList
    }
    var inputDevices: [Device] {
        return self.devices.filter {
            $0.input
        }
    }
    var outputDevices: [Device] {
        return self.devices.filter {
            $0.output
        }
    }
    
    var currentInputDevice: Device? {
        guard currentInputDeviceID != nil else {
            return nil
        }
        let device = deviceList.first(where: { $0.id == currentInputDeviceID })
        return device
    }
    var currentOutputDevice: Device? {
        guard currentOutputDeviceID != nil else {
            return nil
        }
        let device = deviceList.first(where: { $0.id == currentOutputDeviceID })
        return device
    }
    var currentSystemOutputDevice: Device? {
        guard currentSystemOutputDeviceID != nil else {
            return nil
        }
        let device = deviceList.first(where: { $0.id == currentSystemOutputDeviceID })
        return device
    }
    
    init() {
        // get the current input device
        guard let curInDevice = self.getCurrentInputDevice() else {
            return
        }
        guard let curOutDevice = self.getCurrentOutputDevice() else {
            return
        }
        guard let curSystemOutDevice = self.getCurrentSystemOutputDevice() else {
            return
        }
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
        currentInputDeviceID = curInDevice
        currentOutputDeviceID = curOutDevice
        currentSystemOutputDeviceID = curSystemOutDevice
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
        AudioObjectGetPropertyData(id, &inputStreamConfigAddress, 0, nil, &inputStreamConfigAddressSize, &inputStreamConfig)
        
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
        AudioObjectGetPropertyData(id, &outputStreamConfigAddress, 0, nil, &outputStreamConfigAddressSize, &outputStreamConfig)
        
        // if the number of buffers in the output scope is greater than 0, that
        // means it can act as an "output" device
        return outputStreamConfig.mNumberBuffers > 0
    }
    
    // get the current input device
    private func getCurrentInputDevice () -> AudioDeviceID? {
        // get the current input device. This is listed as the "default" input device in
        // the AudioSystemObject
        var currentInputDeviceAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultInputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementName)
        guard AudioObjectHasProperty(AudioObjectID(kAudioObjectSystemObject), &currentInputDeviceAddress) else {
            return nil
        }
        
        // get the size of the audio device ID
        var currentInputDeviceAddressSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &currentInputDeviceAddress, 0, nil, &currentInputDeviceAddressSize) == noErr else {
            return nil
        }
        
        // get the device ID of the current input device
        var currentInputDevice: AudioDeviceID = 0
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &currentInputDeviceAddress, 0, nil, &currentInputDeviceAddressSize, &currentInputDevice) == noErr else {
            return nil
        }
        
        return currentInputDevice
    }
    
    // get the current output device
    private func getCurrentOutputDevice () -> AudioDeviceID? {
        // get the current output device. This is listed as the "default" output device in
        // the AudioSystemObject
        var currentOutputDeviceAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementName)
        guard AudioObjectHasProperty(AudioObjectID(kAudioObjectSystemObject), &currentOutputDeviceAddress) else {
            return nil
        }
        
        // get the size of the audio device ID
        var currentOutputDeviceAddressSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &currentOutputDeviceAddress, 0, nil, &currentOutputDeviceAddressSize) == noErr else {
            return nil
        }
        
        // get the device ID of the current output device
        var currentOutputDevice: AudioDeviceID = 0
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &currentOutputDeviceAddress, 0, nil, &currentOutputDeviceAddressSize, &currentOutputDevice) == noErr else {
            return nil
        }
        
        return currentOutputDevice
    }
    
    // get the current system output device
    private func getCurrentSystemOutputDevice () -> AudioDeviceID? {
        // get the current system output device. This is listed as the "default" system output device in
        // the AudioSystemObject
        var currentSystemOutputDeviceAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultSystemOutputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementName)
        guard AudioObjectHasProperty(AudioObjectID(kAudioObjectSystemObject), &currentSystemOutputDeviceAddress) else {
            return nil
        }
        
        // get the size of the audio device ID
        var currentSystemOutputDeviceAddressSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &currentSystemOutputDeviceAddress, 0, nil, &currentSystemOutputDeviceAddressSize) == noErr else {
            return nil
        }
        
        // get the device ID of the current system output device
        var currentSystemOutputDevice: AudioDeviceID = 0
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &currentSystemOutputDeviceAddress, 0, nil, &currentSystemOutputDeviceAddressSize, &currentSystemOutputDevice) == noErr else {
            return nil
        }
        
        return currentSystemOutputDevice
    }
}
