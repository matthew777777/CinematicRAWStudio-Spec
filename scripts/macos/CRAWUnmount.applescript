-- SPDX-License-Identifier: Apache-2.0
-- Unmounts every take mounted by CRAW Mount (~/CRAW).
on run
	try
		set out to do shell script "export PATH=\"$HOME/.local/bin:$PATH\"; craw-unmount --all"
		display notification out with title "CRAW Unmount"
	on error errMsg
		display alert "CRAW Unmount" message errMsg
	end try
end run
