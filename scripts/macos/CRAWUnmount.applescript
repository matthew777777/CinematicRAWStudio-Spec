-- SPDX-License-Identifier: Apache-2.0
-- Unmounts every take mounted by CRAW Mount (~/CRAW).
on run
	try
        set launcher to (system attribute "HOME") & "/.local/bin/craw"
        try
            set launcher to do shell script "cat \"$HOME/.local/share/craw/command\""
        end try
        set out to do shell script (quoted form of launcher) & " unmount"
		display notification out with title "CRAW Unmount"
	on error errMsg
		display alert "CRAW Unmount" message errMsg
	end try
end run
