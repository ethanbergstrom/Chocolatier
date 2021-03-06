﻿$Chocolatier = 'Chocolatier'

Import-PackageProvider $Chocolatier -Force

if ($PSEdition -eq 'Desktop' -and -not $env:CHOCO_CLI) {
	$platform = 'API'
} else {
	$platform = 'CLI'
}

Describe "$platform basic package search operations" {
	Context 'without additional arguments' {
		$package = 'cpu-z'

		It 'gets a list of latest installed packages' {
			Get-Package -Provider $Chocolatier | Where-Object {$_.Name -contains 'chocolatey'} | Should Not BeNullOrEmpty
		}
		It 'searches for the latest version of a package' {
			Find-Package -Provider $Chocolatier -Name $package | Where-Object {$_.Name -contains $package}  | Should Not BeNullOrEmpty
		}
		It 'searches for all versions of a package' {
			Find-Package -Provider $Chocolatier -Name $package -AllVersions | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
		}
		It 'searches for the latest version of a package with a wildcard pattern' {
			Find-Package -Provider $Chocolatier -Name "$package*" | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
		}
	}
	Context 'with additional arguments' {
		$package = 'cpu-z'
		$argsAndParams = '--exact'

		It 'searches for the exact package name' {
			Find-Package -Provider $Chocolatier -Name $package -AdditionalArguments $argsAndParams | Should Not BeNullOrEmpty
		}
	}
}

Describe "$platform DSC-compliant package installation and uninstallation" {
	Context 'without additional arguments' {
		$package = 'cpu-z'

		It 'searches for the latest version of a package' {
			Find-Package -Provider $Chocolatier -Name $package | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
		}
		It 'silently installs the latest version of a package' {
			Install-Package -Provider $Chocolatier -Name $package -Force | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
		}
		It 'finds the locally installed package just installed' {
			Get-Package -Provider $Chocolatier -Name $package | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
		}
		It 'silently uninstalls the locally installed package just installed' {
			Uninstall-Package -Provider $Chocolatier -Name $package | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
		}
	}
	Context 'with additional arguments' {
		$package = 'sysinternals'
		$argsAndParams = '--paramsglobal --params "/InstallDir=c:\windows\temp\sysinternals /QuickLaunchShortcut=false" -y --installargs MaintenanceService=false'

		It 'searches for the latest version of a package' {
			Find-Package -Provider $Chocolatier -Name $package -AdditionalArguments $argsAndParams | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
		}
		It 'silently installs the latest version of a package' {
			Install-Package -Force -Provider $Chocolatier -Name $package -AdditionalArguments $argsAndParams | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
		}
		It 'finds the locally installed package just installed' {
			Get-Package -Provider $Chocolatier -Name $package -AdditionalArguments $argsAndParams | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
		}
		It 'silently uninstalls the locally installed package just installed' {
			Uninstall-Package -Provider $Chocolatier -Name $package -AdditionalArguments $argsAndParams | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
		}
	}
}

Describe "$platform pipline-based package installation and uninstallation" {
	Context 'without additional arguments' {
		$package = 'cpu-z'

		It 'searches for and silently installs the latest version of a package' {
			Find-Package -Provider $Chocolatier -Name $package | Install-Package -Force | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
		}
		It 'finds and silently uninstalls the locally installed package just installed' {
			Get-Package -Provider $Chocolatier -Name $package | Uninstall-Package | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
		}
	}
	Context 'with additional arguments' {
		$package = 'sysinternals'
		$argsAndParams = '--paramsglobal --params "/InstallDir=c:\windows\temp\sysinternals /QuickLaunchShortcut=false" -y --installargs MaintenanceService=false'

		It 'searches for and silently installs the latest version of a package' {
			Find-Package -Provider $Chocolatier -Name $package | Install-Package -Force -AdditionalArguments $argsAndParams | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
		}

		It 'finds and silently uninstalls the locally installed package just installed' {
			Get-Package -Provider $Chocolatier -Name $package | Uninstall-Package -AdditionalArguments $argsAndParams | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
		}
	}
}

Describe "$platform multi-source support" {
	BeforeAll {
		$altSourceName = 'LocalChocoSource'
		$altSourceLocation = $PSScriptRoot
		$package = 'cpu-z'

		Save-Package $package -Source 'http://chocolatey.org/api/v2' -Path $altSourceLocation
		Unregister-PackageSource -Name $altSourceName -Provider $Chocolatier -ErrorAction SilentlyContinue
	}
	AfterAll {
		Remove-Item "$altSourceLocation\*.nupkg" -Force -ErrorAction SilentlyContinue
		Unregister-PackageSource -Name $altSourceName -Provider $Chocolatier -ErrorAction SilentlyContinue
	}

	It 'refuses to register a source with no location' {
		Register-PackageSource -Name $altSourceName -Provider $Chocolatier -ErrorAction SilentlyContinue | Where-Object {$_.Name -eq $altSourceName} | Should BeNullOrEmpty
	}
	It 'registers an alternative package source' {
		Register-PackageSource -Name $altSourceName -Provider $Chocolatier -Location $altSourceLocation | Where-Object {$_.Name -eq $altSourceName} | Should Not BeNullOrEmpty
	}
	It 'searches for and installs the latest version of a package from an alternate source' {
		Find-Package -Provider $Chocolatier -Name $package -source $altSourceName | Install-Package -Force | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
	}
	It 'finds and uninstalls a package installed from an alternate source' {
		Get-Package -Provider $Chocolatier -Name $package | Uninstall-Package | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
	}
	It 'unregisters an alternative package source' {
		Unregister-PackageSource -Name $altSourceName -Provider $Chocolatier
		Get-PackageSource -Provider $Chocolatier | Where-Object {$_.Name -eq $altSourceName} | Should BeNullOrEmpty
	}
}

Describe "$platform version filters" {
	$package = 'cpu-z'
	$version = '1.87'

	AfterAll {
		Uninstall-Package -Name $package -Provider $Chocolatier -ErrorAction SilentlyContinue
	}

	Context 'required version' {
		It 'searches for and silently installs a specific package version' {
			Find-Package -Provider $Chocolatier -Name $package -RequiredVersion $version | Install-Package -Force | Where-Object {$_.Name -contains $package -and $_.Version -eq $version} | Should Not BeNullOrEmpty
		}
		It 'finds and silently uninstalls a specific package version' {
			Get-Package -Provider $Chocolatier -Name $package -RequiredVersion $version | UnInstall-Package -Force | Where-Object {$_.Name -contains $package -and $_.Version -eq $version} | Should Not BeNullOrEmpty
		}
	}

	Context 'minimum version' {
		It 'searches for and silently installs a minimum package version' {
			Find-Package -Provider $Chocolatier -Name $package -MinimumVersion $version | Install-Package -Force | Where-Object {$_.Name -contains $package -and $_.Version -ge $version} | Should Not BeNullOrEmpty
		}
		It 'finds and silently uninstalls a minimum package version' {
			Get-Package -Provider $Chocolatier -Name $package -MinimumVersion $version | UnInstall-Package -Force | Where-Object {$_.Name -contains $package -and $_.Version -ge $version} | Should Not BeNullOrEmpty
		}
	}

	Context 'maximum version' {
		It 'searches for and silently installs a maximum package version' {
			Find-Package -Provider $Chocolatier -Name $package -MaximumVersion $version | Install-Package -Force | Where-Object {$_.Name -contains $package -and $_.Version -le $version} | Should Not BeNullOrEmpty
		}
		It 'finds and silently uninstalls a maximum package version' {
			Get-Package -Provider $Chocolatier -Name $package -MaximumVersion $version | UnInstall-Package -Force | Where-Object {$_.Name -contains $package -and $_.Version -le $version} | Should Not BeNullOrEmpty
		}
	}

	Context '"latest" version' {
		It 'does not find the "latest" locally installed version if an outdated version is installed' {
			Install-Package -name $package -requiredVersion $version -Provider $Chocolatier -Force
			Get-Package -Provider $Chocolatier -Name $package -RequiredVersion 'latest' -ErrorAction SilentlyContinue | Where-Object {$_.Name -contains $package} | Should BeNullOrEmpty
		}
		It 'searches for and silently installs the latest package version' {
			Find-Package -Provider $Chocolatier -Name $package -RequiredVersion 'latest' | Install-Package -Force | Where-Object {$_.Name -contains $package -and $_.Version -gt $version} | Should Not BeNullOrEmpty
		}
		It 'finds and silently uninstalls a specific package version' {
			Get-Package -Provider $Chocolatier -Name $package -RequiredVersion 'latest' | UnInstall-Package -Force | Where-Object {$_.Name -contains $package -and $_.Version -gt $version} | Should Not BeNullOrEmpty
		}
	}
}
