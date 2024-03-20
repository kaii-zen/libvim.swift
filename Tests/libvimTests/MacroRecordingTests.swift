//
//  MacroRecordingTests.swift
//
//
//  Created by Kaï-Zen Berg-Šæmañn on 2024-03-03.
//

import XCTest
@testable import libvim

final class MacroRecordingTests: VimTestCase {
//    static int updateCount = 0;
//    static int lastLnum = 0;
//    static int lastLnume = 0;
//    static long lastXtra = 0;
//
//    static int macroStartCallbackCount = 0;
//    static int macroStopCallbackCount = 0;
//
//    static int lastStartRegname = -1;
//    static int lastStopRegname = -1;
//    static char_u *lastRegvalue = NULL;

    var updateCount = 0
    var lastLnum: UInt = 0
    var lastLnume: UInt = 0
    var lastXtra = 0

    var macroStartCallbackCount = 0
    var macroStopCallbackCount = 0

    var lastStartRegname = NUL
    var lastStopRegname = NUL
    var lastRegvalue: String!

    override func setUp() {
        super.setUp()

        vimSetBufferUpdateCallback { [unowned self] update in
            lastLnum = update.lnum
            lastLnume = update.lnume
            lastXtra = update.xtra
            updateCount++
        }

        vimMacroSetStartRecordCallback { [unowned self] regname in
            lastStartRegname = regname
            macroStartCallbackCount++
        }

        vimMacroSetStopRecordCallback { [unowned self] regname, regvalue in
            lastStopRegname = regname
            lastRegvalue = regvalue
            macroStopCallbackCount++
        }

        vimKey("<esc>");
        vimKey("<esc>");
        vimExecute("e!");

        vimInput("g");
        vimInput("g");

    }

    func test_macro_saves_register() {
        /* Record a macro into the 'a' register */
        vimInput("q");
        vimInput("a");

        mu_check(macroStartCallbackCount == 1);
        mu_check(lastStartRegname == "a");

        vimInput("j");
        vimInput("j");
        vimInput("j");
        vimInput("k");
        vimInput("k");

        /* Stop recording */

        vimInput("q");
        mu_check(macroStopCallbackCount == 1);
        mu_check(lastStopRegname == "a");
        mu_check(strcmp(lastRegvalue, "jjjkk") == 0);

        /* Validate register */

        let lines = vimRegisterGet("a")

        mu_check(lines.count == 1);
        mu_check(strcmp(lines[0], ("jjjkk")) == 0);
    }
}
