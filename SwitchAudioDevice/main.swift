//
//  main.swift
//  SwitchAudioDevice
//
//  Created by Blair Wilcox on 10/20/20.
//


/**
 * It looks like this isn't going to be straightforward. It seems like it's returning
 * addresses rather than variables. This seems like it might be helpful in
 * telling us how to interpret this:
 *
 * https://gist.github.com/glaurent/b4e9a2a1bc5223977df428e03d465560
 */

import ArgumentParser
import CoreAudio

let adm = AudioDeviceManager()

struct AudiYo: ParsableCommand {
    static var configuration: CommandConfiguration = CommandConfiguration(
        commandName: "audiyo",
        abstract: "Display and manage audio devices from the terminal.",
        subcommands: [List.self, Show.self, Set.self],
        defaultSubcommand: Show.self
//        subcommands: [List.self, Show.self, Info.self, Set.self],
//        defaultSubcommand: Show.self
    )
    
    struct List: ParsableCommand {
        static var configuration: CommandConfiguration = CommandConfiguration(
            abstract: "List all of the devices on this computer."
        )
        
        func run() {
            for device in adm.inputDevices {
                print("input\t" + String(device.id) + "\t" + device.name)
            }
            for device in adm.outputDevices {
                print("output\t" + String(device.id) + "\t" + device.name)
            }
        }
    }
    
    struct Show: ParsableCommand {
        static var configuration: CommandConfiguration = CommandConfiguration(
            abstract: "List the current audio devices in use."
        )
    
        @Option(
            name: [.customShort("t"), .long],
            help: "The types of audio device to display. You can select either 'input', 'output', or 'system'. If this argument is not specified, this command will display all of the current audio devices."
        )
        var types: [String] = ["input", "output", "system"]
        
        func run() {
            for type in types {
                if (type == "input") {
                    if let device = adm.currentInputDevice {
                        print("input\t" + String(device.id) + "\t" + device.name)
                    }
                }
                if (type == "output") {
                    if let device = adm.currentOutputDevice {
                        print("output\t" + String(device.id) + "\t" + device.name)
                    }
                }
                if (type == "system") {
                    if let device = adm.currentSystemOutputDevice {
                        print("system\t" + String(device.id) + "\t" + device.name)
                    }
                }
            }
        }
    }
    
    struct Set: ParsableCommand {
        static var configuration: CommandConfiguration = CommandConfiguration(
            abstract: "Change the audio device"
        )
        
        @Option(
            name: [.customShort("t"), .long],
            help: "The type of the audio device to set. Either 'output', 'input', or 'system', If this value isn't specified, it will default to setting the output device."
        )
        var type: String = "output"
        
        @Argument(
            help: "The device to set. This argument can be either the ID of the device or the name of the device."
        )
        var deviceID: String?
        
        func run() {
            guard deviceID != nil else {
                return
            }
            
            // attempt to parse the deviceID into an AudioObjectID. If it can't
            // be parsed, we'll consider it to be the device name
            let parsedDeviceID = Int(deviceID!)
            var device: Device?
            if parsedDeviceID != nil {
                device = adm.getDeviceByID(id: AudioObjectID(parsedDeviceID!))
            } else {
                device = adm.getDeviceByName(name: deviceID!)
            }
            
            if device != nil {
                if type == "output" {
                    adm.setOutputDevice(device: device!)
                }
                if type == "input" {
                    adm.setInputDevice(device: device!)
                }
                if type == "system" {
                    adm.setSystemOutputDevice(device: device!)
                }
            }
        }
    }
}

AudiYo.main()
