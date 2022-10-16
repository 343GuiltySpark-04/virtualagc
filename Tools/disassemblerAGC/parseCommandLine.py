#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Copyright:      None - the author (Ron Burkey) declares this software to
                be in the Public Domain, with no rights reserved.
Filename:       parseCommandLine.py
Purpose:        Parses command line for disassemblerAGC.py
History:        2022-09-28 RSB  Split off from disassemblerAGC.py.
                2022-10-07 RSB  Added --skip and --check.
                2022-10-08 RSB  Added --overlap, --hint, --ignore
                2022-10-09 RSB  Added --avoid
                2022-10-10 RSB  Added --parity.
                2022-10-13 RSB  Added --block1 and --blk2.
                2022-10-14 RSB  Removed --descent, --basic, and --interp.
                                Completely restructured and partially
                                cleaned up the --help option for (hopefully)
                                much-more-effective usage.
"""

import sys

#=============================================================================
# Parse command line.

# Turn a command-line string like NNNN or NN,NNNN into a fixed-memory address.
def toFixed(string):
    try:
        fields = string.split(",")
        if len(fields) == 1:
            value = int(fields[0], 8)
            if value < 0o4000 or value > 0o7777:
                print("Address out of range:", string)
                sys.exit(1)
            return value // 0o2000, value % 0o2000
        if len(fields) == 2:
            bank = int(fields[0], 8)
            offset = int(fields[1], 8)
            if bank < 0 or bank > 0o43 or offset < 0o2000 or offset > 0o3777:
                print("Address out of range:", string)
                sys.exit(1)
            return bank, offset % 0o2000
        else:
            print("Mangled address:", string)
            sys.exit(1)
    except:
        print("Mangled address:", string)
        sys.exit(1)

binFile = False
hardwareFile = False
debug = False
dump = False
dtest = False
dbasic = True
dbank = -1
dstart = -1
dend = -1
specialOnly = False
pattern = False
symbol = "SYMBOL"
specsFilename = ""
findFilename = ""
flexFilename = ""
checkFilename = ""
skips = {}
disjoint = True
hintAfter = {}
ignore = []
avoid = []
parity = False
block1 = False
blk2 = False

entryCount = 0
pBanks = ""
oBanks = ""
for param in sys.argv[1:]:
    if param == "--help":
        print('''
            This program can be used as an AGC disassembler or viewer for
            .bin files.  Primarily, however, it is part of the workflow
            for reconstructing AGC source code for an AGC program given
            as just a dump of physical rope-memory modules.  Specifically,
            it tries to deduce a list of memory addresses of program labels
            and variables names.  Companion programs are pieceworkAGC.py
            and specifyAGC.py.
        
            Usage:    
                 disassemblerAGC.py [OPTIONS] <ROPE >DISASSEMBLY    
                 
            Options related to the input file:
                Default:    The input ROPE is a .binsource file.
                --bin       ROPE is instead a .bin file as output by yaYUL.    
                --hardware  ROPE is a 'hardware' style .bin file, presumably
                            created by dumping physical rope-memory modules.
                --parity    By default, the parity bit is ignored in input 
                            --bin files and --hardware files.  The --parity 
                            switch enables it.  Note that without parity, we 
                            cannot necessarily distinguish between memory 
                            locations that are unused vs those that are merely 
                            00000; but not all .bin files contain parity bits,
                            and this may not be a problem anyway.  Processing
                            of binsource files is unaffected by --parity.

            Options related to AGC architecture:
                Default:    LGC or Block II, normal variant.
                --blk2      LGC or Block II, BLK2 variant.
                --block1    Block I.
            
            Miscellaneous options:          
                --help      Display the descriptive information you're now
                            reading.       
                --debug     Turn on some debugging messages. 
                --dump      Output an octal dump of the ROPE. Don't forget
                            to add any appropriate AGC-architecture options
                            (see above), since those affect the selection of
                            banks and the order in which they're output.   
                  
            Options related to --dtest:
                --dtest     This outputs a disassembly of a range of
                            addresses confined to a single fixed-memory bank.
                            For Block II the default address range corresponds
                            to the interrupt vector table:  i.e., 02,2000
                            to 02,2050 for Block II, and 01,6000 to 01,6034
                            for Block I.  But these assumptions can be changed
                            with the options listed below.
                --dint      The disassembly range can be mixed basic 
                            instructions and interpreter instructions, but 
                            by default the very first instruction in the
                            range is basic. The --dint switch instead specifies
                            that the first instruction is interpretive.
                --dbank=N   Bank number is N (octal).
                --dstart=N  Starting offset is N (octal).
                --dend==N   Disassembly stops when reaching this address 
                            (octal) without disassembling it.    
                            
            Automation:  Creation of match-patterns:                                   
                --specs=F   Reads a baseline file (F) of pattern 
                            specifications, typically created by the separate
                            program specifyAGC.py. Outputs patterns in a form
                            useful for the disassemblerAGC.py's --find option,
                            for subsequent patterns matching within a 
                            different (or the same) ROPE. 
                            
            Automation:  Analysis of a ROPE using BASELINE match-patterns:
                --find=F    Uses a baseline match-pattern file as created by
                            --specs (see above), and tries to find all of the
                            patterns specified therein.
                --hint=S1@S2 This is a hint that subroutine S1 must be at a 
                            higher memory address than subroutine S2.  As many
                            --hint switches can be used as desired.  A typical
                            usage would be to work around two (or more) 
                            match-patterns being either identical, or being 
                            contained within one another.  Used in similar 
                            circumstances as --skip (see below), for similar
                            reasons, but generally the superior choice for
                            problematic tables of TC instructions.
                --skip=S    In using the --find option, it just so happens 
                            that there may be several matches for some symbol S
                            defined in the match-patterns file.  One option for
                            dealing with that situation is to instruct the 
                            disassembler to skip the first match it finds for
                            that symbol.  Using this switch twice tells the 
                            disassembler to skip the first 2 matches of the 
                            symbol.  And so on.  Used in similar circumstances
                            as --hint (see above), for similar reasons, but 
                            sometimes the superior choice for small 
                            match-patterns.
                --ignore=S  Simply ignore subroutine S altogether when matching
                            patterns.  This is a last-resort measure when
                            --hint and --skip (see above) are inadequate for
                            dealing with a problematic subroutine S.
                --avoid=BB,NNNN-MMMM Specify a fixed address range which 
                            should be avoided by the matching process.  You
                            can use as many of these switches as necessary.
                            This is a last-resort measure when a long section
                            of data happens to disassemble compatibly to 
                            code.  An example (the only one known, actually)
                            is a table of CADR pseudo-ops that disassembles
                            as a table of TC instructions.
                --check=F   Specifies an assembly-listing file that can be 
                            used for comparison vs the matches found. If 
                            this switch is not present, no comparison is 
                            performed.
                --overlap   (Rare.) By default, overlapping of the program 
                            chunks defined in the match-patterns file (and the 
                            specifications file from which it was derived)
                            is rigidly avoided by the pattern-matching.  But
                            if they can overlap by intention (which can happen
                            only if the match-patterns or the specifications
                            they're derived from have been created manually
                            rather than by automation), use this switch.
                --prio=B,... (Rare.) A list of banks (octal) which are searched 
                            first with the --find switch.  Without --prio, the 
                            banks are searched in the order 00, 01, 02, ..., 
                            43.
                --only=B,... (Rare.) A list of banks (octal) for --find.  If
                            present, only the listed banks are searched.
                        
            Options related to "special subroutines":                            
                --special   Just print the "special subroutines" found, 
                            without any additional processing.  
                --flex=F    Add user-created "special subroutines" to the
                            list of special subroutines already hardcoded,
                            which include INTPRET etc.  F is a file containing
                            such patterns.  Patterns can be created either
                            manually, or with the --pattern option (see
                            below).  
                --pattern=S Outputs a sample pattern (which typically 
                            requiring manual tweaking) for program label S, 
                            suitable for pasting into searchSpecial.py or for
                            use with the --flex option (see above). Only 
                            patterns consisting entirely of basic
                            instructions (rather than interpretive) are 
                            currently supported.
                --dbank=N   (For --pattern.) Bank number is N (octal).
                --dstart=N  (For --pattern.) Starting offset is N (octal.
                --dend==N   (For --pattern.) First address not assembled.    
        ''')
        sys.exit(0)
    elif param == "--bin":
        binFile = True
    elif param == "--hardware":
        hardwareFile = True
    elif param == "--block1":
        block1 = True
    elif param == "--blk2":
        blk2 = True
    elif param == "--debug":
        debug = True
    elif param == "--dump":
        dump = True
    elif param[:10] == "--pattern=":
        pattern = True
        symbol = param[10:]
    elif param == "--dtest":
        dtest = True
    elif param[:8] == "--dbank=":
        dbank = int(param[8:], 8)
    elif param[:9] == "--dstart=":
        dstart = int(param[9:], 8)
    elif param[:7] == "--dend=":
        dend = int(param[7:], 8)
    elif param == "--dint":
        dbasic = False
    elif param in ["--special", "--specials"]:
        specialOnly = True
    elif param[:8] == "--specs=":
        specsFilename = param[8:]
    elif param[:8] == "--check=":
        checkFilename = param[8:]
    elif param[:7] == "--find=":
        findFilename = param[7:]
    elif param[:7] == "--flex=":
        flexFilename = param[7:]
    elif param[:7] == "--prio=":
        pBanks = param[7:]
    elif param[:7] == "--skip=":
        skip = param[7:]
        if skip not in skips:
            skips[skip] = 1
        else:
            skips[skip] += 1
    elif param[:7] == "--only=":
        oBanks = param[7:]
    elif param[:7] == "--hint=":
        fields = param[7:].split("@")
        if fields[0] in hintAfter:
            hintAfter[fields[0]].append(fields[1])
        else:
            hintAfter[fields[0]] = [fields[1]]
    elif param == "--overlap":
        disjoint = False
    elif param[:9] == "--ignore=":
        ignore.append(param[9:])
    elif param[:8] == "--avoid=":
        fields = param[8:].split("-")
        leftFields = fields[0].split(",")
        avoid.append((int(leftFields[0], 8), int(leftFields[1], 8), 
                        int(fields[1], 8)))
    elif param == "--parity":
        parity = True
    else:
        print("Unrecognized option", param)
        sys.exit(1)
if hardwareFile:
    binFile = False
if block1:
    if dbank == -1:
        dbank = 0o01
    if dstart == -1:
        dstart = 0o6000
    if dend == -1:
        dend = 0o6034
else: # Block II
    if dbank == -1:
        dbank = 0o02
    if dstart == -1:
        dstart = 0o2000
    if dend == -1:
        dend = 0o2050

