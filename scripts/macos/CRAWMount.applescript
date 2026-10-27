-- SPDX-License-Identifier: Apache-2.0
-- Droplet: drop .craw takes (or open them with "CRAW Mount") to mount them as
-- CinemaDNG folders under ~/CRAW and reveal them in Finder for DaVinci Resolve.
on open theItems
	set args to ""
	repeat with f in theItems
		set args to args & " " & quoted form of POSIX path of f
	end repeat
	try
		set out to do shell script "export PATH=\"$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH\"; craw-mount --open" & args
		display notification out with title "CRAW Mount"
	on error errMsg
		display alert "CRAW Mount failed" message errMsg as critical
	end try
end open

on run
	set picked to choose file with prompt "Choose .craw takes to mount for DaVinci Resolve" of type {"craw", "CRAW", "public.data"} with multiple selections allowed
	open picked
end run
