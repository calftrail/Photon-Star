#! /usr/bin/osascript

on run argv
	set thePhotoID to first item of argv as number
	set theRating to second item of argv as number
	tell application "iPhoto"
		get photo id (2 ^ 32 + thePhotoID)
		set rating of result to theRating
	end tell
end run
