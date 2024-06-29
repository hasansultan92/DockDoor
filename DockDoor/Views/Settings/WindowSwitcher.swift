//
//  WindowSwitcher.swift
//  DockDoor
//
//  Created by Hasan Sultan on 6/25/24.
//


import SwiftUI
import Defaults
import Carbon

struct WindowSwitcherSettingsView: View {
    @State private var currentShortcut : UserKeyboardShortcut?
    @State private var isRecording = false // Default value
    @Default(.showWindowSwitcher) var showWindowSwitcher
    @Default(.defaultCMDTABKeybind) var defaultCMDTABKeybind
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $showWindowSwitcher, label: {
                Text("Enable Window Switcher")
            }).onChange(of: showWindowSwitcher){
                _, newValue in
                restartApplication()
            }
            if (Defaults[.showWindowSwitcher]){
                Toggle(isOn: $defaultCMDTABKeybind, label: {
                    Text("Use Default MacOS keybind ⌘ + Tab")
                }).onChange(of: defaultCMDTABKeybind){
                    _, newValue in
                }
                if (!Defaults[.defaultCMDTABKeybind]){
                    
                    Text("Press any key combination to set the keybind").padding()
                    Button(action: {self.isRecording = true}){
                        Text(isRecording ? "Press shortcut ..." : "Record shortcut")
                    } .keyboardShortcut(.defaultAction)
                    if let shortcut = currentShortcut {
                        Text("Current Keybind: \(shortcutDescription(shortcut))").padding()
                    }
                }
            }
        }
        .background(ShortcutCaptureView(currentShortcut: $currentShortcut, isRecording: $isRecording))
        .onAppear{
                currentShortcut = UserDefaults.standard.getKeyboardShortcut()
            }
        .padding(20)
        .frame(minWidth: 600)
    }
    func shortcutDescription(_ shortcut: UserKeyboardShortcut) -> String {
            var parts: [String] = []

            if shortcut.modifierFlags.contains(.command) {
                parts.append("⌘")
            }
            if shortcut.modifierFlags.contains(.option) {
                parts.append("⌥")
            }
            if shortcut.modifierFlags.contains(.control) {
                parts.append("⌃")
            }
            if shortcut.modifierFlags.contains(.shift) {
                parts.append("⇧")
            }

            parts.append(String(describing: KeyCodeConverter.string(from: shortcut.keyCode)))

            return parts.joined(separator: " ")
        }
}

struct ShortcutCaptureView: NSViewRepresentable {
    @Binding var currentShortcut: UserKeyboardShortcut?
    @Binding var isRecording: Bool

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard self.isRecording else {
                return event
            }
            self.isRecording = false
            let newShortcut = UserKeyboardShortcut(keyCode: event.keyCode, modifierFlags: event.modifierFlags)
            self.currentShortcut = newShortcut
            UserDefaults.standard.saveKeyboardShortcut(newShortcut)
            return nil
        }
        return view
    }


    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct KeyCodeConverter {
    static func string(from keyCode: UInt16) -> String {
        switch keyCode {
        case 48:
            return "⇥" // Tab symbol
        case 51:
            return "⌫" // Delete symbol
        case 53:
            return "⎋" // Escape symbol
        case 36:
            return "↩︎" // Return symbol
        default:

            let source = TISCopyCurrentKeyboardInputSource().takeUnretainedValue()
            let layoutData = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
            
            guard let data = layoutData else {
                return "?"
            }
            
            let layout = unsafeBitCast(data, to: CFData.self)
            let keyboardLayout = unsafeBitCast(CFDataGetBytePtr(layout), to: UnsafePointer<UCKeyboardLayout>.self)
            
            var keysDown: UInt32 = 0
            var chars = [UniChar](repeating: 0, count: 4)
            var realLength: Int = 0
            
            let result = UCKeyTranslate(keyboardLayout,
                                        keyCode,
                                        UInt16(kUCKeyActionDisplay),
                                        0,
                                        UInt32(LMGetKbdType()),
                                        UInt32(kUCKeyTranslateNoDeadKeysBit),
                                        &keysDown,
                                        chars.count,
                                        &realLength,
                                        &chars)
            
            if result == noErr {
                return String(utf16CodeUnits: chars, count: realLength)
            } else {
                return "?"
            }
        }
    }
}
