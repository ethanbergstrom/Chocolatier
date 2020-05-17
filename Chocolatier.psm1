#region Private Variables
# Current script path
[string]$ScriptPath = Split-Path (Get-Variable MyInvocation -Scope Script).Value.MyCommand.Definition -Parent

# Define provider related variables
$script:ProviderName = "Chocolatier"
$script:PackageSourceName = "Chocolatey"
$script:additionalArguments = "AdditionalArguments"
$script:AllVersions = "AllVersions"
$script:AcceptLicense = "AcceptLicense"

# Define choco related variables
$script:ChocoExeName = 'choco.exe'

# Only allow the native Chocolatey .NET library with FullCLR
if ($PSEdition -eq 'Desktop' -and $env:CHOCO_NATIVEAPI) {
	$script:NativeAPI = $true
	# If Choco.exe isn't already installed, try to guess where the API files should get extracted
	if (-not $env:ChocolateyInstall) {
		$env:ChocolateyInstall = "$($env:ProgramData)\chocolatey"
	}
}

# Utility variables
$script:FastReferenceRegex = "(?<name>[^#]*)#(?<version>[^\s]*)#(?<source>[^#]*)"
$script:ChocoSourcePropertyNames = @(
	'Name',
	'Location',
	'Disabled',
	'UserName',
	'Certificate',
	'Priority',
	'Bypass Proxy',
	'Allow Self Service',
	'Visibile to Admins Only'
)

Import-LocalizedData LocalizedData -filename "$script:ProviderName.Resource.psd1"

#endregion Private Variables

#region Methods

# Load included libraries, since the manifest wont handle that for package providers
if ($script:NativeAPI) {
	Get-ChildItem $ScriptPath/lib/ -Filter 'chocolatey.dll' -File | ForEach-Object {
		Add-Type -Path $_.FullName
	}
}

# Dot sourcing private script files
Get-ChildItem $ScriptPath/src/private -Recurse -Filter '*.ps1' -File | ForEach-Object {
	. $_.FullName
}

# Load and export methods

# Dot sourcing public function files
Get-ChildItem $ScriptPath/src/public -Recurse -Filter '*.ps1' -File | ForEach-Object {
	. $_.FullName

	# Find all the functions defined no deeper than the first level deep and export it.
	# This looks ugly but allows us to not keep any uneeded variables from polluting the module.
	([System.Management.Automation.Language.Parser]::ParseInput((Get-Content -Path $_.FullName -Raw), [ref]$null, [ref]$null)).FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false) | ForEach-Object {
		Export-ModuleMember $_.Name
	}
}
#endregion Methods

#region Module Cleanup
$ExecutionContext.SessionState.Module.OnRemove = {
	# cleanup when unloading module (if any)
}
#endregion Module Cleanup
