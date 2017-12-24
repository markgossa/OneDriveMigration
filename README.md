# OneDriveMigration
Module containing functions to rename unsupported files and folders and copy them to the OneDrive folder.

Files and folders are renamed to *RenamedItem* followed by a random number to avoid conflicts. 

Follows guidance from here: [https://support.microsoft.com/en-gb/help/3125202/restrictions-and-limitations-when-you-sync-files-and-folders](https://support.microsoft.com/en-gb/help/3125202/restrictions-and-limitations-when-you-sync-files-and-folders)

# Examples
```powershell
Copy-OneDriveFolder -Source "H:\IT" -Destination "C:\Users\joebloggs\OneDrive - Joe Bloggs\IT" -LogPath C:\OneDriveLogs
```