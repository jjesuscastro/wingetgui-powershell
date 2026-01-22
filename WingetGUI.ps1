Write-Host "WinGet Application Installer v012226"

Start-Process "winget" -ArgumentList "search 7zip --accept-source-agreements" -WindowStyle Hidden -Wait

# Application categories and IDs
$appsByCategory = [ordered]@{ 
    "Browsers"     = [ordered]@{ 
        "Google Chrome"   = "Google.Chrome"
        "Mozilla Firefox" = "Mozilla.Firefox"
        "Opera GX"        = "Opera.OperaGX"
        "Helium"          = "ImputNet.Helium"
    } 
    "Utilities"    = [ordered]@{ 
        "AnyBurn"     = "PowerSoftware.AnyBurn"
        "Bitwarden"  = "Bitwarden.Bitwarden"
        "7-Zip"       = "7zip.7zip" 
        "PowerToys"   = "Microsoft.PowerToys" 
        "qBittorrent" = "qBittorrent.qBittorrent"
        "Google Drive"= "Google.GoogleDrive"
    } 
    "Messaging"    = [ordered]@{
        "Discord"     = "Discord.Discord" 
        "Discord PTB" = "Discord.Discord.PTB"
    }
    "Development"  = [ordered]@{ 
        "Git"                = "Git.Git" 
        "GitHub Desktop"     = "GitHub.GitHubDesktop"
        "JetBrains Rider"    = "JetBrains.Rider"
        "Unity Hub"          = "Unity.UnityHub" 
        "Visual Studio Code" = "Microsoft.VisualStudioCode"
        "Visual Studio Community" = "Microsoft.VisualStudio.Community"
    }
    "Media"        = [ordered]@{ 
        "Handbrake"        = "Handbrake.Handbrake"
        "OBS Studio"       = "OBSProject.OBSStudio"
        "Spotify"          = "Spotify.Spotify"
        "VLC Media Player" = "VideoLAN.VLC" 
    }
    "Gaming"       = [ordered]@{ 
        "Epic Games Launcher" = "EpicGames.EpicGamesLauncher"
        "Steam"               = "Valve.Steam" 
        "Valorant"            = "RiotGames.Valorant.AP" 
    }
    "Productivity" = [ordered]@{ 
        "Microsoft Office" = "Microsoft.MicrosoftOffice"
        "Notion"           = "Notion.Notion" 
    }
    "Security"     = [ordered]@{ 
        "Malwarebytes" = "Malwarebytes.Malwarebytes" 
    }
    "3D Printing"  = [ordered]@{ 
        "PrusaSlicer" = "Prusa3D.PrusaSlicer" 
    }
    "Other"        = [ordered]@{ 
        "Rainmeter" = "Rainmeter.Rainmeter"
        "VIA"       = "Olivia.VIA" 
        "Vial"      = "Vial.Vial"
        "WindHawk"  = "RamenSoftware.Windhawk"
    }
}

# List of apps I install by default
$defaultIds = @(
    "Mozilla.Firefox",
    "ImputNet.Helium",
    "PowerSoftware.AnyBurn",
    "7zip.7zip",
    "Microsoft.PowerToys",
    "qBittorrent.qBittorrent",
    "Google.GoogleDrive",
    "Discord.Discord",
    "Git.Git",
    "Unity.UnityHub",
    "Microsoft.VisualStudioCode",
    "Microsoft.VisualStudio.Community",
    "Handbrake.Handbrake",
    "VideoLAN.VLC",
    "EpicGames.EpicGamesLauncher",
    "Valve.Steam",
    "RiotGames.Valorant.AP",
    "Notion.Notion",
    "Malwarebytes.Malwarebytes",
    "Olivia.VIA",
    "Vial.Vial",
    "RamenSoftware.Windhawk"
)

Add-Type -AssemblyName System.Windows.Forms

# Function to New the main form
function New-MainForm {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "WinGet Application Installer"
    $form.Size = New-Object System.Drawing.Size(400, 500)
    $form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30) # Dark Charcoal
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"  # Prevent resizing
    return $form
}

# Function to New the application selection TreeView
function New-TreeView {
    $treeView = New-Object System.Windows.Forms.TreeView
    $treeView.Size = New-Object System.Drawing.Size(350, 300)
    $treeView.Location = New-Object System.Drawing.Point(20, 50)
    $treeView.CheckBoxes = $true  # Allows selection of applications

    # Color properties
    $treeView.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
    $treeView.ForeColor = [System.Drawing.Color]::White
    $treeView.LineColor = [System.Drawing.Color]::White
    return $treeView
}

# Function to get the list of installed applications and cache it
function Get-InstalledApps {
    $global:installedAppsCache = winget list 2>&1
}

# Function to check if an application is installed using the cached list
function Is-AppInstalled {
    param($appId)
    return ($global:installedAppsCache -match $appId)
}

# Function to Update the TreeView with categorized applications
function Update-TreeView {
    param($treeView, $appsByCategory)

    $total = 0

    foreach ($category in $appsByCategory.Keys) {
        $categoryNode = New-Object System.Windows.Forms.TreeNode($category)
        foreach ($appName in $appsByCategory[$category].Keys) {
            $appId = $appsByCategory[$category][$appName]
            $displayText = "$appName ($appId)"
            $appNode = New-Object System.Windows.Forms.TreeNode($displayText)
            $appNode.Tag =  $appId # Store winget ID for installation
            
            # Check if the application is installed and disable the checkbox if it is
            if (Is-AppInstalled -appId $appNode.Tag) {
                $appNode.ForeColor = [System.Drawing.Color]::Gray
                $appNode.NodeFont = New-Object System.Drawing.Font($treeView.Font, [System.Drawing.FontStyle]::Strikeout)
                $appNode.BackColor = [System.Drawing.Color]::LightGray
            }
            
            $categoryNode.Nodes.Add($appNode) > $null

            $total++
        }
        $treeView.Nodes.Add($categoryNode) > $null
    }

    # Write-Host "Added $total applications."
}

# Function to handle checking/unchecking of parent and child nodes
function Set-TreeViewEvents {
    param($treeView)
    $treeView.add_AfterCheck({
            param($s, $e)
            if ($e.Action -ne 'ByMouse') { return }  # Prevent infinite loops
        
            $node = $e.Node
            $isChecked = $node.Checked
        
            # Check/uncheck all child nodes when parent is checked/unchecked
            foreach ($childNode in $node.Nodes) {
                $childNode.Checked = $isChecked
            }
        
            # If all child nodes are checked, check the parent node as well
            if ($null -ne $node.Parent) {
                $allChecked = $true
                foreach ($sibling in $node.Parent.Nodes) {
                    if (-not $sibling.Checked) {
                        $allChecked = $false
                        break
                    }
                }
                $node.Parent.Checked = $allChecked
            }
        })
}

# Function to New the installation status label
function New-StatusLabel {
    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.ForeColor = [System.Drawing.Color]::White # White text
    $statusLabel.Size = New-Object System.Drawing.Size(350, 20)
    $statusLabel.Location = New-Object System.Drawing.Point(20, 330)
    $statusLabel.Text = "Select apps to Install. Greyed out apps are already installed."
    return $statusLabel
}

# Function to New the install button
function New-InstallButton {
    param($treeView, $statusLabel)
    $installButton = New-Object System.Windows.Forms.Button
    $installButton.Text = "Install Selected"
    $installButton.Size = New-Object System.Drawing.Size(170, 30)
    $installButton.Location = New-Object System.Drawing.Point(200, 360)
    $installButton.BackColor = [System.Drawing.Color]::SteelBlue
    $installButton.ForeColor = [System.Drawing.Color]::Black
    $installButton.FlatStyle = "Flat"
    
    $installButton.Add_Click({
            $selectedApps = @()
            foreach ($categoryNode in $treeView.Nodes) {
                foreach ($appNode in $categoryNode.Nodes) {
                    $isInstalled = Is-AppInstalled -appId $appNode.Tag
                    if ($appNode.Checked -and -not $isInstalled) {
                        $selectedApps += $appNode.Tag  # Collect selected app IDs
                    }
                }
            }

            $total = $selectedApps.Count
            Write-Host "Selected $total apps: $selectedApps"
        
            if ($total -eq 0) {
                [System.Windows.Forms.MessageBox]::Show("No applications selected.", "Warning", "OK", "Warning")
                return
            }
            
            foreach ($app in $selectedApps) {
                $index = [array]::IndexOf($selectedApps, $app) + 1
                $statusLabel.Text = "Installing ($index of $total): $app"

                # Start the installation process
                $process = Start-Process "winget" -ArgumentList "install --id=$app --accept-package-agreements --accept-source-agreements" -NoNewWindow -PassThru

                # Show a rotating throbber while the process is running
                $throbber = @("", ".", "..", "...")
                $i = 0
                while (!$process.HasExited) {
                    $statusLabel.Text = "Installing ($index of $total): $app " + $throbber[$i % $throbber.Length]
                    $i++
                    Start-Sleep -Milliseconds 200
                }

                Write-Host "Finished installing ($index of $total): $app"
            }
        
            $statusLabel.Text = "Installation complete."
        })
    return $installButton
}

function New-DefaultButton {
    param($treeView) # Pass the treeView as a parameter
    
    $button = New-Object System.Windows.Forms.Button
    $button.Text = "Select Default Apps"
    $button.Size = New-Object System.Drawing.Size(170, 30)
    $button.Location = New-Object System.Drawing.Point(20, 10)
    $button.BackColor = [System.Drawing.Color]::LightGray
    $button.ForeColor = [System.Drawing.Color]::Black
    $button.FlatStyle = "Flat"

    $button.Add_Click({
        foreach ($categoryNode in $treeView.Nodes) {
            foreach ($appNode in $categoryNode.Nodes) {
                # Check if this app's ID is in our default list
                if ($defaultIds -contains $appNode.Tag) {
                    # Only check it if it's not already installed (to respect your grey-out logic)
                    if (-not (Is-AppInstalled -appId $appNode.Tag)) {
                        $appNode.Checked = $true
                    } else {
                        Write-Host "$appNode.Tag is already installed."
                    }
                }
                else {
                    # Optional: Uncheck apps NOT in the default list
                    $appNode.Checked = $false
                }
            }
        }
    })

    return $button
}

# Function to New additional buttons
function New-TitusButton {
    param($text, $xPos)
    
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $text
    $button.Size = New-Object System.Drawing.Size(170, 30)
    $button.Location = New-Object System.Drawing.Point($xPos, 400)
    $button.BackColor = [System.Drawing.Color]::LightGray
    $button.ForeColor = [System.Drawing.Color]::Black
    $button.FlatStyle = "Flat"

    # Properly define the click event to use the captured variable
    $button.Add_Click([System.EventHandler] {
            Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"iwr -useb https://christitus.com/win | iex`"" -NoNewWindow
        })

    return $button
}

function New-ActivateButton {
    param($text, $xPos)
    
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $text
    $button.Size = New-Object System.Drawing.Size(170, 30)
    $button.Location = New-Object System.Drawing.Point($xPos, 400)
    $button.BackColor = [System.Drawing.Color]::LightGray
    $button.ForeColor = [System.Drawing.Color]::Black
    $button.FlatStyle = "Flat"

    # Properly define the click event to use the captured variable
    $button.Add_Click([System.EventHandler] {
            Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://get.activated.win | iex`"" -NoNewWindow
        })

    return $button
}

# Function to create the refresh button
function New-RefreshButton {
    param($treeView, $appsByCategory)
    $refreshButton = New-Object System.Windows.Forms.Button
    $refreshButton.Text = "Refresh"
    $refreshButton.Size = New-Object System.Drawing.Size(170, 30)
    $refreshButton.Location = New-Object System.Drawing.Point(20, 360)
    $refreshButton.BackColor = [System.Drawing.Color]::LightGray
    $refreshButton.ForeColor = [System.Drawing.Color]::Black
    $refreshButton.FlatStyle = "Flat"
    
    $refreshButton.Add_Click({
            # Recheck the list of installed applications
            Get-InstalledApps
        
            # Clear the existing nodes
            $treeView.Nodes.Clear()
        
            # Update the TreeView with the new list
            Update-TreeView -treeView $treeView -appsByCategory $appsByCategory
        })
    return $refreshButton
}

# Initialize form and UI elements
$form = New-MainForm
$treeView = New-TreeView
$statusLabel = New-StatusLabel
$installButton = New-InstallButton -treeView $treeView -statusLabel $statusLabel
$defaultButton = New-DefaultButton -treeView $treeView -appsByCategory $appsByCategory
$refreshButton = New-RefreshButton -treeView $treeView -appsByCategory $appsByCategory
$chrisTitusButton = New-TitusButton -text "Chris Titus Script" -xPos 20
$activateButton = New-ActivateButton -text "Activate Windows" -xPos 200

# Get the list of installed applications and cache it
Get-InstalledApps

# Update and Set UI elements
Update-TreeView -treeView $treeView -appsByCategory $appsByCategory
Set-TreeViewEvents -treeView $treeView

# Add elements to the form
$form.Controls.Add($treeView)
$form.Controls.Add($statusLabel)
$form.Controls.Add($installButton)
$form.Controls.Add($defaultButton)
$form.Controls.Add($refreshButton)
$form.Controls.Add($chrisTitusButton)
$form.Controls.Add($activateButton)

# Show the Form
$form.ShowDialog()
