# PowerShell script to name photos for printing
# Nicholas Armstrong, Jan 2010
# Available at http://nicholasarmstrong.com
# Renames a folder of photos for printing using the capture date as the file name
# Run 'Set-ExecutionPolicy Unrestricted' from an admistrative prompt before running 
# the first time from a computer that hasn't been set to run Powershell scripts

Write-Output "Renames a folder of photos for printing using the capture date as the file name"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", ""
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", ""
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$files = Get-ChildItem -Filter "*.jpg" | sort name
$numFiles = @($files).Count

$result = $host.ui.PromptForChoice("", "Name $numFiles photos for printing?", $options, 0) 
if (!$result -and $numFiles)
{
    Write-Output "Processing..."
    
    # Load the assemblies needed for reading and parsing EXIF
    [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") > $null
    [System.Reflection.Assembly]::LoadWithPartialName("System.Text") > $null
   
    foreach ($file in $files)
    {
		# Image files are assumed to have a four-digit number in the filename;
		# if they do not, an alternate naming scheme is used
        $photoNumberPattern = [regex] '([0-9][0-9][0-9][0-9])'
        $photoNumber = $photoNumberPattern.Match($file.Name)        
        
        # Load image and get EXIF date
        $photo = [System.Drawing.Image]::FromFile($file)
        try
        {
            $dateProp = $photo.GetPropertyItem(36867)
        }
        catch
        {
            try
            {
                $dateProp = $photo.GetPropertyItem(306)
            }
            catch
            {
                continue
            }
        }
        $photo.Dispose()
        
        # Convert date taken metadata to appropriate fields
        $encoding = New-Object System.Text.UTF8Encoding
        $date = $encoding.GetString($dateProp.Value).Trim()
        $year = $date.Substring(0,4)
        $month = $date.Substring(5,2)
        $day = $date.Substring(8,2)
        
        # Set default filename
        if ($photoNumber.Success)
        {
            $filename = "{0}.{1}.{2}.i{3}.jpg" -f $year, $month, $day, $photoNumber.Groups[1].Value
        }
        else
        {
            $filename = "{0}.{1}.{2}.jpg" -f $year, $month, $day
        }
        
        # If file is named correctly, do not rename
        if (!$file.Name.Equals($filename))
        {
			$number = 0
			
			# If filename already exists, use incrementing counter to avoid conflicts
            while (Test-Path $filename)
            {
                $number++
                
                if ($photoNumber.Success)
                {
                    $photoNumber.Groups[1].Value
                    $filename = "{0}.{1}.{2}.i{3}.no{4}.jpg" -f $year, $month, $day, $photoNumber.Groups[1].Value, $number
                }
                else
                {
                    $filename = "{0}.{1}.{2}.no{3}.jpg" -f $year, $month, $day, $number
                }
            }
            
            # Rename the photo with the known-good filename
            Rename-Item $file.FullName -newName $filename
            Write-Output "Renamed $file to $filename"
        }
    }
}
         
Write-Output "Processing Complete"
