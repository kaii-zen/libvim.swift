//
//  libvim.swift
//
//
//  Created by Kaï-Zen Berg-Šæmañn on 2024-03-03.
//

import clibvim

public enum Vim {}

let NORMAL = clibvim.NORMAL
let INSERT = clibvim.INSERT
let VISUAL = clibvim.VISUAL
let CMDLINE = clibvim.CMDLINE
let OP_PENDING = clibvim.OP_PENDING
let TERMINAL = clibvim.TERMINAL
let Ctrl_V = clibvim.Ctrl_V |> CUnsignedChar.init |> Character.init
let NUL = 0 |> CUnsignedChar.init |> Character.init

let EVENT_INSERTENTER = clibvim.EVENT_INSERTENTER
let EVENT_INSERTLEAVE = clibvim.EVENT_INSERTLEAVE

let EVENT_CMDLINECHANGED = clibvim.EVENT_CMDLINECHANGED
let EVENT_CMDLINEENTER = clibvim.EVENT_CMDLINEENTER
let EVENT_CMDLINELEAVE = clibvim.EVENT_CMDLINELEAVE

let EOL_UNKNOWN = Int(clibvim.EOL_UNKNOWN) /* not defined yet */
let EOL_UNIX = Int(clibvim.EOL_UNIX)     /* NL */
let EOL_DOS = Int(clibvim.EOL_DOS)      /* CR NL */
let EOL_MAC = Int(clibvim.EOL_MAC)      /* CR */

let FILE_CHANGED = clibvim.FILE_CHANGED


/*
 * Motion types, used for operators and for yank/delete registers.
 */
let MCHAR = clibvim.MCHAR /* character-wise movement/register */
let MLINE = clibvim.MLINE /* line-wise movement/register */
let MBLOCK = clibvim.MBLOCK /* block-wise register */

let MAUTO = clibvim.MAUTO /* Decide between MLINE/MCHAR */


public func win_setwidth(_ width: Int) {
    clibvim.win_setwidth(CInt(width))
}

public func win_setheight(_ height: Int) {
    clibvim.win_setheight(CInt(height))
}

public func vim_tempname(_ extraChar: Character, _ keep: Bool) -> String {
    let cString = clibvim.vim_tempname(
        CInt(extraChar.asciiValue!),
        CInt(keep)
    )
    return String(cString: cString!)
}

var curbuf: Vim.Buffer! {
    clibvim.curbuf
}

/*
 * vimInit
 *
 * This must be called prior to using any other methods.
 *
 * This expects an `argc` and an `argv` parameters,
 * for the command line arguments for this vim instance.
 */
//void vimInit(int argc, char **argv);
public func vimInit(_ args: String...) {
    clibvim.vimInit(CInt(args.count), args.cCharPointerPointer)
}


/***
 * Buffer Methods
 ***/

public extension Vim {
    // TODO: Wrap in RawRepresentable struct
    typealias Buffer = UnsafeMutablePointer<buf_T>

    struct BufferUpdate: RawRepresentable {
        public typealias RawValue = bufferUpdate_T
        let buf: Buffer
        let lnum: LineNumber  // first line with change
        let lnume: LineNumber // line below last changed line
        let xtra: Int         // number of extra lines (negative when deleting)

        public init?(rawValue: RawValue) {
            buf = rawValue.buf
            lnum = rawValue.lnum
            lnume = rawValue.lnume
            xtra = Int(rawValue.xtra)
        }

        public var rawValue: RawValue {
            .init(buf: buf,
                  lnum: lnum,
                  lnume: lnume,
                  xtra: CLong(xtra))
        }
    }
}

/*
 * vimBufferOpen
 *
 * Open a buffer and set as current.
 */

//buf_T *vimBufferOpen(char_u *ffname_arg, linenr_T lnum, int flags);

@discardableResult
public func vimBufferOpen(_ ffname: String, _ lnum: Int, _ flags: CInt) -> Vim.Buffer {
    ffname.withMutableCString {
        clibvim.vimBufferOpen($0, lnum, flags)
    }
}

/*
 * vimBufferLoad
 *
 * Load a buffer, but do not change current buffer.
 */

//buf_T *vimBufferLoad(char_u *ffname_arg, linenr_T lnum, int flags);
public func vimBufferLoad(_ ffname: String, _ lnum: Int, _ flags: CInt) -> Vim.Buffer {
    ffname.withMutableCString {
        clibvim.vimBufferLoad($0, lnum, flags)
    }
}

/*
 * vimBufferNew
 *
 * Create a new buffer
 */
//buf_T *vimBufferNew(int flags);

/*
 * vimBufferCheckIfChanged
 *
 * Check if the contents of a buffer have been changed on the filesystem, outside of libvim.
 * Returns 1 if buffer was changed (and changes the buffer contents)
 * Returns 2 if a message was displayed
 * Returns 0 otherwise
 */
//int vimBufferCheckIfChanged(buf_T *buf);
public func vimBufferCheckIfChanged(_ buf: Vim.Buffer) -> Int {
    Int(clibvim.vimBufferCheckIfChanged(buf))
}

//buf_T *vimBufferGetById(int id);
public func vimBufferGetById(_ id: Int) -> Vim.Buffer {
    clibvim.vimBufferGetById(CInt(id))
}
//buf_T *vimBufferGetCurrent(void);
public func vimBufferGetCurrent() -> Vim.Buffer {
    clibvim.vimBufferGetCurrent()
}
//void vimBufferSetCurrent(buf_T *buf);

//char_u *vimBufferGetFilename(buf_T *buf);
//char_u *vimBufferGetFiletype(buf_T *buf);
//int vimBufferGetId(buf_T *buf);
public func vimBufferGetId(_ buf: Vim.Buffer) -> Int {
    Int(clibvim.vimBufferGetId(buf))
}
//long vimBufferGetLastChangedTick(buf_T *buf);

public func vimBufferGetLastChangedTick(_ buf: Vim.Buffer) -> Int {
    clibvim.vimBufferGetLastChangedTick(buf)
}
//char_u *vimBufferGetLine(buf_T *buf, linenr_T lnum);
public func vimBufferGetLine(_ buf: Vim.Buffer!, _ lnum: Int) -> String {
    let ptr = clibvim.vimBufferGetLine(buf, lnum)
    return String(cString: ptr!)
}

//size_t vimBufferGetLineCount(buf_T *buf);

public func vimBufferGetLineCount(_ buf: Vim.Buffer) -> Int {
    clibvim.vimBufferGetLineCount(buf)
}

/*
 * vimBufferSetLines
 *
 * Set a range of lines into the buffer. The start parameter is zero based and inclusive.
 * The end parameter is exclusive. This means you can either replace existing lines, or
 * splice in new lines in-between existing lines.
 *
 * Examples:
 * vimBufferSetLines(buf, 0, 0, ["abc"], 1); // Insert "abc" above the current first line, pushing down all existing lines
 * vimBufferSetLines(buf, 0, 1, ["abc"], 1); // Set line 1 to "abc"
 * vimBufferSetLines(buf, 0, 2, ["abc"], 2); // Set line 1 to "abc", make line 2 empty
 * vimBufferSetLines(buf, 2, 2, ["abc"], 1); // Splice "abc" after the second line, pushing the existing lines from 3 on down
 *
 */
//void vimBufferSetLines(buf_T *buf, linenr_T start, linenr_T end, char_u **lines, int count);
//
public func vimBufferSetLines(_ buf: Vim.Buffer, _ start: Int, _ end: Int, _ lines: [String]) {
    let cLines = lines.cPointerPointer
    clibvim.vimBufferSetLines(buf, start, end, cLines, CInt(lines.count))
}

public func vimBufferSetLines(_ buf: Vim.Buffer, _ start: Int, _ end: Int, _ lines: [String], _ count: Int) {
    let cLines = lines.cPointerPointer
    clibvim.vimBufferSetLines(buf, start, end, cLines, CInt(count))
}

//int vimBufferGetModified(buf_T *buf);
public func vimBufferGetModified(_ buf: Vim.Buffer) -> Bool {
    clibvim.vimBufferGetModified(buf)
    |> Bool.init
}
//
//int vimBufferGetModifiable(buf_T *buf);
public func vimBufferGetModifiable(_ buf: Vim.Buffer) -> Bool {
    clibvim.vimBufferGetModifiable(buf)
    |> Bool.init
}
//void vimBufferSetModifiable(buf_T *buf, int modifiable);
public func vimBufferSetModifiable(_ buf: Vim.Buffer, _ modifiable: Bool) {
    clibvim.vimBufferSetModifiable(buf, CInt(modifiable))
}

//
//int vimBufferGetFileFormat(buf_T *buf);
public func vimBufferGetFileFormat(_ buf: Vim.Buffer) -> Int {
    Int(clibvim.vimBufferGetFileFormat(buf))
}

//void vimBufferSetFileFormat(buf_T *buf, int fileformat);
public func vimBufferSetFileFormat(_ buf: Vim.Buffer, _ fileformat: Int) {
    clibvim.vimBufferSetFileFormat(buf, CInt(fileformat))
}
//
//int vimBufferGetReadOnly(buf_T *buf);
public func vimBufferGetReadOnly(_ buf: Vim.Buffer) -> Bool {
    clibvim.vimBufferGetReadOnly(buf)
    |> Bool.init
}

//void vimBufferSetReadOnly(buf_T *buf, int modifiable);
public func vimBufferSetReadOnly(_ buf: Vim.Buffer, _ readOnly: Bool) {
    clibvim.vimBufferSetReadOnly(buf, CInt(readOnly))
}
//
//void vimSetBufferUpdateCallback(BufferUpdateCallback bufferUpdate);
public typealias BufferUpdateCallback = (_ bufferUpdate: Vim.BufferUpdate) -> Void
var vimBufferUpdateCallback: BufferUpdateCallback?

public func vimSetBufferUpdateCallback(_ callback: @escaping BufferUpdateCallback) {
    vimBufferUpdateCallback = callback
    let cCallback: clibvim.BufferUpdateCallback? = { cBufferUpdate in
        vimBufferUpdateCallback?(Vim.BufferUpdate(rawValue: cBufferUpdate)!)
    }
    clibvim.vimSetBufferUpdateCallback(cCallback)
}

/***
 * Autocommands
 ***/

public extension Vim {
    /*
     * Events for autocommands.
     */
    enum Event: RawRepresentable {
        public typealias RawValue = event_T

        case bufAdd,               // after adding a buffer to the buffer list
             bufDelete,            // deleting a buffer from the buffer list
             bufEnter,             // after entering a buffer
             bufFilePost,          // after renaming a buffer
             bufFilePre,           // before renaming a buffer
             bufHidden,            // just after buffer becomes hidden
             bufLeave,             // before leaving a buffer
             bufNew,               // after creating any buffer
             bufNewFile,           // when creating a buffer for a new file
             bufReadCmd,           // read buffer using command
             bufReadPost,          // after reading a buffer
             bufReadPre,           // before reading a buffer
             bufUnload,            // just before unloading a buffer
             bufWinEnter,          // after showing a buffer in a window
             bufWinLeave,          // just after buffer removed from window
             bufWipeOut,           // just before really deleting a buffer
             bufWriteCmd,          // write buffer using command
             bufWritePost,         // after writing a buffer
             bufWritePre,          // before writing a buffer
             cmdLineChanged,       // command line was modified
             cmdLineEnter,         // after entering the command line
             cmdLineLeave,         // before leaving the command line
             cmdUndefined,         // command undefined
             cmdWinEnter,          // after entering the cmdline window
             cmdWinLeave,          // before leaving the cmdline window
             colorScheme,          // after loading a colorscheme
             colorSchemePre,       // before loading a colorscheme
             completeChanged,      // after completion popup menu changed
             completeDone,         // after finishing insert complete
             cursorHold,           // cursor in same position for a while
             cursorHoldI,          // idem, in Insert mode
             cursorMoved,          // cursor was moved
             cursorMovedI,         // cursor was moved in Insert mode
             diffUpdated,          // after diffs were updated
             dirChanged,           // after user changed directory
             encodingChanged,      // after changing the 'encoding' option
             exitPre,              // before exiting
             fileAppendCmd,        // append to a file using command
             fileAppendPost,       // after appending to a file
             fileAppendPre,        // before appending to a file
             fileChangedRO,        // before first change to read-only file
             fileChangedShell,     // after shell command that changed file
             fileChangedShellPost, // after (not) reloading changed file
             fileReadCmd,          // read from a file using command
             fileReadPost,         // after reading a file
             fileReadPre,          // before reading a file
             fileType,             // new file type detected (user defined)
             fileWriteCmd,         // write to a file using command
             fileWritePost,        // after writing a file
             fileWritePre,         // before writing a file
             filterReadPost,       // after reading from a filter
             filterReadPre,        // before reading from a filter
             filterWritePost,      // after writing to a filter
             filterWritePre,       // before writing to a filter
             focusGained,          // got the focus
             focusLost,            // lost the focus to another app
             funcUndefined,        // if calling a function which doesn't exist
             guiEnter,             // after starting the GUI
             guiFailed,            // after starting the GUI failed
             insertChange,         // when changing Insert/Replace mode
             insertCharPre,        // before inserting a char
             insertEnter,          // when entering Insert mode
             insertLeave,          // when leaving Insert mode
             menuPopup,            // just before popup menu is displayed
             optionSet,            // option was set
             quickFixCmdPost,      // after :make, :grep etc.
             quickFixCmdPre,       // before :make, :grep etc.
             quitPre,              // before :quit
             remoteReply,          // upon string reception from a remote vim
             sessionLoadPost,      // after loading a session file
             shellCmdPost,         // after ":!cmd"
             shellFilterPost,      // after ":1,2!cmd", ":w !cmd", ":r !cmd".
             sourceCmd,            // sourcing a Vim script using command
             sourcePre,            // before sourcing a Vim script
             sourcePost,           // after sourcing a Vim script
             spellFileMissing,     // spell file missing
             stdinReadPost,        // after reading from stdin
             stdinReadPre,         // before reading from stdin
             swapExists,           // found existing swap file
             syntax,               // syntax selected
             tabClosed,            // after closing a tab page
             tabEnter,             // after entering a tab page
             tabLeave,             // before leaving a tab page
             tabNew,               // when entering a new tab page
             termChanged,          // after changing 'term'
             terminalOpen,         // after a terminal buffer was created
             termResponse,         // after setting "v:termresponse"
             textChanged,          // text was modified not in Insert mode
             textChangedI,         // text was modified in Insert mode
             textChangedP,         // TextChangedI with popup menu visible
             textYankPost,         // after some text was yanked
             user,                 // user defined autocommand
             vimEnter,             // after starting Vim
             vimLeave,             // before exiting Vim
             vimLeavePre,          // before exiting Vim and writing .viminfo
             vimResized,           // after Vim window was resized
             winEnter,             // after entering a window
             winLeave,             // before leaving a window
             winNew,               // when entering a new window
             // MUST be the last one
             numEvents

        public init?(rawValue: RawValue) {
            let value: Self? = switch rawValue {
            case EVENT_BUFADD:               .bufAdd
            case EVENT_BUFDELETE:            .bufDelete
            case EVENT_BUFENTER:             .bufEnter
            case EVENT_BUFFILEPOST:          .bufFilePost
            case EVENT_BUFFILEPRE:           .bufFilePre
            case EVENT_BUFHIDDEN:            .bufHidden
            case EVENT_BUFLEAVE:             .bufLeave
            case EVENT_BUFNEW:               .bufNew
            case EVENT_BUFNEWFILE:           .bufNewFile
            case EVENT_BUFREADCMD:           .bufReadCmd
            case EVENT_BUFREADPOST:          .bufReadPost
            case EVENT_BUFREADPRE:           .bufReadPre
            case EVENT_BUFUNLOAD:            .bufUnload
            case EVENT_BUFWINENTER:          .bufWinEnter
            case EVENT_BUFWINLEAVE:          .bufWinLeave
            case EVENT_BUFWIPEOUT:           .bufWipeOut
            case EVENT_BUFWRITECMD:          .bufWriteCmd
            case EVENT_BUFWRITEPOST:         .bufWritePost
            case EVENT_BUFWRITEPRE:          .bufWritePre
            case EVENT_CMDLINECHANGED:       .cmdLineChanged
            case EVENT_CMDLINEENTER:         .cmdLineEnter
            case EVENT_CMDLINELEAVE:         .cmdLineLeave
            case EVENT_CMDUNDEFINED:         .cmdUndefined
            case EVENT_CMDWINENTER:          .cmdWinEnter
            case EVENT_CMDWINLEAVE:          .cmdWinLeave
            case EVENT_COLORSCHEME:          .colorScheme
            case EVENT_COLORSCHEMEPRE:       .colorSchemePre
            case EVENT_COMPLETECHANGED:      .completeChanged
            case EVENT_COMPLETEDONE:         .completeDone
            case EVENT_CURSORHOLD:           .cursorHold
            case EVENT_CURSORHOLDI:          .cursorHoldI
            case EVENT_CURSORMOVED:          .cursorMoved
            case EVENT_CURSORMOVEDI:         .cursorMovedI
            case EVENT_DIFFUPDATED:          .diffUpdated
            case EVENT_DIRCHANGED:           .dirChanged
            case EVENT_ENCODINGCHANGED:      .encodingChanged
            case EVENT_EXITPRE:              .exitPre
            case EVENT_FILEAPPENDCMD:        .fileAppendCmd
            case EVENT_FILEAPPENDPOST:       .fileAppendPost
            case EVENT_FILEAPPENDPRE:        .fileAppendPre
            case EVENT_FILECHANGEDRO:        .fileChangedRO
            case EVENT_FILECHANGEDSHELL:     .fileChangedShell
            case EVENT_FILECHANGEDSHELLPOST: .fileChangedShellPost
            case EVENT_FILEREADCMD:          .fileReadCmd
            case EVENT_FILEREADPOST:         .fileReadPost
            case EVENT_FILEREADPRE:          .fileReadPre
            case EVENT_FILETYPE:             .fileType
            case EVENT_FILEWRITECMD:         .fileWriteCmd
            case EVENT_FILEWRITEPOST:        .fileWritePost
            case EVENT_FILEWRITEPRE:         .fileWritePre
            case EVENT_FILTERREADPOST:       .filterReadPost
            case EVENT_FILTERREADPRE:        .filterReadPre
            case EVENT_FILTERWRITEPOST:      .filterWritePost
            case EVENT_FILTERWRITEPRE:       .filterWritePre
            case EVENT_FOCUSGAINED:          .focusGained
            case EVENT_FOCUSLOST:            .focusLost
            case EVENT_FUNCUNDEFINED:        .funcUndefined
            case EVENT_GUIENTER:             .guiEnter
            case EVENT_GUIFAILED:            .guiFailed
            case EVENT_INSERTCHANGE:         .insertChange
            case EVENT_INSERTCHARPRE:        .insertCharPre
            case EVENT_INSERTENTER:          .insertEnter
            case EVENT_INSERTLEAVE:          .insertLeave
            case EVENT_MENUPOPUP:            .menuPopup
            case EVENT_OPTIONSET:            .optionSet
            case EVENT_QUICKFIXCMDPOST:      .quickFixCmdPost
            case EVENT_QUICKFIXCMDPRE:       .quickFixCmdPre
            case EVENT_QUITPRE:              .quitPre
            case EVENT_REMOTEREPLY:          .remoteReply
            case EVENT_SESSIONLOADPOST:      .sessionLoadPost
            case EVENT_SHELLCMDPOST:         .shellCmdPost
            case EVENT_SHELLFILTERPOST:      .shellFilterPost
            case EVENT_SOURCECMD:            .sourceCmd
            case EVENT_SOURCEPRE:            .sourcePre
            case EVENT_SOURCEPOST:           .sourcePost
            case EVENT_SPELLFILEMISSING:     .spellFileMissing
            case EVENT_STDINREADPOST:        .stdinReadPost
            case EVENT_STDINREADPRE:         .stdinReadPre
            case EVENT_SWAPEXISTS:           .swapExists
            case EVENT_SYNTAX:               .syntax
            case EVENT_TABCLOSED:            .tabClosed
            case EVENT_TABENTER:             .tabEnter
            case EVENT_TABLEAVE:             .tabLeave
            case EVENT_TABNEW:               .tabNew
            case EVENT_TERMCHANGED:          .termChanged
            case EVENT_TERMINALOPEN:         .terminalOpen
            case EVENT_TERMRESPONSE:         .termResponse
            case EVENT_TEXTCHANGED:          .textChanged
            case EVENT_TEXTCHANGEDI:         .textChangedI
            case EVENT_TEXTCHANGEDP:         .textChangedP
            case EVENT_TEXTYANKPOST:         .textYankPost
            case EVENT_USER:                 .user
            case EVENT_VIMENTER:             .vimEnter
            case EVENT_VIMLEAVE:             .vimLeave
            case EVENT_VIMLEAVEPRE:          .vimLeavePre
            case EVENT_VIMRESIZED:           .vimResized
            case EVENT_WINENTER:             .winEnter
            case EVENT_WINLEAVE:             .winLeave
            case EVENT_WINNEW:               .winNew
            case NUM_EVENTS:                 .numEvents
            default:                          nil
            }

            guard let value else { return nil }
            self = value
        }

        public var rawValue: RawValue {
            switch self {
            case .bufAdd:               EVENT_BUFADD
            case .bufDelete:            EVENT_BUFDELETE
            case .bufEnter:             EVENT_BUFENTER
            case .bufFilePost:          EVENT_BUFFILEPOST
            case .bufFilePre:           EVENT_BUFFILEPRE
            case .bufHidden:            EVENT_BUFHIDDEN
            case .bufLeave:             EVENT_BUFLEAVE
            case .bufNew:               EVENT_BUFNEW
            case .bufNewFile:           EVENT_BUFNEWFILE
            case .bufReadCmd:           EVENT_BUFREADCMD
            case .bufReadPost:          EVENT_BUFREADPOST
            case .bufReadPre:           EVENT_BUFREADPRE
            case .bufUnload:            EVENT_BUFUNLOAD
            case .bufWinEnter:          EVENT_BUFWINENTER
            case .bufWinLeave:          EVENT_BUFWINLEAVE
            case .bufWipeOut:           EVENT_BUFWIPEOUT
            case .bufWriteCmd:          EVENT_BUFWRITECMD
            case .bufWritePost:         EVENT_BUFWRITEPOST
            case .bufWritePre:          EVENT_BUFWRITEPRE
            case .cmdLineChanged:       EVENT_CMDLINECHANGED
            case .cmdLineEnter:         EVENT_CMDLINEENTER
            case .cmdLineLeave:         EVENT_CMDLINELEAVE
            case .cmdUndefined:         EVENT_CMDUNDEFINED
            case .cmdWinEnter:          EVENT_CMDWINENTER
            case .cmdWinLeave:          EVENT_CMDWINLEAVE
            case .colorScheme:          EVENT_COLORSCHEME
            case .colorSchemePre:       EVENT_COLORSCHEMEPRE
            case .completeChanged:      EVENT_COMPLETECHANGED
            case .completeDone:         EVENT_COMPLETEDONE
            case .cursorHold:           EVENT_CURSORHOLD
            case .cursorHoldI:          EVENT_CURSORHOLDI
            case .cursorMoved:          EVENT_CURSORMOVED
            case .cursorMovedI:         EVENT_CURSORMOVEDI
            case .diffUpdated:          EVENT_DIFFUPDATED
            case .dirChanged:           EVENT_DIRCHANGED
            case .encodingChanged:      EVENT_ENCODINGCHANGED
            case .exitPre:              EVENT_EXITPRE
            case .fileAppendCmd:        EVENT_FILEAPPENDCMD
            case .fileAppendPost:       EVENT_FILEAPPENDPOST
            case .fileAppendPre:        EVENT_FILEAPPENDPRE
            case .fileChangedRO:        EVENT_FILECHANGEDRO
            case .fileChangedShell:     EVENT_FILECHANGEDSHELL
            case .fileChangedShellPost: EVENT_FILECHANGEDSHELLPOST
            case .fileReadCmd:          EVENT_FILEREADCMD
            case .fileReadPost:         EVENT_FILEREADPOST
            case .fileReadPre:          EVENT_FILEREADPRE
            case .fileType:             EVENT_FILETYPE
            case .fileWriteCmd:         EVENT_FILEWRITECMD
            case .fileWritePost:        EVENT_FILEWRITEPOST
            case .fileWritePre:         EVENT_FILEWRITEPRE
            case .filterReadPost:       EVENT_FILTERREADPOST
            case .filterReadPre:        EVENT_FILTERREADPRE
            case .filterWritePost:      EVENT_FILTERWRITEPOST
            case .filterWritePre:       EVENT_FILTERWRITEPRE
            case .focusGained:          EVENT_FOCUSGAINED
            case .focusLost:            EVENT_FOCUSLOST
            case .funcUndefined:        EVENT_FUNCUNDEFINED
            case .guiEnter:             EVENT_GUIENTER
            case .guiFailed:            EVENT_GUIFAILED
            case .insertChange:         EVENT_INSERTCHANGE
            case .insertCharPre:        EVENT_INSERTCHARPRE
            case .insertEnter:          EVENT_INSERTENTER
            case .insertLeave:          EVENT_INSERTLEAVE
            case .menuPopup:            EVENT_MENUPOPUP
            case .optionSet:            EVENT_OPTIONSET
            case .quickFixCmdPost:      EVENT_QUICKFIXCMDPOST
            case .quickFixCmdPre:       EVENT_QUICKFIXCMDPRE
            case .quitPre:              EVENT_QUITPRE
            case .remoteReply:          EVENT_REMOTEREPLY
            case .sessionLoadPost:      EVENT_SESSIONLOADPOST
            case .shellCmdPost:         EVENT_SHELLCMDPOST
            case .shellFilterPost:      EVENT_SHELLFILTERPOST
            case .sourceCmd:            EVENT_SOURCECMD
            case .sourcePre:            EVENT_SOURCEPRE
            case .sourcePost:           EVENT_SOURCEPOST
            case .spellFileMissing:     EVENT_SPELLFILEMISSING
            case .stdinReadPost:        EVENT_STDINREADPOST
            case .stdinReadPre:         EVENT_STDINREADPRE
            case .swapExists:           EVENT_SWAPEXISTS
            case .syntax:               EVENT_SYNTAX
            case .tabClosed:            EVENT_TABCLOSED
            case .tabEnter:             EVENT_TABENTER
            case .tabLeave:             EVENT_TABLEAVE
            case .tabNew:               EVENT_TABNEW
            case .termChanged:          EVENT_TERMCHANGED
            case .terminalOpen:         EVENT_TERMINALOPEN
            case .termResponse:         EVENT_TERMRESPONSE
            case .textChanged:          EVENT_TEXTCHANGED
            case .textChangedI:         EVENT_TEXTCHANGEDI
            case .textChangedP:         EVENT_TEXTCHANGEDP
            case .textYankPost:         EVENT_TEXTYANKPOST
            case .user:                 EVENT_USER
            case .vimEnter:             EVENT_VIMENTER
            case .vimLeave:             EVENT_VIMLEAVE
            case .vimLeavePre:          EVENT_VIMLEAVEPRE
            case .vimResized:           EVENT_VIMRESIZED
            case .winEnter:             EVENT_WINENTER
            case .winLeave:             EVENT_WINLEAVE
            case .winNew:               EVENT_WINNEW
            case .numEvents:            NUM_EVENTS
            }
        }
    }
}

//void vimSetAutoCommandCallback(AutoCommandCallback autoCommandDispatch);

public typealias AutoCommandCallback = (_ event: Vim.Event, _ buffer: Vim.Buffer?) -> Void
var vimAutoCommandCallback: AutoCommandCallback?

public func vimSetAutoCommandCallback(_ callback: AutoCommandCallback?) {
    vimAutoCommandCallback = callback
    let cCallback: clibvim.AutoCommandCallback? = if callback != nil {
        { cEvent, buffer in
            vimAutoCommandCallback!(Vim.Event(rawValue: cEvent)!, buffer)
        }
    } else {
        nil
    }

    clibvim.vimSetAutoCommandCallback(cCallback)
}
/**
 * Commandline
 ***/

//char_u vimCommandLineGetType(void);
public func vimCommandLineGetType() -> Character {
    clibvim.vimCommandLineGetType()
    |> Character.init
}

//char_u *vimCommandLineGetText(void);
public func vimCommandLineGetText() -> String? {
    guard let ptr = clibvim.vimCommandLineGetText() else {
        return nil
    }
    return String(cString: ptr)
}

//int vimCommandLineGetPosition(void);
public func vimCommandLineGetPosition() -> Int {
    Int(clibvim.vimCommandLineGetPosition())
}

//void vimCommandLineGetCompletions(char_u ***completions, int *count);
public func vimCommandLineGetCompletions() -> [String] {
    var cCompletions: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>?
    var count: CInt = 0
    clibvim.vimCommandLineGetCompletions(&cCompletions, &count)
    let completions = UnsafeBufferPointer(start: cCompletions, count: Int(count))
    return completions.compactMap { $0.map { String(cString: $0) } }
}
//void vimSetCustomCommandHandler(CustomCommandCallback customCommandHandler);

public typealias CustomCommandCallback = (_ exCommand: Vim.ExCommand) -> Bool
var vimCustomCommandHandler: CustomCommandCallback?

public extension Vim {
    struct ExCommand: RawRepresentable {
        public typealias RawValue = exCommand_T

        public let command: String
        public let forceIt: Bool
        public let regName: Int

        public init?(rawValue: RawValue) {
            command = String(cString: rawValue.cmd)
            forceIt = Bool(rawValue.forceit)
            regName = Int(rawValue.regname)
        }

        public var rawValue: RawValue {
            .init(
                cmd: command.uCString,
                forceit: CInt(forceIt),
                regname: CInt(regName)
            )
        }
    }
}

public func vimSetCustomCommandHandler(_ handler: CustomCommandCallback?) {
    vimCustomCommandHandler = handler
    let cHandler: clibvim.CustomCommandCallback? = if handler != nil {
        {
            CInt(
                vimCustomCommandHandler!(
                    Vim.ExCommand(rawValue: $0!.pointee)!
                )
            )
        }
    } else {
        nil
    }
    clibvim.vimSetCustomCommandHandler(cHandler)
}

/**
 * Eval
 ***/

/***
 * vimEval
 *
 * Evaluate a string as vim script, and return the result as string.
 * Callee is responsible for freeing the command as well as the result.
 */
//char_u *vimEval(char_u *str);

public func vimEval(_ str: String) -> String? {
    str.withMutableCString {
        guard let result = clibvim.vimEval($0) else {
            return nil
        }
        return String(cString: result)
    }
}

//void vimSetFunctionGetCharCallback(FunctionGetCharCallback callback);
//public typealias FunctionGetCharCallback = (_ mode: Int, _ character: inout Character, _ modMask: inout Int) -> Bool
public typealias FunctionGetCharCallback = (_ mode: Int, _ character: UnsafeMutablePointer<CChar>?, _ modMask: UnsafeMutablePointer<CInt>?) -> Bool
var vimFunctionGetCharCallback: FunctionGetCharCallback?

public func vimSetFunctionGetCharCallback(_ callback: FunctionGetCharCallback?) {
    vimFunctionGetCharCallback = callback
    let cCallback: clibvim.FunctionGetCharCallback? = if callback != nil {
        { mode, character, modMask in
            vimFunctionGetCharCallback!(
                Int(mode),
                character,
                modMask
            )
            |> CInt.init
        }
    } else {
        nil
    }
    clibvim.vimSetFunctionGetCharCallback(cCallback)
}

/***
 * Cursor Methods
 ***/

public extension Vim {
    static let MAXCOL = clibvim.MAXCOL

    enum ScreenLineMotion: RawRepresentable {
        case h, l, m

        public init?(rawValue: screenLineMotion_T) {
            let value: Self? = switch rawValue {
            case MOTION_H: .h
            case MOTION_L: .l
            case MOTION_M: .m
            default: nil
            }

            guard let value else { return nil }
            self = value
        }

        public var rawValue: screenLineMotion_T {
            switch self {
            case .h: MOTION_H
            case .l: MOTION_L
            case .m: MOTION_M
            }
        }
    }

    enum Direction: RawRepresentable {
        public typealias RawValue = CInt
        case forward, backward, forwardFile, backwardFile

        public var rawValue: RawValue {
            switch self {
            case .forward: FORWARD
            case .backward: BACKWARD
            case .forwardFile: FORWARD_FILE
            case .backwardFile: BACKWARD_FILE
            }
        }

        public init?(rawValue: RawValue) {
            let value: Self? = switch rawValue {
            case FORWARD: .forward
            case BACKWARD: .backward
            case FORWARD_FILE: .forwardFile
            case BACKWARD_FILE: .backwardFile
            default: nil
            }

            guard let value else { return nil }
            self = value
        }
    }

    typealias ColumnNumber = colnr_T
    typealias LineNumber = linenr_T
}

//colnr_T vimCursorGetColumn(void);
public func vimCursorGetColumn() -> Vim.ColumnNumber {
    clibvim.vimCursorGetColumn()
}

//colnr_T vimCursorGetColumnWant(void);
public func vimCursorGetColumnWant() -> Vim.ColumnNumber {
    clibvim.vimCursorGetColumnWant()
}

//void vimCursorSetColumnWant(colnr_T curswant);
public func vimCursorSetColumnWant(_ column: Vim.ColumnNumber) {
    clibvim.vimCursorSetColumnWant(column)
}

//linenr_T vimCursorGetLine(void);

public func vimCursorGetLine() -> Vim.LineNumber {
    clibvim.vimCursorGetLine()
}

//pos_T vimCursorGetPosition(void);
public func vimCursorGetPosition() -> Vim.Position {
    clibvim.vimCursorGetPosition()
}

//void vimCursorSetPosition(pos_T pos);
public func vimCursorSetPosition(_ pos: Vim.Position) {
    clibvim.vimCursorSetPosition(pos)
}
//void vimSetCursorAddCallback(CursorAddCallback cursorAddCallback);
public typealias CursorAddCallback = (_ cursor: Vim.Position) -> Void
var vimCursorAddCallback: CursorAddCallback?

public func vimSetCursorAddCallback(_ callback: CursorAddCallback?) {
    vimCursorAddCallback = callback
    let cCallback: clibvim.CursorAddCallback? = if callback != nil {
        { cursor in
            vimCursorAddCallback!(cursor)
        }
    } else {
        nil
    }
    clibvim.vimSetCursorAddCallback(cCallback)
}

/***
 * vimCursorGetDesiredColumn
 *
 * Get the column that we'd like to be at - used to stay in the same
 * column for up/down cursor motions.
 */
//colnr_T vimCursorGetDesiredColumn(void);

/***
 * vimSetCursorMoveScreenLineCallback
 *
 * Callback when the cursor will be moved via screen lines (H, M, L).
 * Because the libvim-consumer is responsible for managing the view,
 * libvim needs information about the view to correctly handle these motions.
 */
//void vimSetCursorMoveScreenLineCallback(
//    CursorMoveScreenLineCallback cursorMoveScreenLineCallback);
public typealias CursorMoveScreenLineCallback = (_ motion: Vim.ScreenLineMotion, _ count: Int, _ startLine: Vim.LineNumber) -> Vim.LineNumber
var vimCursorMoveScreenLineCallback: CursorMoveScreenLineCallback?

public func vimSetCursorMoveScreenLineCallback(_ callback: CursorMoveScreenLineCallback?) {
    vimCursorMoveScreenLineCallback = callback
    let cCallback: clibvim.CursorMoveScreenLineCallback? = if callback != nil {
        { motion, count, startLine, destLinePtr in
            destLinePtr!.pointee = vimCursorMoveScreenLineCallback!(
                Vim.ScreenLineMotion(rawValue: motion)!,
                Int(count),
                startLine
            )
        }
    } else {
        nil
    }
    clibvim.vimSetCursorMoveScreenLineCallback(cCallback)
}

/***
 * vimSetCursorMoveScreenLineCallback
 *
 * Callback when the cursor will be moved via screen position (gj, gk).
 * Because the libvim-consumer is responsible for managing the view,
 * libvim needs information about the view to correctly handle these motions.
 */
//void vimSetCursorMoveScreenPositionCallback(
//    CursorMoveScreenPositionCallback cursorMoveScreenPositionCallback);

public typealias CursorMoveScreenPositionCallback = (_ direction: Vim.Direction, _ count: Int, _ srcLine: Vim.LineNumber, _ srcColumn: Vim.ColumnNumber, _ curswant: Vim.ColumnNumber) -> (Vim.LineNumber, Vim.ColumnNumber)
var vimCursorMoveScreenPositionCallback: CursorMoveScreenPositionCallback?

public func vimSetCursorMoveScreenPositionCallback(_ callback: CursorMoveScreenPositionCallback?) {
    vimCursorMoveScreenPositionCallback = callback
    let cCallback: clibvim.CursorMoveScreenPositionCallback? = if callback != nil {
        { direction, count, srcLine, srcColumn, curswant, destLinePtr, destColumnPtr in
            let (destLine, destColumn) = vimCursorMoveScreenPositionCallback!(
                Vim.Direction(rawValue: direction)!,
                Int(count),
                srcLine,
                srcColumn,
                curswant
            )
            destLinePtr!.pointee = destLine
            destColumnPtr!.pointee = destColumn
        }
    } else {
        nil
    }
    clibvim.vimSetCursorMoveScreenPositionCallback(cCallback)
}

/***
 * File I/O
 ***/
//void vimSetFileWriteFailureCallback(FileWriteFailureCallback fileWriteFailureCallback);
public typealias FileWriteFailureCallback = (_ failureReason: Vim.WriteFailureReason, _ buf: Vim.Buffer) -> Void
var vimFileWriteFailureCallback: FileWriteFailureCallback?

public extension Vim {
    typealias WriteFailureReason = writeFailureReason_T
}

public func vimSetFileWriteFailureCallback(_ callback: FileWriteFailureCallback?) {
    vimFileWriteFailureCallback = callback
    let cCallback: clibvim.FileWriteFailureCallback? = if callback != nil {
        { reason, buf in
            vimFileWriteFailureCallback!(
                reason,
                buf!
            )
        }
    } else {
        nil
    }
    clibvim.vimSetFileWriteFailureCallback(cCallback)
}

/***
 * User Input
 ***/

/***
 * vimInput
 *
 * vimInput(input) passes the string, verbatim, to vim to be processed,
 * without replacing term-codes. This means strings like "<LEFT>" are
 * handled literally. This function handles Unicode text correctly.
 */
//void vimInput(char_u *input);

public func vimInput(_ input: String) {
    input.withMutableCString {
        clibvim.vimInput($0)
    }
}

/***
 * vimKey
 *
 * vimKey(input) passes a string and escapes termcodes - so a
 * a string like "<LEFT>" will first be replaced with the appropriate
 * term-code, and handled.
 */
//void vimKey(char_u *key);

public func vimKey(_ key: String) {
    key.withMutableCString {
        clibvim.vimKey($0)
    }
}

/***
 * vimExecute
 *
 * vimExecute(cmd) executes a command as if it was typed at the command-line.
 *
 * Example: vimExecute("echo 'hello!');
 */
//void vimExecute(char_u *cmd);
public func vimExecute(_ cmd: String) {
    cmd.withMutableCString {
        clibvim.vimExecute($0)
    }
}

//void vimExecuteLines(char_u **lines, int lineCount);
public func vimExecuteLines(_ lines: [String]) {
    clibvim.vimExecuteLines(lines.cPointerPointer, CInt(lines.count))
}

/***
 * Auto-indent
 ***/

public typealias AutoIndentCallback = (_ lnum: Int, _ buf: Vim.Buffer, _ prevLine: String?, _ currentLine: String?) -> Int
var vimAutoIndentCallback: AutoIndentCallback!

//void vimSetAutoIndentCallback(AutoIndentCallback callback);

public func vimSetAutoIndentCallback(_ callback: @escaping AutoIndentCallback) {
    vimAutoIndentCallback = callback
    let cCallback: clibvim.AutoIndentCallback = { lnum, bufferPointer, prevLine, currentLine in
        vimAutoIndentCallback(
            Int(lnum),
            bufferPointer!,
            String?(prevLine),
            String?(currentLine))
        |> CInt.init
    }
    clibvim.vimSetAutoIndentCallback(cCallback)
}

/***
 * Colorschemes
 */

public extension Vim {
    struct ColorSchemeCompletionContext {
        let filter: String

        private var numSchemes: UInt {
            get { UInt(numSchemesPointer!.pointee) }
            set { numSchemesPointer!.pointee = CInt(newValue) }
        }

        var colorSchemes: [String] {
            get {
                Array(colorSchemesPointer!.pointee!, count: numSchemes)
                    .map { String(cString: $0!) }
            }
            set {
                colorSchemesPointer!.pointee = newValue.cPointerPointer
                numSchemes = UInt(newValue.count)
            }
        }

        let numSchemesPointer: UnsafeMutablePointer<CInt>?
        let colorSchemesPointer: UnsafeMutablePointer<UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>?>?
    }
}
//void vimColorSchemeSetChangedCallback(ColorSchemeChangedCallback callback);
public typealias ColorSchemeChangedCallback = (_ colorSchemeName: String?) -> Bool
var vimColorSchemeChangedCallback: ColorSchemeChangedCallback?

public func vimColorSchemeSetChangedCallback(_ callback: ColorSchemeChangedCallback?) {
    vimColorSchemeChangedCallback = callback
    let cCallback: clibvim.ColorSchemeChangedCallback? = if callback != nil {
        { colorSchemeName in
            String?(colorSchemeName)
            |> vimColorSchemeChangedCallback!
            |> CInt.init
        }
    } else {
        nil
    }
    clibvim.vimColorSchemeSetChangedCallback(cCallback)
}
//void vimColorSchemeSetCompletionCallback(ColorSchemeCompletionCallback callback);
public typealias ColorSchemeCompletionCallback = (_ context: inout Vim.ColorSchemeCompletionContext) -> Bool
var vimColorSchemeCompletionCallback: ColorSchemeCompletionCallback?

public func vimColorSchemeSetCompletionCallback(_ callback: ColorSchemeCompletionCallback?) {
    vimColorSchemeCompletionCallback = callback
    let cCallback: clibvim.ColorSchemeCompletionCallback? = if callback != nil {
        { filter, count, colorSchemes in
            var context = Vim.ColorSchemeCompletionContext(
                filter: String(cString: filter!),
                numSchemesPointer: count,
                colorSchemesPointer: colorSchemes
            )

            return vimColorSchemeCompletionCallback!(&context) ? 1 : 0
        }
    } else {
        nil
    }

    clibvim.vimColorSchemeSetCompletionCallback(cCallback)
}

/***
 * Mapping
 */

public extension Vim {
    // TODO: Wrap in RawRepresentable struct
    typealias MapBlock = mapblock_T
}
//void vimSetInputMapCallback(InputMapCallback mapCallback);
//typedef void (*InputMapCallback)(const mapblock_T *mapping);
public typealias InputMapCallback = (_ mapping: Vim.MapBlock) -> Void
var vimInputMapCallback: InputMapCallback?

public func vimSetInputMapCallback(_ mapCallback: InputMapCallback?) {
    vimInputMapCallback = mapCallback
    let cCallback: clibvim.InputMapCallback? = if mapCallback != nil {
        {
            vimInputMapCallback!($0!.pointee)
        }
    } else {
        nil
    }
    clibvim.vimSetInputMapCallback(cCallback)
}

/*
 * vimSetInputUnmapCallback
 *
 * Called when `unmap` family or `mapclear` is called
 * There are two arguments passed:
 * - `mode`: The mode (`iunmap`, `nunmap`, etc)
 * - `keys`: NULL if `mapclear` was used, or a `char_u*` describing the original keys
 */
//void vimSetInputUnmapCallback(InputUnmapCallback unmapCallback);
//typedef void (*InputUnmapCallback)(int mode, const char_u *orig_lhs);
public typealias InputUnmapCallback = (_ mode: Character, _ origLhs: String?) -> Void
var vimInputUnmapCallback: InputUnmapCallback?

public func vimSetInputUnmapCallback(_ unmapCallback: InputUnmapCallback?) {
    vimInputUnmapCallback = unmapCallback
    let cCallback: clibvim.InputUnmapCallback? = if unmapCallback != nil {
        {
            vimInputUnmapCallback!(Character($0), String?($1))
        }
    } else {
        nil
    }
    clibvim.vimSetInputUnmapCallback(cCallback)
}

/***
 * Messages
 ***/

//void vimSetMessageCallback(MessageCallback messageCallback);
//typedef enum
//{
//  MSG_INFO,
//  MSG_WARNING,
//  MSG_ERROR,
//} msgPriority_T;

public extension Vim {
    struct Message: RawRepresentable {
        public typealias RawValue = msg_T

        var contents: String = ""
        var title: String = ""
        let priority: MessagePriority

        public var rawValue: RawValue {
            RawValue(
                contents: contents.cString,
                title: title.cString,
                priority: priority.rawValue
            )
        }

        func send() {
            var rawValue = rawValue
            withUnsafeMutablePointer(to: &rawValue, msg2_send)
        }

        mutating func put(_ s: String) {
            contents += s
        }

        public init(contents: String = "", title: String = "", priority: MessagePriority) {
            self.contents = contents
            self.title = title
            self.priority = priority
        }

        public init?(rawValue: RawValue) {
            guard let priority = MessagePriority(rawValue: rawValue.priority) else {
                return nil
            }

            self.contents = String(cString: rawValue.contents)
            self.title = String(cString: rawValue.title)
            self.priority = priority
        }
    }

    enum MessagePriority: RawRepresentable {
        public typealias RawValue = msgPriority_T

        case info
        case warning
        case error

        public var rawValue: RawValue {
            switch self {
            case .info: MSG_INFO
            case .warning: MSG_WARNING
            case .error: MSG_ERROR
            }
        }

        public init?(rawValue: RawValue) {
            let value: Self? = switch rawValue {
            case MSG_INFO: .info
            case MSG_WARNING: .warning
            case MSG_ERROR: .error
            default: nil
            }

            guard let value else { return nil }
            self = value
        }
    }
}

public typealias MessagePriority = Vim.MessagePriority

public typealias MessageCallback = (_ title: String, _ message: String, _ priority: MessagePriority) -> Void
var vimMessageCallback: MessageCallback?

public func vimSetMessageCallback(_ callback: MessageCallback?) {
    vimMessageCallback = callback
    let cCallback: clibvim.MessageCallback? = if callback != nil {
        {
            message, kind, priority in
            let message = String(cString: message!)
            let kind = String(cString: kind!)
            let priority = MessagePriority(rawValue: priority)!
            vimMessageCallback?(message, kind, priority)
        }
    } else {
        nil
    }
    clibvim.vimSetMessageCallback(cCallback)
}

/**
 * Misc
 **/

public extension Vim {
    enum GotoTarget: RawRepresentable {
        public typealias RawValue = gotoTarget_T

        case definition
        case declaration
        case implementation
        case typeDefinition
        case hover
        case outline
        case messages

        public var rawValue: RawValue {
            switch self {
            case .definition: DEFINITION
            case .declaration: DECLARATION
            case .implementation: IMPLEMENTATION
            case .typeDefinition: TYPEDEFINITION
            case .hover: HOVER
            case .outline: OUTLINE
            case .messages: MESSAGES
            }
        }

        public init?(rawValue: RawValue) {
            let value: Self? = switch rawValue {
            case DEFINITION: .definition
            case DECLARATION: .declaration
            case IMPLEMENTATION: .implementation
            case TYPEDEFINITION: .typeDefinition
            case HOVER: .hover
            case OUTLINE: .outline
            case MESSAGES: .messages
            default: nil
            }

            guard let value else { return nil }
            self = value
        }
    }

    struct GotoRequest: RawRepresentable {
        public typealias RawValue = gotoRequest_T

        let count: Int
        let location: Position
        let target: GotoTarget

        public var rawValue: RawValue {
            gotoRequest_T(
                count: CInt(count),
                location: location,
                target: target.rawValue
            )
        }

        public init?(rawValue: RawValue) {
            self.count = Int(rawValue.count)
            self.location = rawValue.location
            self.target = GotoTarget(rawValue: rawValue.target)!
        }
    }

    enum FormatRequestType: RawRepresentable {
        public typealias RawValue = formatRequestType_T

        case indentation
        case formatting

        public var rawValue: RawValue {
            switch self {
            case .indentation: INDENTATION
            case .formatting: FORMATTING
            }
        }

        public init?(rawValue: RawValue) {
            let value: Self? = switch rawValue {
            case INDENTATION: .indentation
            case FORMATTING: .formatting
            default: nil
            }

            guard let value else { return nil }
            self = value
        }
    }

    struct FormatRequest: RawRepresentable {
        public typealias RawValue = formatRequest_T

        let formatType: FormatRequestType
        let returnCursor: Bool
        let start: Position
        let end: Position
        let buf: Buffer
        let cmd: String?

        public var rawValue: RawValue {
            RawValue(
                formatType: formatType.rawValue,
                returnCursor: returnCursor ? 1 : 0,
                start: start,
                end: end,
                buf: buf,
                cmd: cmd?.uCString
            )
        }

        public init?(rawValue: RawValue) {
            self.formatType = FormatRequestType(rawValue: rawValue.formatType)!
            self.returnCursor = Bool(rawValue.returnCursor)
            self.start = rawValue.start
            self.end = rawValue.end
            self.buf = rawValue.buf
            self.cmd = Character(rawValue.cmd.pointee) == NUL ? nil : String(cString: rawValue.cmd)
        }
    }

    //    typedef enum
    //    {
    //        CLEAR_MESSAGES
    //    } clearTarget_T;

    enum ClearTarget: RawRepresentable {
        public typealias RawValue = clearTarget_T

        case messages

        public var rawValue: RawValue {
            switch self {
            case .messages: CLEAR_MESSAGES
            }
        }

        public init?(rawValue: RawValue) {
            let value: Self? = switch rawValue {
            case CLEAR_MESSAGES: .messages
            default: nil
            }

            guard let value else { return nil }
            self = value
        }
    }

    //    typedef struct
    //    {
    //        int count;
    //        clearTarget_T target;
    //    } clearRequest_T;
    struct ClearRequest: RawRepresentable {
        public typealias RawValue = clearRequest_T

        let count: Int
        let target: ClearTarget

        public var rawValue: RawValue {
            RawValue(
                count: CInt(count),
                target: target.rawValue
            )
        }

        public init?(rawValue: RawValue) {
            self.count = Int(rawValue.count)
            self.target = ClearTarget(rawValue: rawValue.target)!
        }
    }

    //    typedef struct
    //    {
    //        char_u *fullname;
    //        char_u *shortname;
    //
    //        // Type can be:
    //        // Number or toggle: 1 -> value is in numval
    //        // String: 0 -> value is in stringval
    //        int type;
    //
    //        long numval;
    //        char_u *stringval;
    //        int opt_flags; // [ OPT_FREE | OPT_LOCAL | OPT_GLOBAL ]
    //        int hidden;
    //    } optionSet_T;
    struct OptionSet: RawRepresentable {
        public typealias RawValue = optionSet_T

        let fullname: String
        let shortname: String?
        let type: Int
        let numval: Int
        let stringval: String?
        let optFlags: Int
        let hidden: Int

        public var rawValue: RawValue {
            RawValue(
                fullname: fullname.uCString,
                shortname: shortname?.uCString,
                type: CInt(type),
                numval: CLong(numval),
                stringval: stringval?.uCString,
                opt_flags: CInt(optFlags),
                hidden: CInt(hidden)
            )
        }

        public init?(rawValue: RawValue) {
            self.fullname = String(cString: rawValue.fullname)
            self.shortname = String?(rawValue.shortname)
            self.type = Int(rawValue.type)
            self.numval = Int(rawValue.numval)
            self.stringval = String?(rawValue.stringval)
            self.optFlags = Int(rawValue.opt_flags)
            self.hidden = Int(rawValue.hidden)
        }
    }
}

// Set a callback for when various entities should be cleared - ie, messages.
//void vimSetClearCallback(ClearCallback clearCallback);
//typedef void (*ClearCallback)(clearRequest_T clearInfo);
public typealias ClearCallback = (_ clearInfo: Vim.ClearRequest) -> Void
var vimClearCallback: ClearCallback?

public func vimSetClearCallback(_ callback: ClearCallback?) {
    vimClearCallback = callback
    let cCallback: clibvim.ClearCallback? = if callback != nil {
        {
            let clearInfo = Vim.ClearRequest(rawValue: $0)!
            vimClearCallback!(clearInfo)
        }
    } else {
        nil
    }
    clibvim.vimSetClearCallback(cCallback)
}

// Set a callback for when output is produced (ie, `:!ls`)
//void vimSetOutputCallback(OutputCallback outputCallback);
//typedef void (*OutputCallback)(char_u *cmd, char_u *output, int isSilent);
public typealias OutputCallback = (_ cmd: String, _ output: String, _ isSilent: Bool) -> Void
var vimOutputCallback: OutputCallback?

public func vimSetOutputCallback(_ callback: OutputCallback?) {
    vimOutputCallback = callback
    let cCallback: clibvim.OutputCallback? = if callback != nil {
        {
            let cmd = String(cString: $0!)
            let output = String(cString: $1!)
            let isSilent = Bool($2)
            vimOutputCallback!(cmd, output, isSilent)
        }
    } else {
        nil
    }
    clibvim.vimSetOutputCallback(cCallback)
}

//
//void vimSetFormatCallback(FormatCallback formatCallback);
//typedef void (*FormatCallback)(formatRequest_T *formatRequest);
public typealias FormatCallback = (_ formatRequest: Vim.FormatRequest) -> Void
var vimFormatCallback: FormatCallback?

public func vimSetFormatCallback(_ callback: FormatCallback?) {
    vimFormatCallback = callback
    let cCallback: clibvim.FormatCallback? = if callback != nil {
        {
            let formatRequest = Vim.FormatRequest(rawValue: $0!.pointee)!
            vimFormatCallback!(formatRequest)
        }
    } else {
        nil
    }
    clibvim.vimSetFormatCallback(cCallback)
}

//void vimSetGotoCallback(GotoCallback gotoCallback);
public typealias GotoCallback = (_ gotoInfo: Vim.GotoRequest) -> Bool
var vimGotoCallback: GotoCallback?

public func vimSetGotoCallback(_ callback: GotoCallback?) {
    vimGotoCallback = callback
    let cCallback: clibvim.GotoCallback? = if callback != nil {
        {
            let gotoInfo = Vim.GotoRequest(rawValue: $0)!
            return vimGotoCallback!(gotoInfo) |> CInt.init
        }
    } else {
        nil
    }
    clibvim.vimSetGotoCallback(cCallback)
}
//void vimSetTabPageCallback(TabPageCallback tabPageCallback);
//void vimSetDirectoryChangedCallback(DirectoryChangedCallback callback);
public typealias DirectoryChangedCallback = (_ directory: String) -> Void
var vimDirectoryChangedCallback: DirectoryChangedCallback?

public func vimSetDirectoryChangedCallback(_ callback: @escaping DirectoryChangedCallback) {
    vimDirectoryChangedCallback = callback
    let cCallback: clibvim.DirectoryChangedCallback? = {
        directory in
        let directory = String(cString: directory!)
        vimDirectoryChangedCallback?(directory)
    }
    clibvim.vimSetDirectoryChangedCallback(cCallback)
}

//void vimSetOptionSetCallback(OptionSetCallback callback);
public typealias OptionSetCallback = (_ optionSet: Vim.OptionSet) -> Void
var vimOptionSetCallback: OptionSetCallback?

public func vimSetOptionSetCallback(_ callback: OptionSetCallback?) {
    vimOptionSetCallback = callback
    let cCallback: clibvim.OptionSetCallback? = if callback != nil {
        {
            let optionSet = Vim.OptionSet(rawValue: $0!.pointee)!
            vimOptionSetCallback!(optionSet)
        }
    } else {
        nil
    }
    clibvim.vimSetOptionSetCallback(cCallback)
}

/**
 * Operators
 **/

public extension Vim {
    enum ScrollDirection: RawRepresentable {
        public typealias RawValue = scrollDirection_T
        case cursorCenterV
        case cursorCenterH
        case cursorTop
        case cursorBottom
        case cursorLeft
        case cursorRight
        case lineUp
        case lineDown
        case halfPageDown
        case halfPageUp
        case pageDown
        case pageUp
        case halfPageLeft
        case halfPageRight
        case columnLeft
        case columnRight

        public init?(rawValue: RawValue) {
            let value: Self? = switch rawValue {
            case SCROLL_CURSOR_CENTERV: .cursorCenterV
            case SCROLL_CURSOR_CENTERH: .cursorCenterH
            case SCROLL_CURSOR_TOP: .cursorTop
            case SCROLL_CURSOR_BOTTOM: .cursorBottom
            case SCROLL_CURSOR_LEFT: .cursorLeft
            case SCROLL_CURSOR_RIGHT: .cursorRight
            case SCROLL_LINE_UP: .lineUp
            case SCROLL_LINE_DOWN: .lineDown
            case SCROLL_HALFPAGE_DOWN: .halfPageDown
            case SCROLL_HALFPAGE_UP: .halfPageUp
            case SCROLL_PAGE_DOWN: .pageDown
            case SCROLL_PAGE_UP: .pageUp
            case SCROLL_HALFPAGE_LEFT: .halfPageLeft
            case SCROLL_HALFPAGE_RIGHT: .halfPageRight
            case SCROLL_COLUMN_LEFT: .columnLeft
            case SCROLL_COLUMN_RIGHT: .columnRight
            default: nil
            }

            guard let value else {
                return nil
            }
            self = value
        }

        public var rawValue: RawValue {
            switch self {
            case .cursorCenterV: SCROLL_CURSOR_CENTERV
            case .cursorCenterH: SCROLL_CURSOR_CENTERH
            case .cursorTop: SCROLL_CURSOR_TOP
            case .cursorBottom: SCROLL_CURSOR_BOTTOM
            case .cursorLeft: SCROLL_CURSOR_LEFT
            case .cursorRight: SCROLL_CURSOR_RIGHT
            case .lineUp: SCROLL_LINE_UP
            case .lineDown: SCROLL_LINE_DOWN
            case .halfPageDown: SCROLL_HALFPAGE_DOWN
            case .halfPageUp: SCROLL_HALFPAGE_UP
            case .pageDown: SCROLL_PAGE_DOWN
            case .pageUp: SCROLL_PAGE_UP
            case .halfPageLeft: SCROLL_HALFPAGE_LEFT
            case .halfPageRight: SCROLL_HALFPAGE_RIGHT
            case .columnLeft: SCROLL_COLUMN_LEFT
            case .columnRight: SCROLL_COLUMN_RIGHT
            }
        }
    }
}
//void vimSetToggleCommentsCallback(ToggleCommentsCallback callback);
//typedef int (*ToggleCommentsCallback)(buf_T *buf, linenr_T startLine, linenr_T endLine, linenr_T *outCount, char_u ***outLines);

public typealias ToggleCommentsCallback = (_ buf: Vim.Buffer, _ startLine: Vim.LineNumber, _ endLine: Vim.LineNumber) -> [String]?
var vimToggleCommentsCallback: ToggleCommentsCallback?

public func vimSetToggleCommentsCallback(_ callback: ToggleCommentsCallback?) {
    vimToggleCommentsCallback = callback
    let cCallback: clibvim.ToggleCommentsCallback? = if callback != nil {
        { buf, startLine, endLine, outCount, outLines in
            guard let lines = vimToggleCommentsCallback!(buf!, startLine, endLine) else { return 0 }

            outLines!.pointee = lines.cPointerPointer
            outCount!.pointee = Vim.LineNumber(lines.count)

            return 1
        }
    } else {
        nil
    }
    clibvim.vimSetToggleCommentsCallback(cCallback)
}

/*
 * vimSetQuitCallback
 *
 * Called when a `:q`, `:qa`, `:q!` is called
 *
 * It is up to the libvim consumer how to handle the 'quit' call.
 * There are two arguments passed:
 * - `buffer`: the buffer quit was requested for
 * - `force`: a boolean if the command was forced (ie, if `q!` was used)
 */
//void vimSetQuitCallback(QuitCallback callback);
public typealias QuitCallback = (_ buffer: Vim.Buffer?, _ force: Bool) -> Void
var vimQuitCallback: QuitCallback?

public func vimSetQuitCallback(_ callback: QuitCallback?) {
    vimQuitCallback = callback
    let cCallback: clibvim.QuitCallback? = if callback != nil {
        {
            let buffer = $0
            let force = Bool($1)
            vimQuitCallback!(buffer, force)
        }
    } else {
        nil
    }
    clibvim.vimSetQuitCallback(cCallback)
}

/*
 * vimSetScrollCallback
 *
 * Called when the window should be scrolled (ie, `C-Y`, `zz`, etc).
 *
 */
//void vimSetScrollCallback(ScrollCallback callback);
//typedef void (*ScrollCallback)(scrollDirection_T dir, long count);
public typealias ScrollCallback = (_ dir: Vim.ScrollDirection, _ count: Int) -> Void
var vimScrollCallback: ScrollCallback?

public func vimSetScrollCallback(_ callback: ScrollCallback?) {
    vimScrollCallback = callback
    let cCallback: clibvim.ScrollCallback? = if callback != nil {
        {
            let dir = Vim.ScrollDirection(rawValue: $0)!
            let count = Int($1)
            vimScrollCallback!(dir, count)
        }
    } else {
        nil
    }
    clibvim.vimSetScrollCallback(cCallback)
}

/*
 * vimSetUnhandledEscapeCallback
 *
 * Called when <esc> is pressed in normal mode, but there is no
 * pending operator or action.
 *
 * This is intended for UI's to pick up and handle (for example,
 * to clear messages or alerts).
 */
//void vimSetUnhandledEscapeCallback(VoidCallback callback);
public typealias VoidCallback = () -> Void
var vimUnhandledEscapeCallback: VoidCallback?

public func vimSetUnhandledEscapeCallback(_ callback: VoidCallback?) {
    vimUnhandledEscapeCallback = callback
    let cCallback: clibvim.VoidCallback? = if callback != nil {
        {
            vimUnhandledEscapeCallback!()
        }
    } else {
        nil
    }
    clibvim.vimSetUnhandledEscapeCallback(cCallback)
}

/***
 * Macros
 */

//void vimMacroSetStartRecordCallback(MacroStartRecordCallback callback);
//typedef void (*MacroStartRecordCallback)(int regname);
public typealias MacroStartRecordCallback = (_ regName: Character) -> Void
var vimMacroStartRecordCallback: MacroStartRecordCallback?

public func vimMacroSetStartRecordCallback(_ callback: MacroStartRecordCallback?) {
    vimMacroStartRecordCallback = callback
    let cCallback: clibvim.MacroStartRecordCallback? = if callback != nil {
        {
            vimMacroStartRecordCallback!(Character($0))
        }
    } else {
        nil
    }
    clibvim.vimMacroSetStartRecordCallback(cCallback)
}
//void vimMacroSetStopRecordCallback(MacroStopRecordCallback callback);
//typedef void (*MacroStopRecordCallback)(int regname, char_u *regvalue);
public typealias MacroStopRecordCallback = (_ regName: Character, _ regValue: String) -> Void
var vimMacroStopRecordCallback: MacroStopRecordCallback?

public func vimMacroSetStopRecordCallback(_ callback: MacroStopRecordCallback?) {
    vimMacroStopRecordCallback = callback
    let cCallback: clibvim.MacroStopRecordCallback? = if callback != nil {
        {
            vimMacroStopRecordCallback!(Character($0), String(cString: $1!))
        }
    } else {
        nil
    }
    clibvim.vimMacroSetStopRecordCallback(cCallback)
}

/***
 * Options
 **/

let p_enc = String(cString: clibvim.p_enc)

public func chartabsize(_ c: Character, _ col: Vim.ColumnNumber) -> Int {
    var c = CUnsignedChar(c.asciiValue!)
    return Int(clibvim.chartabsize(&c, col))
}

//void vimOptionSetTabSize(int tabSize);
public func vimOptionSetTabSize(_ tabSize: Int) {
    clibvim.vimOptionSetTabSize(CInt(tabSize))
}

//void vimOptionSetInsertSpaces(int insertSpaces);
public func vimOptionSetInsertSpaces(_ insertSpaces: Bool) {
    clibvim.vimOptionSetInsertSpaces(insertSpaces ? 1 : 0)
}

//int vimOptionGetInsertSpaces(void);
public func vimOptionGetInsertSpaces() -> Bool {
    Bool(clibvim.vimOptionGetInsertSpaces())
}

//int vimOptionGetTabSize(void);
public func vimOptionGetTabSize() -> Int {
    Int(clibvim.vimOptionGetTabSize())
}

/***
 * Registers
 ***/

//void vimRegisterGet(int reg_name, int *num_lines, char_u ***lines);
public func vimRegisterGet(_ regName: Int) -> [String] {
    let numLines = UnsafeMutablePointer<CInt>.allocate(capacity: 1)
    let lines = UnsafeMutablePointer<UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>?>.allocate(capacity: 1)
    clibvim.vimRegisterGet(CInt(regName), numLines, lines)
    let result = Array(lines.pointee!, count: UInt(numLines.pointee))
        .map { String(cString: $0!) }
    return result
}

public func vimRegisterGet(_ regName: Character) -> [String] {
    vimRegisterGet(Int(char: regName))
}

/***
 * Undo
 ***/

//int vimUndoSaveCursor(void);
//int vimUndoSaveRegion(linenr_T start_lnum, linenr_T end_lnum);
@discardableResult
public func vimUndoSaveRegion(_ startLnum: Vim.LineNumber, _ endLnum: Vim.LineNumber) -> Bool {
    Bool(clibvim.vimUndoSaveRegion(startLnum, endLnum))
}

/*
 * vimUndoSync(force)
 *
 * Create a sync point (a new undo level) - stop adding to current
 * undo entry, and start a new one.
 */
//void vimUndoSync(int force);
public func vimUndoSync(_ force: Bool) {
    clibvim.vimUndoSync(CInt(force))
}

/***
 * Visual Mode
 ***/

//int vimVisualGetType(void);
public func vimVisualGetType() -> Character {
    //    Character(cInt: clibvim.vimVisualGetType())
    clibvim.vimVisualGetType()
    |> CUnsignedChar.init
    |> Character.init

}

//void vimVisualSetType(int);
//int vimVisualIsActive(void);
public func vimVisualIsActive() -> Bool {
    clibvim.vimVisualIsActive() != 0
}
//int vimSelectIsActive(void);
public func vimSelectIsActive() -> Bool {
    clibvim.vimSelectIsActive() != 0
}

/*
 * vimVisualGetRange
 *
 * If in visual mode or select mode, returns the current range.
 * If not in visual or select mode, returns the last visual range.
 */
//void vimVisualGetRange(pos_T *startPos, pos_T *endPos);
public extension Vim {
    typealias Position = pos_T
}

extension Vim.Position: Equatable {
    public static func == (lhs: Vim.Position, rhs: Vim.Position) -> Bool {
        lhs.lnum == rhs.lnum && lhs.col == rhs.col
    }
}

public func vimVisualGetRange() -> (start: Vim.Position, end: Vim.Position) {
    var (start, end) = (Vim.Position(), Vim.Position())
    clibvim.vimVisualGetRange(&start, &end)
    return (start, end)
}

/*
 * vimVisualSetStart
 *
 * If in visual mode or select mode, set the visual start position.
 * The visual range is the range from this start position to the cursor position
 *
 * Only has an effect in visual or select modes.
 */
//void vimVisualSetStart(pos_T startPos);

public func vimVisualSetStart(_ startPos: Vim.Position) {
    clibvim.vimVisualSetStart(startPos)
}

/***
 * Search
 ***/

public extension Vim {
    typealias SearchHighlight = searchHighlight_T
}

extension Vim.SearchHighlight: Equatable {
    public static func == (lhs: Vim.SearchHighlight, rhs: Vim.SearchHighlight) -> Bool {
        lhs.start == rhs.start && lhs.end == rhs.end
    }
}

/*
 * vimSearchGetMatchingPair
 *
 * Returns the position of a matching pair,
 * based on the current buffer and cursor position
 *
 * result is NULL if no match found.
 */
//pos_T *vimSearchGetMatchingPair(int initc);
public func vimSearchGetMatchingPair(_ initc: Int) -> Vim.Position? {
    clibvim.vimSearchGetMatchingPair(CInt(initc))?.pointee
}

public func vimSearchGetMatchingPair(_ initc: Character) -> Vim.Position? {
    vimSearchGetMatchingPair(Int(char: initc))
}

/*
 * vimSearchGetHighlights
 *
 * Get highlights for the current search
 */
//void vimSearchGetHighlights(buf_T *buf, linenr_T start_lnum, linenr_T end_lnum,
//                            int *num_highlights,
//                            searchHighlight_T **highlights);
public func vimSearchGetHighlights(_ buf: Vim.Buffer, _ startLnum: UInt, _ endLnum: UInt) -> [Vim.SearchHighlight] {
    var numHighlights: CInt = 0
    var highlights: UnsafeMutablePointer<Vim.SearchHighlight>?
    clibvim.vimSearchGetHighlights(buf, linenr_T(startLnum), linenr_T(endLnum), &numHighlights, &highlights)
    return Array(UnsafeBufferPointer(start: highlights, count: Int(numHighlights)))
}

/*
 * vimSearchGetPattern
 *
 * Get the current search pattern
 */
//char_u *vimSearchGetPattern();
public func vimSearchGetPattern() -> String {
    clibvim.vimSearchGetPattern() |> {
        String(cString: $0)
    }
}

//void vimSetStopSearchHighlightCallback(VoidCallback callback);
var vimStopSearchHighlightCallback: VoidCallback?

public func vimSetStopSearchHighlightCallback(_ callback: VoidCallback?) {
    vimStopSearchHighlightCallback = callback
    let cCallback: clibvim.VoidCallback? = if callback != nil {
        {
            vimStopSearchHighlightCallback!()
        }
    } else {
        nil
    }
    clibvim.vimSetStopSearchHighlightCallback(cCallback)
}

/***
 * Terminal
 */

public extension Vim {
    //    typedef struct
    //    {
    //        char_u *cmd;
    //        int rows;
    //        int cols;
    //        int curwin;
    //        char finish;
    //        int hidden;
    //    } terminalRequest_t;
    struct TerminalRequest: RawRepresentable {
        public typealias RawValue = terminalRequest_t

        let cmd: String?
        let rows: Int
        let cols: Int
        let curwin: Int
        let finish: Character
        let hidden: Bool

        public var rawValue: RawValue {
            .init(cmd: cmd?.uCString,
                  rows: CInt(rows),
                  cols: CInt(cols),
                  curwin: CInt(curwin),
                  finish: CChar(char: finish),
                  hidden: CInt(hidden))
        }

        public init?(rawValue: RawValue) {
            self.cmd = String?(rawValue.cmd)
            self.rows = Int(rawValue.rows)
            self.cols = Int(rawValue.cols)
            self.curwin = Int(rawValue.curwin)
            self.finish = Character(rawValue.finish)
            self.hidden = Bool(rawValue.hidden)
        }
    }
}
//void vimSetTerminalCallback(TerminalCallback callback);
public typealias TerminalCallback = (_ terminalRequest: Vim.TerminalRequest) -> Void
var vimTerminalCallback: TerminalCallback?

public func vimSetTerminalCallback(_ callback: TerminalCallback?) {
    vimTerminalCallback = callback
    let cCallback: clibvim.TerminalCallback? = if callback != nil {
        {
            vimTerminalCallback!(Vim.TerminalRequest(rawValue: $0!.pointee)!)
        }
    } else {
        nil
    }
    clibvim.vimSetTerminalCallback(cCallback)
}

/***
 * Window
 */

public extension Vim {
    //    typedef enum
    //    {
    //    } windowSplit_T;
    enum WindowSplit: RawRepresentable {
        public typealias RawValue = windowSplit_T

        case horizontal
        case horizontalNew
        case vertical
        case verticalNew
        case tab
        case tabNew

        public var rawValue: RawValue {
            switch self {
            case .horizontal: SPLIT_HORIZONTAL
            case .horizontalNew: SPLIT_HORIZONTAL_NEW
            case .vertical: SPLIT_VERTICAL
            case .verticalNew: SPLIT_VERTICAL_NEW
            case .tab: SPLIT_TAB
            case .tabNew: SPLIT_TAB_NEW
            }
        }

        public init?(rawValue: RawValue) {
            let value: Self? = switch rawValue {
            case SPLIT_HORIZONTAL: .horizontal
            case SPLIT_HORIZONTAL_NEW: .horizontalNew
            case SPLIT_VERTICAL: .vertical
            case SPLIT_VERTICAL_NEW: .verticalNew
            case SPLIT_TAB: .tab
            case SPLIT_TAB_NEW: .tabNew
            default: nil
            }

            guard let value else { return nil }
            self = value
        }
    }

    //    typedef enum
    //    {
    //        WIN_CURSOR_LEFT,           // <C-w>h
    //        WIN_CURSOR_RIGHT,          // <C-w>l
    //        WIN_CURSOR_UP,             // <C-w>k
    //        WIN_CURSOR_DOWN,           // <C-w>j
    //        WIN_MOVE_FULL_LEFT,        // <C-w>H
    //        WIN_MOVE_FULL_RIGHT,       // <C-w>L
    //        WIN_MOVE_FULL_UP,          // <C-w>K
    //        WIN_MOVE_FULL_DOWN,        // <C-w>J
    //        WIN_CURSOR_TOP_LEFT,       // <C-w>t
    //        WIN_CURSOR_BOTTOM_RIGHT,   // <C-w>b
    //        WIN_CURSOR_PREVIOUS,       // <C-w>p
    //        WIN_MOVE_ROTATE_DOWNWARDS, // <C-w>r
    //        WIN_MOVE_ROTATE_UPWARDS,   // <C-w>R
    //    } windowMovement_T;
    enum WindowMovement: RawRepresentable {
        public typealias RawValue = windowMovement_T

        case cursorLeft
        case cursorRight
        case cursorUp
        case cursorDown
        case moveFullLeft
        case moveFullRight
        case moveFullUp
        case moveFullDown
        case cursorTopLeft
        case cursorBottomRight
        case cursorPrevious
        case moveRotateDownwards
        case moveRotateUpwards

        public var rawValue: RawValue {
            switch self {
            case .cursorLeft:
                WIN_CURSOR_LEFT
            case .cursorRight: WIN_CURSOR_RIGHT
            case .cursorUp: WIN_CURSOR_UP
            case .cursorDown: WIN_CURSOR_DOWN
            case .moveFullLeft: WIN_MOVE_FULL_LEFT
            case .moveFullRight: WIN_MOVE_FULL_RIGHT
            case .moveFullUp: WIN_MOVE_FULL_UP
            case .moveFullDown: WIN_MOVE_FULL_DOWN
            case .cursorTopLeft: WIN_CURSOR_TOP_LEFT
            case .cursorBottomRight: WIN_CURSOR_BOTTOM_RIGHT
            case .cursorPrevious: WIN_CURSOR_PREVIOUS
            case .moveRotateDownwards: WIN_MOVE_ROTATE_DOWNWARDS
            case .moveRotateUpwards: WIN_MOVE_ROTATE_UPWARDS
            }
        }

        public init?(rawValue: RawValue) {
            let value: Self? = switch rawValue {
            case WIN_CURSOR_LEFT: .cursorLeft
            case WIN_CURSOR_RIGHT: .cursorRight
            case WIN_CURSOR_UP: .cursorUp
            case WIN_CURSOR_DOWN: .cursorDown
            case WIN_MOVE_FULL_LEFT: .moveFullLeft
            case WIN_MOVE_FULL_RIGHT: .moveFullRight
            case WIN_MOVE_FULL_UP: .moveFullUp
            case WIN_MOVE_FULL_DOWN: .moveFullDown
            case WIN_CURSOR_TOP_LEFT: .cursorTopLeft
            case WIN_CURSOR_BOTTOM_RIGHT: .cursorBottomRight
            case WIN_CURSOR_PREVIOUS: .cursorPrevious
            case WIN_MOVE_ROTATE_DOWNWARDS: .moveRotateDownwards
            case WIN_MOVE_ROTATE_UPWARDS: .moveRotateUpwards
            default: nil
            }

            guard let value else { return nil }
            self = value
        }
    }
}
//int vimWindowGetWidth(void);
public func vimWindowGetWidth() -> Int {
    Int(clibvim.vimWindowGetWidth())
}
//int vimWindowGetHeight(void);
public func vimWindowGetHeight() -> Int {
    Int(clibvim.vimWindowGetHeight())
}
//int vimWindowGetTopLine(void);
public func vimWindowGetTopLine() -> Int {
    Int(clibvim.vimWindowGetTopLine())
}

//int vimWindowGetLeftColumn(void);
//
//void vimWindowSetWidth(int width);
public func vimWindowSetWidth(_ width: Int) {
    clibvim.vimWindowSetWidth(CInt(width))
}
//void vimWindowSetHeight(int height);
public func vimWindowSetHeight(_ height: Int) {
    clibvim.vimWindowSetHeight(CInt(height))
}
//void vimWindowSetTopLeft(int top, int left);
public func vimWindowSetTopLeft(_ top: Int, _ left: Int) {
    clibvim.vimWindowSetTopLeft(CInt(top), CInt(left))
}
//
//void vimSetWindowSplitCallback(WindowSplitCallback callback);
//typedef void (*WindowSplitCallback)(windowSplit_T splitType, char_u *fname);
public typealias WindowSplitCallback = (_ splitType: Vim.WindowSplit, _ fname: String) -> Void
var vimWindowSplitCallback: WindowSplitCallback?

public func vimSetWindowSplitCallback(_ callback: WindowSplitCallback?) {
    vimWindowSplitCallback = callback
    let cCallback: clibvim.WindowSplitCallback? = if callback != nil {
        {
            let splitType = Vim.WindowSplit(rawValue: $0)!
            let fname = String(cString: $1!)
            vimWindowSplitCallback!(splitType, fname)
        }
    } else {
        nil
    }
    clibvim.vimSetWindowSplitCallback(cCallback)
}

//void vimSetWindowMovementCallback(WindowMovementCallback callback);
//typedef void (*WindowMovementCallback)(windowMovement_T movementType, int count);
public typealias WindowMovementCallback = (_ movementType: Vim.WindowMovement, _ count: Int) -> Void
var vimWindowMovementCallback: WindowMovementCallback?

public func vimSetWindowMovementCallback(_ callback: WindowMovementCallback?) {
    vimWindowMovementCallback = callback
    let cCallback: clibvim.WindowMovementCallback? = if callback != nil {
        {
            let movementType = Vim.WindowMovement(rawValue: $0)!
            let count = Int($1)
            vimWindowMovementCallback!(movementType, count)
        }
    } else {
        nil
    }
    clibvim.vimSetWindowMovementCallback(cCallback)
}

/***
 * Misc
 ***/

public extension Vim {
    struct State: Swift.OptionSet {
        public typealias RawValue = CInt

        public let rawValue: RawValue
        public init(rawValue: RawValue) {
            self.rawValue = rawValue
        }

        public static let normal         = Self(rawValue: clibvim.NORMAL)
        public static let visual         = Self(rawValue: clibvim.VISUAL)
        public static let opPending      = Self(rawValue: clibvim.OP_PENDING)
        public static let cmdLine        = Self(rawValue: clibvim.CMDLINE)
        public static let insert         = Self(rawValue: clibvim.INSERT)
        public static let langMap        = Self(rawValue: clibvim.LANGMAP)
        public static let replaceFlag    = Self(rawValue: clibvim.REPLACE_FLAG)
        public static let replace: Self  = [ .replaceFlag, .insert ]
        public static let vReplaceFlag   = Self(rawValue: clibvim.VREPLACE_FLAG)
        public static let vReplace: Self = [ .replaceFlag, .vReplaceFlag, .insert ]
        public static let lReplace: Self = [ .replaceFlag, .langMap ]
        public static let normalBusy     = Self(rawValue: clibvim.NORMAL_BUSY)
        public static let hitReturn      = Self(rawValue: clibvim.HITRETURN)
        public static let askMore        = Self(rawValue: clibvim.ASKMORE)
        public static let setWSize       = Self(rawValue: clibvim.SETWSIZE)
        public static let abbrev         = Self(rawValue: clibvim.ABBREV)
        public static let externCmd      = Self(rawValue: clibvim.EXTERNCMD)
        public static let showMatch      = Self(rawValue: clibvim.SHOWMATCH)
        public static let confirm        = Self(rawValue: clibvim.CONFIRM)
        public static let selectMode     = Self(rawValue: clibvim.SELECTMODE)
        public static let terminal       = Self(rawValue: clibvim.TERMINAL)
    }

    // Motion types, used for operators and for yank/delete registers.
    enum MotionType: RawRepresentable {
        public typealias RawValue = CInt

        case charWise,  // character-wise movement/register
             lineWise,  // line-wise movement/register
             blockWise, // block-wise register
             auto       // Decide between MLINE/MCHAR

        public init?(rawValue: RawValue) {
            let value: Self? = switch rawValue {
            case clibvim.MCHAR: .charWise
            case clibvim.MLINE: .lineWise
            case clibvim.MBLOCK: .blockWise
            case clibvim.MAUTO: .auto
            default: nil
            }

            guard let value else { return nil }
            self = value
        }

        public var rawValue: RawValue {
            switch self {
            case .charWise: clibvim.MCHAR
            case .lineWise: clibvim.MLINE
            case .blockWise: clibvim.MBLOCK
            case .auto: clibvim.MAUTO
            }
        }
    }
}

//void vimSetClipboardGetCallback(ClipboardGetCallback callback);
//typedef int (*ClipboardGetCallback)(int regname, int *num_lines, char_u ***lines, int *blockType /* MLINE, MCHAR, MBLOCK */);
public typealias ClipboardGetCallback = (_ regName: Character) -> (lines: [String], blockType: Vim.MotionType)?

var vimClipboardGetCallback: ClipboardGetCallback?


public func vimSetClipboardGetCallback(_ callback: ClipboardGetCallback?) {
    vimClipboardGetCallback = callback
    let cCallback: clibvim.ClipboardGetCallback? = if callback != nil {
        { regName, numLines, cLines, cBlockType in
            guard let result = vimClipboardGetCallback!(Character(regName)) else {
                return CFalse
            }

            numLines!.pointee = CInt(result.lines.count)
            cLines!.pointee = result.lines.cPointerPointer
            cBlockType!.pointee = result.blockType.rawValue

            return CTrue
        }
    } else {
        nil
    }
    clibvim.vimSetClipboardGetCallback(cCallback)
}
//
//int vimGetMode(void);

public func vimGetMode() -> Vim.State {
    Vim.State(rawValue: clibvim.vimGetMode())
}

/* There are some modal input experiences that aren't considered
 full-fledged modes, but are nevertheless a modal input state.
 Examples include insert-literal (C-V, C-G), search w/ confirmation, etc.
 */
//subMode_T vimGetSubMode(void);
public extension Vim {
    enum SubMode: RawRepresentable {
        public typealias RawValue = subMode_T
        case none
        case insertLiteral

        public init?(rawValue: RawValue) {
            let value: Self? = switch rawValue {
            case SM_NONE: Vim.SubMode.none
            case SM_INSERT_LITERAL: .insertLiteral
            default: nil
            }

            guard let value else { return nil }
            self = value
        }

        public var rawValue: RawValue {
            switch self {
            case .none: SM_NONE
            case .insertLiteral: SM_INSERT_LITERAL
            }
        }
    }

    struct PendingOperator: RawRepresentable {
        public typealias RawValue = pendingOp_T
        let opType: Operator
        let regName: Character
        let count: Int

        public init?(rawValue: RawValue) {
            guard let opType = Operator(rawValue: rawValue.op_type) else { return nil }
            self.opType = opType
            self.regName = Character(rawValue.regname)
            self.count = Int(rawValue.count)
        }
        
        public var rawValue: RawValue {
            RawValue(
                op_type: opType.rawValue,
                regname: CInt(regName.asciiValue!),
                count: CLong(count)
            )
        }
    }

    enum Operator: RawRepresentable {
        public typealias RawValue = CInt
        case nop            /* no pending operation */
        case delete         /* "d"  delete operator */
        case yank           /* "y"  yank operator */
        case change         /* "c"  change operator */
        case lshift         /* "<"  left shift operator */
        case rshift         /* ">"  right shift operator */
        case filter         /* "!"  filter operator */
        case tilde          /* "g~" switch case operator */
        case indent         /* "="  indent operator */
        case format         /* "gq" format operator */
        case colon         /* ":"  colon operator */
        case upper         /* "gU" make upper case operator */
        case lower         /* "gu" make lower case operator */
        case join          /* "J"  join operator, only for Visual mode */
        case joinNs       /* "gJ"  join operator, only for Visual mode */
        case rot13         /* "g?" rot-13 encoding */
        case replace       /* "r"  replace chars, only for Visual mode */
        case insert        /* "I"  Insert column, only for Visual mode */
        case append        /* "A"  Append column, only for Visual mode */
        case fold          /* "zf" define a fold */
        case foldopen      /* "zo" open folds */
        case foldopenrec   /* "zO" open folds recursively */
        case foldclose     /* "zc" close folds */
        case foldcloserec  /* "zC" close folds recursively */
        case folddel       /* "zd" delete folds */
        case folddelrec    /* "zD" delete folds recursively */
        case format2       /* "gw" format operator, keeps cursor pos */
        case function      /* "g@" call 'operatorfunc' */
        case nrAdd        /* "<C-A>" Add to the number or alphabetic \ \ \
                                    character (OP_ADD conflicts with Perl) */
        case nrSub       /* "<C-X>" Subtract from the number or \ \ \
                                    alphabetic character */
        case comment      /* "gc" and "gcc" toggles commented lines */

        public init?(rawValue: CInt) {
            let value: Self? = switch rawValue {
            case OP_NOP: .nop
            case OP_DELETE: .delete
            case OP_YANK: .yank
            case OP_CHANGE: .change
            case OP_LSHIFT: .lshift
            case OP_RSHIFT: .rshift
            case OP_FILTER: .filter
            case OP_TILDE: .tilde
            case OP_INDENT: .indent
            case OP_FORMAT: .format
            case OP_COLON: .colon
            case OP_UPPER: .upper
            case OP_LOWER: .lower
            case OP_JOIN: .join
            case OP_JOIN_NS: .joinNs
            case OP_ROT13: .rot13
            case OP_REPLACE: .replace
            case OP_INSERT: .insert
            case OP_APPEND: .append
            case OP_FOLD: .fold
            case OP_FOLDOPEN: .foldopen
            case OP_FOLDOPENREC: .foldopenrec
            case OP_FOLDCLOSE: .foldclose
            case OP_FOLDCLOSEREC: .foldcloserec
            case OP_FOLDDEL: .folddel
            case OP_FOLDDELREC: .folddelrec
            case OP_FORMAT2: .format2
            case OP_FUNCTION: .function
            case OP_NR_ADD: .nrAdd
            case OP_NR_SUB: .nrSub
            case OP_COMMENT: .comment
            default: nil
            }

            guard let value else { return nil }
            self = value
        }
        
        public var rawValue: CInt {
            switch self {
            case .nop: OP_NOP
            case .delete: OP_DELETE
            case .yank: OP_YANK
            case .change: OP_CHANGE
            case .lshift: OP_LSHIFT
            case .rshift: OP_RSHIFT
            case .filter: OP_FILTER
            case .tilde: OP_TILDE
            case .indent: OP_INDENT
            case .format: OP_FORMAT
            case .colon: OP_COLON
            case .upper: OP_UPPER
            case .lower: OP_LOWER
            case .join: OP_JOIN
            case .joinNs: OP_JOIN_NS
            case .rot13: OP_ROT13
            case .replace: OP_REPLACE
            case .insert: OP_INSERT
            case .append: OP_APPEND
            case .fold: OP_FOLD
            case .foldopen: OP_FOLDOPEN
            case .foldopenrec: OP_FOLDOPENREC
            case .foldclose: OP_FOLDCLOSE
            case .foldcloserec: OP_FOLDCLOSEREC
            case .folddel: OP_FOLDDEL
            case .folddelrec: OP_FOLDDELREC
            case .format2: OP_FORMAT2
            case .function: OP_FUNCTION
            case .nrAdd: OP_NR_ADD
            case .nrSub: OP_NR_SUB
            case .comment: OP_COMMENT
            }
        }
    }
}

public func vimGetSubMode() -> Vim.SubMode {
    (clibvim.vimGetSubMode() |> Vim.SubMode.init)!
}
//
//int vimGetPendingOperator(pendingOp_T *pendingOp);
public func vimGetPendingOperator() -> Vim.PendingOperator? {
    var cPendingOp = Vim.PendingOperator.RawValue()
    guard Bool(clibvim.vimGetPendingOperator(&cPendingOp)) else {
        return nil
    }
    return Vim.PendingOperator(rawValue: cPendingOp)
}
//
//void vimSetYankCallback(YankCallback callback);

public typealias YankCallback = (_ yankInfo: Vim.YankInfo) -> Void
var vimYankCallback: YankCallback?

public extension Vim {
    struct YankInfo: RawRepresentable {
        public typealias RawValue = yankInfo_T

        var opChar: Character
        var extraOpChar: Character
        var regName: Character
        var blockType: Int
        var start: Position
        var end: Position
        var numLines: Int
        var lines: [String]

        public init?(rawValue: RawValue) {
            self.opChar = Character(rawValue.op_char)
            self.extraOpChar = Character(rawValue.extra_op_char)
            self.regName = Character(rawValue.regname)
            self.blockType = Int(rawValue.blockType)
            self.start = rawValue.start
            self.end = rawValue.end
            self.numLines = Int(rawValue.numLines)
            self.lines = [String](rawValue.lines, count: rawValue.numLines)
        }

        public var rawValue: RawValue {
            RawValue(
                op_char: CInt(char: opChar),
                extra_op_char: CInt(char: extraOpChar),
                regname: CInt(char: regName),
                blockType: CInt(blockType),
                start: start,
                end: end,
                numLines: CInt(numLines),
                lines: lines.cPointerPointer
            )
        }

        public init(_ cYankInfoPointer: UnsafeMutablePointer<RawValue>) {
            self.init(rawValue: cYankInfoPointer.pointee)!
        }
    }
}

public func vimSetYankCallback(_ callback: @escaping YankCallback) {
    vimYankCallback = callback
    let cCallback: clibvim.YankCallback? = { yankInfoPointer in
        let yankInfo = Vim.YankInfo(yankInfoPointer!)
        vimYankCallback?(yankInfo)
    }
    clibvim.vimSetYankCallback(cCallback)
}

public extension Vim {
    struct Expand {
        enum Mode: RawRepresentable {
            public typealias RawValue = CInt

            case free,
                 expandFree,
                 expandKeep,
                 next,
                 prev,
                 all,
                 longest,
                 allKeep

            init?(rawValue: RawValue) {
                let value: Self? = switch rawValue {
                case WILD_FREE: .free
                case WILD_EXPAND_FREE: .expandFree
                case WILD_EXPAND_KEEP: .expandKeep
                case WILD_NEXT: .next
                case WILD_PREV: .prev
                case WILD_ALL: .all
                case WILD_LONGEST: .longest
                case WILD_ALL_KEEP: .allKeep
                default: nil
                }

                guard let value else { return nil }
                self = value
            }
            
            var rawValue: CInt {
                switch self {
                case .free: WILD_FREE
                case .expandFree: WILD_EXPAND_FREE
                case .expandKeep: WILD_EXPAND_KEEP
                case .next: WILD_NEXT
                case .prev: WILD_PREV
                case .all: WILD_ALL
                case .longest: WILD_LONGEST
                case .allKeep: WILD_ALL_KEEP
                }
            }
        }

        struct Option: Swift.OptionSet {
            public typealias RawValue = CInt
            let rawValue: RawValue
            static let listNotFound = Option(rawValue: WILD_LIST_NOTFOUND)
            static let homeReplace = Option(rawValue: WILD_HOME_REPLACE)
            static let useNL = Option(rawValue: WILD_USE_NL)
            static let noBeep = Option(rawValue: WILD_NO_BEEP)
            static let addSlash = Option(rawValue: WILD_ADD_SLASH)
            static let keepAll = Option(rawValue: WILD_KEEP_ALL)
            static let silent = Option(rawValue: WILD_SILENT)
            static let escape = Option(rawValue: WILD_ESCAPE)
            static let iCase = Option(rawValue: WILD_ICASE)
            static let allLinks = Option(rawValue: WILD_ALLLINKS)
        }

        enum Context: RawRepresentable {
            public typealias RawValue = CInt

            case unsuccessful
            case ok
            case nothing
            case commands
            case files
            case directories
            case settings
            case boolSettings
            case tags
            case oldSetting
            case help
            case buffers
            case events
            case menus
            case syntax
            case highlight
            case augroup
            case userVars
            case mappings
            case tagsListfiles
            case functions
            case userFunc
            case expression
            case menuNames
            case userCommands
            case userCmdFlags
            case userNargs
            case userComplete
            case envVars
            case language
            case colors
            case compiler
            case userDefined
            case userList
            case shellCmd
            case cScope
            case sign
            case profile
            case behave
            case fileType
            case filesInPath
            case ownSyntax
            case locales
            case history
            case user
            case synTime
            case userAddrType
            case packAdd
            case messages
            case mapClear
            case argList

            public init?(rawValue: CInt) {
                let context: Self? = switch rawValue {
                case EXPAND_UNSUCCESSFUL: .unsuccessful
                case EXPAND_OK: .ok
                case EXPAND_NOTHING: .nothing
                case EXPAND_COMMANDS: .commands
                case EXPAND_FILES: .files
                case EXPAND_DIRECTORIES: .directories
                case EXPAND_SETTINGS: .settings
                case EXPAND_BOOL_SETTINGS: .boolSettings
                case EXPAND_TAGS: .tags
                case EXPAND_OLD_SETTING: .oldSetting
                case EXPAND_HELP: .help
                case EXPAND_BUFFERS: .buffers
                case EXPAND_EVENTS: .events
                case EXPAND_MENUS: .menus
                case EXPAND_SYNTAX: .syntax
                case EXPAND_HIGHLIGHT: .highlight
                case EXPAND_AUGROUP: .augroup
                case EXPAND_USER_VARS: .userVars
                case EXPAND_MAPPINGS: .mappings
                case EXPAND_TAGS_LISTFILES: .tagsListfiles
                case EXPAND_FUNCTIONS: .functions
                case EXPAND_USER_FUNC: .userFunc
                case EXPAND_EXPRESSION: .expression
                case EXPAND_MENUNAMES: .menuNames
                case EXPAND_USER_COMMANDS: .userCommands
                case EXPAND_USER_CMD_FLAGS: .userCmdFlags
                case EXPAND_USER_NARGS: .userNargs
                case EXPAND_USER_COMPLETE: .userComplete
                case EXPAND_ENV_VARS: .envVars
                case EXPAND_LANGUAGE: .language
                case EXPAND_COLORS: .colors
                case EXPAND_COMPILER: .compiler
                case EXPAND_USER_DEFINED: .userDefined
                case EXPAND_USER_LIST: .userList
                case EXPAND_SHELLCMD: .shellCmd
                case EXPAND_CSCOPE: .cScope
                case EXPAND_SIGN: .sign
                case EXPAND_PROFILE: .profile
                case EXPAND_BEHAVE: .behave
                case EXPAND_FILETYPE: .fileType
                case EXPAND_FILES_IN_PATH: .filesInPath
                case EXPAND_OWNSYNTAX: .ownSyntax
                case EXPAND_LOCALES: .locales
                case EXPAND_HISTORY: .history
                case EXPAND_USER: .user
                case EXPAND_SYNTIME: .synTime
                case EXPAND_USER_ADDR_TYPE: .userAddrType
                case EXPAND_PACKADD: .packAdd
                case EXPAND_MESSAGES: .messages
                case EXPAND_MAPCLEAR: .mapClear
                case EXPAND_ARGLIST: .argList
                default: nil
                }
                if let context {
                    self = context
                } else {
                    return nil
                }
            }

            public var rawValue: CInt {
                switch self {
                case .unsuccessful: EXPAND_UNSUCCESSFUL
                case .ok: EXPAND_OK
                case .nothing: EXPAND_NOTHING
                case .commands: EXPAND_COMMANDS
                case .files: EXPAND_FILES
                case .directories: EXPAND_DIRECTORIES
                case .settings: EXPAND_SETTINGS
                case .boolSettings: EXPAND_BOOL_SETTINGS
                case .tags: EXPAND_TAGS
                case .oldSetting: EXPAND_OLD_SETTING
                case .help: EXPAND_HELP
                case .buffers: EXPAND_BUFFERS
                case .events: EXPAND_EVENTS
                case .menus: EXPAND_MENUS
                case .syntax: EXPAND_SYNTAX
                case .highlight: EXPAND_HIGHLIGHT
                case .augroup: EXPAND_AUGROUP
                case .userVars: EXPAND_USER_VARS
                case .mappings: EXPAND_MAPPINGS
                case .tagsListfiles: EXPAND_TAGS_LISTFILES
                case .functions: EXPAND_FUNCTIONS
                case .userFunc: EXPAND_USER_FUNC
                case .expression: EXPAND_EXPRESSION
                case .menuNames: EXPAND_MENUNAMES
                case .userCommands: EXPAND_USER_COMMANDS
                case .userCmdFlags: EXPAND_USER_CMD_FLAGS
                case .userNargs: EXPAND_USER_NARGS
                case .userComplete: EXPAND_USER_COMPLETE
                case .envVars: EXPAND_ENV_VARS
                case .language: EXPAND_LANGUAGE
                case .colors: EXPAND_COLORS
                case .compiler: EXPAND_COMPILER
                case .userDefined: EXPAND_USER_DEFINED
                case .userList: EXPAND_USER_LIST
                case .shellCmd: EXPAND_SHELLCMD
                case .cScope: EXPAND_CSCOPE
                case .sign: EXPAND_SIGN
                case .profile: EXPAND_PROFILE
                case .behave: EXPAND_BEHAVE
                case .fileType: EXPAND_FILETYPE
                case .filesInPath: EXPAND_FILES_IN_PATH
                case .ownSyntax: EXPAND_OWNSYNTAX
                case .locales: EXPAND_LOCALES
                case .history: EXPAND_HISTORY
                case .user: EXPAND_USER
                case .synTime: EXPAND_SYNTIME
                case .userAddrType: EXPAND_USER_ADDR_TYPE
                case .packAdd: EXPAND_PACKADD
                case .messages: EXPAND_MESSAGES
                case .mapClear: EXPAND_MAPCLEAR
                case .argList: EXPAND_ARGLIST
                }
            }

        }


        public typealias CExpand = expand_T
        private var cExpand = CExpand()

        var files: [String] {
            get {
                [String](cExpand.xp_files, count: cExpand.xp_numfiles)
            }
        }

        public init() {
            ExpandInit(&cExpand)
        }

        @discardableResult
        mutating func expandOne(_ pattern: String,
                                _ original: String?, /* allocated copy of original of expanded string */
                                _ options: Option,
                                _ mode: Mode) -> String? {

            cExpand.xp_pattern = pattern.uCString
            cExpand.xp_pattern_len = CInt(pattern.utf8.count)
            cExpand.xp_context = Context.colors.rawValue

            let pattern = addstar(cExpand.xp_pattern, cExpand.xp_pattern_len, cExpand.xp_context);

            return ExpandOne(&cExpand,
                             pattern,
                             original?.uCString,
                             options.rawValue,
                             mode.rawValue)
            |> String?.init
        }
    }
}
/* Callbacks for when the `:intro` and `:version` commands are used

 The Vim license has some specific requirements when implementing these methods:

 3) A message must be added, at least in the output of the ":version"
 command and in the intro screen, such that the user of the modified Vim
 is able to see that it was modified.  When distributing as mentioned
 under 2)e) adding the message is only required for as far as this does
 not conflict with the license used for the changes.
 */
//void vimSetDisplayIntroCallback(VoidCallback callback);
var vimDisplayIntroCallback: VoidCallback?

public func vimSetDisplayIntroCallback(_ callback: VoidCallback?) {
    vimDisplayIntroCallback = callback
    let cCallback: clibvim.VoidCallback? = if callback != nil {
        {
            vimDisplayIntroCallback!()
        }
    } else {
        nil
    }
    clibvim.vimSetDisplayIntroCallback(cCallback)
}

//void vimSetDisplayVersionCallback(VoidCallback callback);
var vimDisplayVersionCallback: VoidCallback?

public func vimSetDisplayVersionCallback(_ callback: VoidCallback?) {
    vimDisplayVersionCallback = callback
    let cCallback: clibvim.VoidCallback? = if callback != nil {
        {
            vimDisplayVersionCallback!()
        }
    } else {
        nil
    }
    clibvim.vimSetDisplayVersionCallback(cCallback)
}

/* vim: set ft=c : */
