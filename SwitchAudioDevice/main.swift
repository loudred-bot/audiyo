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
 * - [x] "-a" show all audio devices                                        --- audiyo list
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

let adm = AudioDeviceManager()

struct AudiYo: ParsableCommand {
    static var configuration: CommandConfiguration = CommandConfiguration(
        commandName: "audiyo",
        abstract: "Display and manage audio devices from the terminal",
        subcommands: [List.self, Show.self],
        defaultSubcommand: List.self
//        subcommands: [List.self, Show.self, Info.self, Set.self],
//        defaultSubcommand: Show.self
    )
    
    struct List: ParsableCommand {
        static var configuration: CommandConfiguration = CommandConfiguration(
            abstract:"List all of the devices on this computer."
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
            abstract:"List the current audio devices in use."
        )
    
        @Option(
            name: [.customShort("t"), .long],
            help: "The types of audio device to display. You can select either 'input', 'output', or 'system'. If this argument is not specified, this command will display all of the current audio devices"
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
}

AudiYo.main()

//struct SwitchAudioDevice: ParsableCommand {
//
//    @Flag(name: [.customShort("a")], help: "show all audio devices.")
//    var showAll = false
//
//    func run() {
//        if showAll {
//            let adm = AudioDeviceManager()
//
//            if let inDevice = adm.currentInputDevice {
//                print("Current Input Device")
//                print(inDevice.name)
//                print("\tid: " + String(inDevice.id))
//                print("\tinput: " + String(inDevice.input))
//                print("\toutput: " + String(inDevice.output))
//                print("")
//            }
//
//            print("Devices:")
//            for device in adm.devices {
//                print(device.name)
//                print("\tid: " + String(device.id))
//                print("\tinput: " + String(device.input))
//                print("\toutput: " + String(device.output))
//            }
//        } else {
//            print("Hello, world!")
//        }
//    }
//}
//
//SwitchAudioDevice.main()
