//
//  MappingTests.swift
//
//
//  Created by Kaï-Zen Berg-Šæmañn on 2024-03-03.
//

import XCTest
@testable import libvim

final class MappingTests: VimTestCase {
    var mappingCallbackCount = 0
    var lastMapping: Vim.MapBlock!

    var unmappingCallbackCount = 0
    var lastUnmapKeys: String?
    var lastUnmapMode = NUL

    override func setUp() {
        super.setUp()

        vimSetInputMapCallback { [unowned self] in
            print("onMapping -",
                  "orig_keys: |\(String(describing: $0.m_orig_keys))|",
                  "keys: |\(String(describing: $0.m_keys))|",
                  "orig_str: |\(String(describing: $0.m_orig_str))|",
                  "script id: |\($0.m_script_ctx.sc_sid)|")

            lastMapping = $0;
            mappingCallbackCount++;
        }
        vimSetInputUnmapCallback { [unowned self] mode, origLhs in
            lastUnmapMode = mode
            lastUnmapKeys = origLhs
            unmappingCallbackCount++;
        }
        vimSetMessageCallback { title, message, _ in
            print("onMessage - title: |\(title)| contents: |\(message)|")
        }

        vimKey("<esc>");
        vimKey("<esc>");
        vimExecute("e!");

        vimInput("g");
        vimInput("g");
    }

    func test_simple_mapping()
    {
        vimExecute("inoremap jk <Esc>");

        mu_check(strcmp("jk", lastMapping.m_orig_keys) == 0);
        mu_check(strcmp("<Esc>", lastMapping.m_orig_str) == 0);
        mu_check(mappingCallbackCount == 1);
    };

    func test_lhs_termcode()
    {
        vimExecute("inoremap <Esc> jk");

        mu_check(strcmp("<Esc>", lastMapping.m_orig_keys) == 0);
        mu_check(strcmp("jk", lastMapping.m_orig_str) == 0);
        mu_check(mappingCallbackCount == 1);
    };

    func test_map_same_keys()
    {
        vimExecute("inoremap jj <Esc>");

        mu_check(mappingCallbackCount == 1);

        vimExecute("inoremap jj <F1>");

        mu_check(mappingCallbackCount == 2);
        mu_check(strcmp("jj", lastMapping.m_orig_keys) == 0);
        mu_check(strcmp("<F1>", lastMapping.m_orig_str) == 0);
    };

    func test_map_same_keys_multiple_modes()
    {
        vimExecute("inoremap jj <Esc>");

        mu_check(mappingCallbackCount == 1);

        vimExecute("nnoremap jj <F1>");

        mu_check(mappingCallbackCount == 2);
        mu_check(lastMapping.m_mode == NORMAL);
        mu_check(strcmp("jj", lastMapping.m_orig_keys) == 0);
        mu_check(strcmp("<F1>", lastMapping.m_orig_str) == 0);
    };

    func test_sid_resolution()
    {
        vimExecute("source \(collateral)/map_plug_sid.vim");
        mu_check(mappingCallbackCount == 1);

        vimExecute("call <SNR>1_sayhello()");
    };

    func test_simple_unmap()
    {
        vimExecute("imap jj <Esc>");

        mu_check(mappingCallbackCount == 1);

        vimExecute("iunmap jj");

        XCTAssertEqual(unmappingCallbackCount, 1);
        mu_check(strcmp("jj", lastUnmapKeys) == 0);
    };

    func test_map_clear()
    {
        //  vimExecute("inoremap jj <Esc>");
        //
        //  mu_check(mappingCallbackCount == 1);

        vimExecute("mapclear");

        mu_check(lastUnmapKeys == nil);
        mu_check(unmappingCallbackCount == 1);
    };
}
