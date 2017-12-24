function Copy-OneDriveFolder
{
    <#

    .SYNOPSIS

    Copies files and folders from one folder to another but renames the files and folders which have invalid names for OneDrive.

    .DESCRIPTION

    Copies files and folders and renames invalid file or folder names which include: Icon, .lock, PRN, CON, PRN, AUX, NUL, COM1, COM2, COM3, COM4, COM5, COM6, COM7, COM8, COM9, LPT1, LPT2, LPT3, LPT4, LPT5, LPT6, LPT7, LPT8, LPT9, _vti_,  _t, _w

    .PARAMETER Source

    The source folder which will be copied to the destination

    .PARAMETER Destination

    The destination folder

    .PARAMETER LogFolderPath

    Folder path where logs will be saved. This includes copy logs and rename logs. Rename logs will be in CSV format so can be searched at a later date if needed.
    
    .EXAMPLE

    Copy-OneDriveFolder -Source "H:\IT" -Destination "C:\Users\joebloggs\OneDrive - Joe Bloggs\IT" -LogPath C:\OneDriveLogs
    
    #>

    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Source,
        [Parameter(Mandatory = $true)]
        [String]
        $Destination,
        [Parameter(Mandatory = $true)]
        [String]
        $LogFolderPath       
    )

    $InvalidNames = "Icon,.lock,PRN,CON,PRN,AUX,NUL,COM1,COM2,COM3,COM4,COM5,COM6,COM7,COM8,COM9," 
    $InvalidNames += "_t,_w,LPT1,LPT2,LPT3,LPT4,LPT5,LPT6,LPT7,LPT8,LPT9,_vti_"
    $InvalidNames = $InvalidNames -split ","

    function Add-LogEntry
    {
        param (
            [Parameter(Mandatory = $true)]
            [String]
            $LogFolderPath,
            [Parameter(Mandatory = $true)]
            [String]
            $OldPath,
            [Parameter(Mandatory = $true)]
            [String]
            $NewPath
        )

        if (!(Get-Item -Path $LogFolderPath -ErrorAction SilentlyContinue))
        {
            New-Item -Path $LogFolderPath -ItemType File
            Add-Content -Path $LogFolderPath -Value "TimeStamp,OldPath,NewPath"
        }

        Add-Content -Path $LogFolderPath -Value "$(Get-Date -Format "dd/MM/yyyy HH:mm:ss"),$($OldPath),$($NewPath)"
    }

    function CopyTo-OneDrive
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Source,
        [Parameter(Mandatory = $true)]
        [string]
        $Destination,
        [Parameter(Mandatory = $true)]
        [string]
        $LogFolderPath
    )
    $LogFolderPath = "$(Join-Path $LogFolderPath (Split-Path $Source -Leaf)).log"
    robocopy $Source $Destination /E /W:2 /R:10 /log+:$LogFolderPath /tee /XO /V
}

    function Get-InvalidItems
    {
        param (
            [Parameter(Mandatory = $true)]
            [String]
            $Path,
            [Parameter(Mandatory = $true)]
            [array]
            $InvalidNames
        )

        $Output = @()
        foreach ($Item in (Get-ChildItem -Path $Path -Recurse))
        {
            foreach ($InvalidName in $InvalidNames)
            {
                if ($Item.BaseName -contains $InvalidName)
                {
                    $Output += $Item
                }
            }
        }

        $Output = $Output | Sort-Object FullName.Length -Descending

        return $Output
    }

    function Rename-InvalidItems
    {
        param (
            [Parameter(Mandatory = $true,ValueFromPipeline)]
            [System.IO.FileSystemInfo[]]
            $Items
        )

        process 
        {
            # For each item, rename it
            $NewName = "RenamedItem$(Get-Random -Minimum 1000000 -Maximum 9999999)$($Items.Extension)"
            Rename-Item -Path $Items.FullName -NewName "$($NewName)"

            # Write out change to log
            $OldPath = $Items.FullName
            $NewPath = Join-Path (Split-Path $Items.FullName) -ChildPath $NewName
            Add-LogEntry -LogFolderPath "$($LogFolderPath)\RenamedFilesAndFolders.csv" -OldPath $OldPath -NewPath $NewPath
        }
    }

    # Copy all files and folders over to the destination
    CopyTo-OneDrive -Source $Source -Destination $Destination -LogFolderPath $LogFolderPath

    # Get the invalid items in the destination, rename them and write out the changes  to the log file
    Get-InvalidItems -Path $Destination -InvalidNames $InvalidNames | Rename-InvalidItems

}