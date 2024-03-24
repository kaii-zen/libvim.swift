//
//  VimTestCase.swift
//  
//
//  Created by Kaï-Zen Berg-Šæmañn on 2024-03-06.
//

import XCTest
import libvim

class VimTestCase: XCTestCase {
    var curbuf: Vim.Buffer {
        vimBufferGetCurrent()
    }
    
    func generateTemporaryFilename() -> String {
        FileManager
            .default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .path(percentEncoded: false)
    }

    func mu_check(_ condition: Bool) {
        XCTAssert(condition)
    }

    private static var vimInitialized = false

    class func vimInitOnce() {
        if !vimInitialized {
            vimInitialized = true
            vimInit()
        }
    }

    class override func setUp() {
        super.setUp()
        vimInitOnce()

        vimWindowSetWidth(5)
        vimWindowSetHeight(100)

        vimBufferOpen(testfile, 1, 0);
    }
}
