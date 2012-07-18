on run argv
	set volName to item 1 of argv
	
	process_disk_image(volName)
end run

on process_disk_image(volumeName)
	tell application "Finder"
		tell disk (volumeName as string)
			open
			
			set iconSize to 128
			set dsStore to "\"" & "/Volumes/" & volumeName & "/" & ".DS_STORE\""
			
			tell container window
				bounds
				set current view to icon view
				set toolbar visible to false
				set statusbar visible to false
				set the bounds to {300, 300, 922, 595}
				name
			end tell
			
			set opts to the icon view options of container window
			tell opts
				set icon size to iconSize
				set arrangement to not arranged
			end tell
			set background picture of opts to file ".background:background.png"
			position of item "Applications" of container window
			position of item "KBase.app" of container window
			set position of item "Applications" to {450, 102}
			set position of item "KBase.app" to {168, 102}
			
			close
			open
			
			update without registering applications
			delay 1
			tell container window
				set statusbar visible to false
				set the bounds to {300, 300, 912, 585}
			end tell
			update without registering applications
			
		end tell
		
		delay 1
		tell disk (volumeName as string)
			tell container window
				set statusbar visible to false
				set the bounds to {300, 300, 922, 595}
			end tell
			update without registering applications
		end tell
		delay 3
		set waitTime to 0
		set ejectMe to false
		repeat while ejectMe is false
			delay 1
			set waitTime to waitTime + 1
			if (do shell script "[ -f " & dsStore & " ]; echo $?") = "0" then set ejectMe to true
		end repeat
		log "waited " & waitTime & " seconds for .DS_STORE to be created."
	end tell
	
end process_disk_image