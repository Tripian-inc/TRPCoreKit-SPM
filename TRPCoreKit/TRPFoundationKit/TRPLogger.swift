//
//  TRPLogger.swift
//  TRPFoundationKit
//
//  Created by EvrenYasar on 4.11.2019.
//  Copyright © 2019 Evren Yaşar. All rights reserved.
//

import Foundation
public class TRPLogger {
    
    public enum Level: String {
        case debug = "DEBUG"
        case error = "ERROR"
        case info = "INFO"
        case warning = "WARNING"
        
    }
    private var prefix: String?
    
    public init(prefixText: String? = nil) {
        self.prefix = prefixText
    }
    
    public func e(file: String = #file, line: Int = #line, function: String = #function, _ message: String) {
        showInPanel(file:file, line:line, function:function, message: message, level: TRPLogger.Level.error)
    }
    
    public func d(file: String = #file, line: Int = #line, function: String = #function, _ message: String) {
        showInPanel(file:file, line:line, function:function, message: message, level: TRPLogger.Level.debug)
    }
    
    public func i(file: String = #file, line: Int = #line, function: String = #function, _ message: String) {
        showInPanel(file:file, line:line, function:function, message: message, level: TRPLogger.Level.info)
    }
    
    public func w(file: String = #file, line: Int = #line, function: String = #function, _ message: String) {
        showInPanel(file:file, line:line, function:function, message: message, level: TRPLogger.Level.warning)
    }
    
    public func deInitialize(file: String = #file, line: Int = #line, function: String = #function) {
        showInPanel(file:file,
                    line:line,
                    function:function,
                    message: nil,
                    level: TRPLogger.Level.debug)
    }
    
    private func showInPanel(file: String = #file,
                             line: Int = #line,
                             function: String = #function,
                             message: String?,
                             level: Level) {
        var text = ""
        if let pref = prefix {
            text += "[\(pref)]"
        }
        text += "[\(getFileName(file)).\(function)] \(level.rawValue)"
        if let msg = message {
            text += ": \(msg)"
        }
        print(text)
    }
    
    private func getFileName(_ filePath: String) -> String {
        let parser = filePath.split(separator:"/")
        if let fileName = String(parser.last ?? "").split(separator: ".").first {
            return String(fileName)
        }
        return ""
    }
}
