﻿$Chocolatier = 'Chocolatier'

Import-PackageProvider $Chocolatier -Force

Describe 'basic package search operations' {
	Context 'without additional arguments' {
		$package = 'cpu-z'

		It 'gets a list of latest installed packages' {
			Get-Package -ProviderName $Chocolatier | Where-Object {$_.Name -contains 'chocolatey'} | Should Not BeNullOrEmpty
		}
		It 'searches for the latest version of a package' {
			Find-Package -ProviderName $Chocolatier -Name $package | Where-Object {$_.Name -contains $package}  | Should Not BeNullOrEmpty
		}
		It 'searches for all versions of a package' {
			Find-Package -ProviderName $Chocolatier -Name $package -AllVersions | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
		}
		It 'searches for the latest version of a package with a wildcard pattern' {
			Find-Package -ProviderName $Chocolatier -Name "$package*" | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
		}
	}
	Context 'with additional arguments' {
		$package = 'cpu-z'
		$argsAndParams = '--exact'

		It 'searches for the exact package name' {
			Find-Package -ProviderName $Chocolatier -Name $package -AdditionalArguments $argsAndParams | Should Not BeNullOrEmpty
		}
	}
}

Describe "DSC-compliant package installation and uninstallation" {
	Context 'without additional arguments' {
		$package = 'cpu-z'

		It 'searches for the latest version of a package' {
			Find-Package -ProviderName $Chocolatier -Name $package | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
		}
		It 'silently installs the latest version of a package' {
			Install-Package -ProviderName $Chocolatier -Name $package -Force | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
		}
		It 'finds the locally installed package just installed' {
			Get-Package -ProviderName $Chocolatier -Name $package | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
		}
		It 'silently uninstalls the locally installed package just installed' {
			Uninstall-Package -ProviderName $Chocolatier -Name $package | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
		}
	}
	Context 'with additional arguments' {
		$package = 'sysinternals'
		$argsAndParams = '--paramsglobal --params "/InstallDir=c:\windows\temp\sysinternals /QuickLaunchShortcut=false" -y --installargs MaintenanceService=false'

		It 'searches for the latest version of a package' {
			Find-Package -ProviderName $Chocolatier -Name $package -AdditionalArguments $argsAndParams | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
		}
		It 'silently installs the latest version of a package' {
			Install-Package -Force -ProviderName $Chocolatier -Name $package -AdditionalArguments $argsAndParams | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
		}
		It 'finds the locally installed package just installed' {
			Get-Package -ProviderName $Chocolatier -Name $package -AdditionalArguments $argsAndParams | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
		}
		It 'silently uninstalls the locally installed package just installed' {
			Uninstall-Package -ProviderName $Chocolatier -Name $package -AdditionalArguments $argsAndParams | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
		}
	}
}

Describe "pipline-based package installation and uninstallation" {
	Context 'without additional arguments' {
		$package = 'cpu-z'

		It 'searches for and silently installs the latest version of a package' {
			Find-Package -ProviderName $Chocolatier -Name $package | Install-Package -Force | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
		}
		It 'finds and silently uninstalls the locally installed package just installed' {
			Get-Package -ProviderName $Chocolatier -Name $package | Uninstall-Package | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
		}
	}
	Context 'with additional arguments' {
		$package = 'sysinternals'
		$argsAndParams = '--paramsglobal --params "/InstallDir=c:\windows\temp\sysinternals /QuickLaunchShortcut=false" -y --installargs MaintenanceService=false'

		It 'searches for and silently installs the latest version of a package' {
			Find-Package -ProviderName $Chocolatier -Name $package | Install-Package -Force -AdditionalArguments $argsAndParams | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
		}

		It 'finds and silently uninstalls the locally installed package just installed' {
			Get-Package -ProviderName $Chocolatier -Name $package | Uninstall-Package -AdditionalArguments $argsAndParams | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
		}
	}
}

Describe 'multi-source support' {
	BeforeAll {
		$altSourceName = 'LocalChocoSource'
		$altSourceLocation = $PSScriptRoot
		$package = 'cpu-z'

		Save-Package $package -Source 'http://chocolatey.org/api/v2' -Path $altSourceLocation
		Unregister-PackageSource -Name $altSourceName -ProviderName $Chocolatier -ErrorAction SilentlyContinue
	}
	AfterAll {
		Remove-Item "$altSourceLocation\*.nupkg" -Force -ErrorAction SilentlyContinue
		Unregister-PackageSource -Name $altSourceName -ProviderName $Chocolatier -ErrorAction SilentlyContinue
	}

	It 'refuses to register a source with no location' {
		Register-PackageSource -Name $altSourceName -ProviderName $Chocolatier -ErrorAction SilentlyContinue | Where-Object {$_.Name -eq $altSourceName} | Should BeNullOrEmpty
	}
	It 'registers an alternative package source' {
		Register-PackageSource -Name $altSourceName -ProviderName $Chocolatier -Location $altSourceLocation | Where-Object {$_.Name -eq $altSourceName} | Should Not BeNullOrEmpty
	}
	It 'searches for and installs the latest version of a package from an alternate source' {
		Find-Package -ProviderName $Chocolatier -Name $package -source $altSourceName | Install-Package -Force | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
	}
	It 'finds and uninstalls a package installed from an alternate source' {
		Get-Package -ProviderName $Chocolatier -Name $package | Uninstall-Package | Where-Object {$_.Name -contains $package} | Should Not BeNullOrEmpty
	}
	It 'unregisters an alternative package source' {
		Unregister-PackageSource -Name $altSourceName -ProviderName $Chocolatier
		Get-PackageSource -ProviderName $Chocolatier | Where-Object {$_.Name -eq $altSourceName} | Should BeNullOrEmpty
	}
}

Describe 'version filters' {
	$package = "cpu-z"
	$version = "1.77"

	AfterAll {
		Uninstall-Package -Name $package -ProviderName $Chocolatier -ErrorAction SilentlyContinue
	}

	Context 'required version' {
		It 'searches for and silently installs a specific package version' {
			Find-Package -ProviderName $Chocolatier -Name $package -RequiredVersion $version | Install-Package -Force | Where-Object {$_.Name -contains $package -and $_.Version -eq $version} | Should Not BeNullOrEmpty
		}
		It 'finds and silently uninstalls a specific package version' {
			Get-Package -ProviderName $Chocolatier -Name $package -RequiredVersion $version | UnInstall-Package -Force | Where-Object {$_.Name -contains $package -and $_.Version -eq $version} | Should Not BeNullOrEmpty
		}
	}

	Context 'minimum version' {
		It 'searches for and silently installs a minimum package version' {
			Find-Package -ProviderName $Chocolatier -Name $package -MinimumVersion $version | Install-Package -Force | Where-Object {$_.Name -contains $package -and $_.Version -ge $version} | Should Not BeNullOrEmpty
		}
		It 'finds and silently uninstalls a minimum package version' {
			Get-Package -ProviderName $Chocolatier -Name $package -MinimumVersion $version | UnInstall-Package -Force | Where-Object {$_.Name -contains $package -and $_.Version -ge $version} | Should Not BeNullOrEmpty
		}
	}

	Context 'maximum version' {
		It 'searches for and silently installs a maximum package version' {
			Find-Package -ProviderName $Chocolatier -Name $package -MaximumVersion $version | Install-Package -Force | Where-Object {$_.Name -contains $package -and $_.Version -le $version} | Should Not BeNullOrEmpty
		}
		It 'finds and silently uninstalls a maximum package version' {
			Get-Package -ProviderName $Chocolatier -Name $package -MaximumVersion $version | UnInstall-Package -Force | Where-Object {$_.Name -contains $package -and $_.Version -le $version} | Should Not BeNullOrEmpty
		}
	}

	Context '"latest" version is specified' {
		It 'does not find the "latest" locally installed version if an outdated version is installed' {
			Install-Package -name $package -requiredVersion $version -ProviderName $Chocolatier -Force
			Get-Package -ProviderName $Chocolatier -Name $package -RequiredVersion 'latest' -ErrorAction SilentlyContinue | Where-Object {$_.Name -contains $package} | Should BeNullOrEmpty
		}
		It 'searches for and silently installs the latest package version' {
			Find-Package -ProviderName $Chocolatier -Name $package -RequiredVersion 'latest' | Install-Package -Force | Where-Object {$_.Name -contains $package -and $_.Version -gt $version} | Should Not BeNullOrEmpty
		}
		It 'finds and silently uninstalls a specific package version' {
			Get-Package -ProviderName $Chocolatier -Name $package -RequiredVersion 'latest' | UnInstall-Package -Force | Where-Object {$_.Name -contains $package -and $_.Version -gt $version} | Should Not BeNullOrEmpty
		}
	}
}
