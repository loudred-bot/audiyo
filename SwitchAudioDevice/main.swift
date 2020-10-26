//
//  main.swift
//  SwitchAudioDevice
//
//  Created by Blair Wilcox on 10/20/20.
//

/**
 * GOAL: Replicate the functionality of switchaudio-osx using
 * modern Apple APIs.
 *
 * TODO:
 * - [ ] "-a" show all audio devices                                        --- audiyo list
 * - [ ] "-c" show current audio device                                  --- audiyo
 * - [ ] "-t {device}" show the type of the specified device    --- audiyo info {device}
 * - [ ] "-c" cycle to the next audio device                             --- audiyo next
 * - [ ] "-s {device}" set the audio device                              --- audiyo set {device}
 * - [ ] "-h" help                                                                     --- audiyo -h, audiyo --help
 *
 * NAME:
 * swad - SWitch Audio Device
 */


/**
 * It looks like this isn't going to be straightforward. It seems like it's returning
 * addresses rather than variables. This seems like it might be helpful in
 * telling us how to interpret this:
 *
 * https://gist.github.com/glaurent/b4e9a2a1bc5223977df428e03d465560
 */

import ArgumentParser
import CoreAudio



func getAudioDeviceInfo () {
    
    /**
     * This is REALLY low-level stuff. We need to get this data from memory addresses,
     * so there are a lot of steps that involve getting addresses and determining the size
     * of the data before we can actually get the data we need.
     *
     *@TODO Need to abstract this into a high-level API
     *~reccanti 10/20/2020
     */
    
    // get the address of where we store the Audio Devices
    var propertyAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)

    // get the number of audio devices
    var propertySize:UInt32 = 0
    guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &propertySize) == noErr else {
        return
    }
    let numDevices = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
    
    // get the audio devices
    var devices = [AudioDeviceID](repeating: 0, count: numDevices)
    guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &propertySize, &devices) == noErr else {
        return
    }
    var deviceAddress = AudioObjectPropertyAddress()
    var deviceNameCString = [CChar](repeating: 0, count: 64)
    // var manufacturerNameCString = [CChar](repeating: 0, count: 64)
    
    for deviceID in devices {
        propertySize = UInt32(MemoryLayout<CChar>.size * 64)
        deviceAddress.mSelector = kAudioDevicePropertyDeviceName
        deviceAddress.mScope = kAudioObjectPropertyScopeGlobal
        deviceAddress.mElement = kAudioObjectPropertyElementMaster
        
        guard AudioObjectGetPropertyData(deviceID, &deviceAddress, 0, nil, &propertySize, &deviceNameCString) == noErr else {
            break
        }
        
        print(String(cString: deviceNameCString))
    }
}

struct SwitchAudioDevice: ParsableCommand {
    
    @Flag(name: [.customShort("a")], help: "show all audio devices.")
    var showAll = false
    
    func run() {
        if showAll {
            let adm = AudioDeviceManager()
            for device in adm.devices {
                print(device.name)
                print("\tid: " + String(device.id))
                print("\tinput: " + String(device.input))
                print("\toutput: " + String(device.output))
            }
        } else {
            print("Hello, world!")
        }
    }
}

SwitchAudioDevice.main()
