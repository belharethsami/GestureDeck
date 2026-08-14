#!/usr/bin/env swift

import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("Usage: generate-icon.swift OUTPUT.png\n".utf8))
    exit(2)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let canvas = NSSize(width: 1024, height: 1024)
let image = NSImage(size: canvas)

image.lockFocus()

let background = NSBezierPath(
    roundedRect: NSRect(x: 44, y: 44, width: 936, height: 936),
    xRadius: 220,
    yRadius: 220
)
NSGradient(colors: [
    NSColor(red: 0.15, green: 0.23, blue: 0.64, alpha: 1),
    NSColor(red: 0.42, green: 0.20, blue: 0.70, alpha: 1)
])!.draw(in: background, angle: -35)

if let hand = NSImage(
    systemSymbolName: "hand.draw.fill",
    accessibilityDescription: nil
)?.withSymbolConfiguration(.init(pointSize: 390, weight: .semibold)) {
    hand.isTemplate = true
    NSColor.white.withAlphaComponent(0.94).set()
    hand.draw(
        in: NSRect(x: 280, y: 270, width: 464, height: 464),
        from: .zero,
        operation: .sourceOver,
        fraction: 1
    )
}

let arrowConfiguration = NSImage.SymbolConfiguration(pointSize: 112, weight: .bold)
let arrows: [(String, NSRect)] = [
    ("arrow.up", NSRect(x: 456, y: 750, width: 112, height: 112)),
    ("arrow.down", NSRect(x: 456, y: 158, width: 112, height: 112)),
    ("arrow.left", NSRect(x: 145, y: 455, width: 112, height: 112)),
    ("arrow.right", NSRect(x: 767, y: 455, width: 112, height: 112))
]

for (symbol, rect) in arrows {
    if let arrow = NSImage(
        systemSymbolName: symbol,
        accessibilityDescription: nil
    )?.withSymbolConfiguration(arrowConfiguration) {
        NSColor.white.withAlphaComponent(0.72).set()
        arrow.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
    }
}

image.unlockFocus()

guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let png = bitmap.representation(using: .png, properties: [:])
else {
    FileHandle.standardError.write(Data("Could not render icon\n".utf8))
    exit(1)
}

try png.write(to: outputURL, options: .atomic)
