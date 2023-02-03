param(
    [string] $source,
    [string] $destination
)

write-host "Copying all files from $source to $destination"



function Check-FileNameLength {
    param(
        [string]$fileName,
        [string]$destinationPath
    )

    $maxLength = 255 # Maximum allowed file path length in Windows

    if (($destinationPath + $fileName).Length -gt $maxLength) {
        $index = 0

        $extension = [System.IO.Path]::GetExtension($fileName)
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)

        # Trim the base name to ensure the new file name is not too long
        # $baseName = $baseName.Substring(0, [Math]::Max(0, $maxLength - $destinationPath.Length - $extension.Length - $index.ToString().Length))

        # Ensure the new file name is unique
        # $newFileName = "{0}{1}{2}" -f $baseName, (&{If($index -gt 0) {"_$index"} Else {""}}), $extension
		#($index -gt 0 ? "_$index" : ""), $extension
		
		#TODO: fix empty filenames
        while (((Test-Path "$destinationPath\$newFileName") -or ($baseName.length -gt $maxLength)) -and ($index -lt 9999)) {
			# Trim the base name to ensure the new file name is not too long
			$baseName = $baseName.Substring(0, [Math]::Max(0, $maxLength - $destinationPath.Length - $extension.Length - $index.ToString().Length))

            $newFileName = "{0}{1}{2}" -f $baseName, (&{If($index -gt 0) {"_$index"} Else {""}}), $extension
            $index++
        }

        return $newFileName
    } else {
        return $fileName
    }
}


Get-ChildItem -Path $source -Recurse | ForEach-Object {
    $destinationPathWithFileName = $_.FullName.Replace($source, $destination)
	$destinationPathOnly = Split-Path $destinationPathWithFileName -Parent

    if ($_.PSIsContainer) {
		#TODO: fix error message for folders that already exist
        New-Item -ItemType Directory -Path $destinationPathOnly -ErrorVariable capturedErrors -ErrorAction SilentlyContinue | Out-Null
    } else {
        $newFileName = Check-FileNameLength $_.Name $destinationPathOnly		
        Copy-Item $_.FullName "$destinationPathOnly\$newFileName" -Force -ErrorVariable capturedErrors -ErrorAction SilentlyContinue
		#\$newFileName
    }

	$capturedErrors | foreach-object { if ($_ -notmatch "already exists") { write-error $_ } } 

}


