# capture env
Get-ChildItem Env: | Out-File "C:\install_env.txt"

# needed for making http requests
$client = New-Object system.net.WebClient
$shell = new-object -com shell.application

# utility function to download a zip file and extract it
function Extract-ZIPFile($file, $destination, $url)
{
    $client.DownloadFile($url, $file)
    $zip = $shell.NameSpace($file)
    foreach($item in $zip.items())
    {
        $shell.Namespace($destination).copyhere($item)
    }
}

md C:\logs
md C:\binaries

# LogDirectory: Required by OpenCloudConfig for DSC logging
md "C:\log"

# NxLog: Maintenance Toolchain - not essential for building firefox
$client.DownloadFile("https://nxlog.co/system/files/products/files/348/nxlog-ce-2.9.1716.msi", "C:\binaries\0.msi")
Start-Process "msiexec" -ArgumentList "/i C:\binaries\0.msi /quiet" -Wait -NoNewWindow

# PaperTrailEncryptionCertificate: Maintenance Toolchain - not essential for building firefox
$client.DownloadFile("https://papertrailapp.com/tools/papertrail-bundle.pem", "C:\Program Files (x86)\nxlog\cert\papertrail-bundle.pem")

# NxLogPaperTrailConfiguration: Maintenance Toolchain - not essential for building firefox
$client.DownloadFile("https://raw.githubusercontent.com/mozilla-releng/OpenCloudConfig/master/userdata/Configuration/nxlog/win2012.conf", "C:\Program Files (x86)\nxlog\conf\nxlog.conf")

# Start_nxlog: Maintenance Toolchain - not essential for building firefox
Set-Service "nxlog" -StartupType Automatic -Status Running

# DisableIndexing: Disable indexing on all disk volumes (for performance)
Get-WmiObject Win32_Volume -Filter "IndexingEnabled=$true" | Set-WmiInstance -Arguments @{IndexingEnabled=$false}

# ProcessExplorer: Maintenance Toolchain - not essential for building firefox
New-Item -ItemType Directory -Force -Path "C:\ProcessExplorer"
Extract-ZIPFile -File "C:\binaries\1.zip" -Destination "C:\ProcessExplorer" -Url "https://download.sysinternals.com/files/ProcessExplorer.zip"

# ProcessMonitor: Maintenance Toolchain - not essential for building firefox
New-Item -ItemType Directory -Force -Path "C:\ProcessMonitor"
Extract-ZIPFile -File "C:\binaries\2.zip" -Destination "C:\ProcessMonitor" -Url "https://download.sysinternals.com/files/ProcessMonitor.zip"

# GpgForWin: Maintenance Toolchain - not essential for building firefox
$client.DownloadFile("http://files.gpg4win.org/gpg4win-2.3.0.exe", "C:\binaries\3.exe")
Start-Process "C:\binaries\3.exe" -ArgumentList "/S" -Wait -NoNewWindow

# SevenZip: Maintenance Toolchain - not essential for building firefox
$client.DownloadFile("http://7-zip.org/a/7z1514-x64.exe", "C:\binaries\4.exe")
Start-Process "C:\binaries\4.exe" -ArgumentList "/S" -Wait -NoNewWindow

# SublimeText3: Maintenance Toolchain - not essential for building firefox
$client.DownloadFile("https://download.sublimetext.com/Sublime%20Text%20Build%203114%20x64%20Setup.exe", "C:\binaries\5.exe")
Start-Process "C:\binaries\5.exe" -ArgumentList "/VERYSILENT /NORESTART /TASKS=`"contextentry`"" -Wait -NoNewWindow

# SublimeText3_PackagesFolder: Maintenance Toolchain - not essential for building firefox
md "C:\Users\Administrator\AppData\Roaming\Sublime Text 3\Packages"

# SublimeText3_PackageControl: Maintenance Toolchain - not essential for building firefox
$client.DownloadFile("http://sublime.wbond.net/Package%20Control.sublime-package", "C:\Users\Administrator\AppData\Roaming\Sublime Text 3\Packages\Package Control.sublime-package")

# SystemPowerShellProfile: Maintenance Toolchain - not essential for building firefox
$client.DownloadFile("https://raw.githubusercontent.com/mozilla-releng/OpenCloudConfig/master/userdata/Configuration/Microsoft.PowerShell_profile.ps1", "C:\Windows\System32\WindowsPowerShell\v1.0\Microsoft.PowerShell_profile.ps1")

# FsutilDisable8Dot3: Maintenance Toolchain - not essential for building firefox
Start-Process "fsutil.exe" -ArgumentList "behavior set disable8dot3 1" -Wait -NoNewWindow

# FsutilDisableLastAccess: Maintenance Toolchain - not essential for building firefox
Start-Process "fsutil.exe" -ArgumentList "behavior set disablelastaccess 1" -Wait -NoNewWindow

# home: Maintenance Toolchain - not essential for building firefox
cmd /c mklink "C:\home" "C:\Users"

# Start_wuauserv: Required by NET-Framework-Core
Set-Service "wuauserv" -StartupType Manual -Status Running

# NET_Framework_Core: Required by DXSDK_Jun10
Install-WindowsFeature NET-Framework-Core

# VisualC2010RedistributablePackageX86Uninstall: Required by DXSDK_Jun10 (https://blogs.msdn.microsoft.com/chuckw/2011/12/09/known-issue-directx-sdk-june-2010-setup-and-the-s1023-error)
Start-Process "msiexec.exe" -ArgumentList "/passive /uninstall {F0C3E5D1-1ADE-321E-8167-68EF0DE699A5}" -Wait -NoNewWindow

# VisualC2010RedistributablePackageX86_64Uninstall: Required by DXSDK_Jun10 (https://blogs.msdn.microsoft.com/chuckw/2011/12/09/known-issue-directx-sdk-june-2010-setup-and-the-s1023-error)
Start-Process "msiexec.exe" -ArgumentList "/passive /uninstall {1D8E6291-B0D5-35EC-8441-6616F567A0F7}" -Wait -NoNewWindow

# DXSDK_Jun10: Provides D3D compilers required by 32 bit builds
$client.DownloadFile("http://download.microsoft.com/download/A/E/7/AE743F1F-632B-4809-87A9-AA1BB3458E31/DXSDK_Jun10.exe", "C:\binaries\6.exe")
Start-Process "C:\binaries\6.exe" -ArgumentList "/U" -Wait -NoNewWindow

# vcredist_vs2010_x86: Required by yasm (c:/mozilla-build/yasm/yasm.exe)
$client.DownloadFile("http://download.microsoft.com/download/C/6/D/C6D0FD4E-9E53-4897-9B91-836EBA2AACD3/vcredist_x86.exe", "C:\binaries\7.exe")
Start-Process "C:\binaries\7.exe" -ArgumentList "/install /passive /norestart /log C:\log\vcredist_vs2010_x86-install.log" -Wait -NoNewWindow

# vcredist_vs2010_x64: Required by yasm (c:/mozilla-build/yasm/yasm.exe)
$client.DownloadFile("http://download.microsoft.com/download/A/8/0/A80747C3-41BD-45DF-B505-E9710D2744E0/vcredist_x64.exe", "C:\binaries\8.exe")
Start-Process "C:\binaries\8.exe" -ArgumentList "/install /passive /norestart /log C:\log\vcredist_vs2010_x64-install.log" -Wait -NoNewWindow

# vcredist_vs2013_x86: Required by rustc (tooltool artefact)
$client.DownloadFile("http://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x86.exe", "C:\binaries\9.exe")
Start-Process "C:\binaries\9.exe" -ArgumentList "/install /passive /norestart /log C:\log\vcredist_vs2013_x86-install.log" -Wait -NoNewWindow

# vcredist_vs2013_x64: Required by rustc (tooltool artefact)
$client.DownloadFile("http://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe", "C:\binaries\10.exe")
Start-Process "C:\binaries\10.exe" -ArgumentList "/install /passive /norestart /log C:\log\vcredist_vs2013_x64-install.log" -Wait -NoNewWindow

# vcredist_vs2015_x86: Required by rustc (tooltool artefact)
$client.DownloadFile("http://download.microsoft.com/download/f/3/9/f39b30ec-f8ef-4ba3-8cb4-e301fcf0e0aa/vc_redist.x86.exe", "C:\binaries\11.exe")
Start-Process "C:\binaries\11.exe" -ArgumentList "/install /passive /norestart /log C:\log\vcredist_vs2015_x86-install.log" -Wait -NoNewWindow

# vcredist_vs2015_x64: Required by rustc (tooltool artefact)
$client.DownloadFile("http://download.microsoft.com/download/4/c/b/4cbd5757-0dd4-43a7-bac0-2a492cedbacb/vc_redist.x64.exe", "C:\binaries\12.exe")
Start-Process "C:\binaries\12.exe" -ArgumentList "/install /passive /norestart /log C:\log\vcredist_vs2015_x64-install.log" -Wait -NoNewWindow

# WindowsSDK10Setup
$client.DownloadFile("https://go.microsoft.com/fwlink/p/?LinkID=698771", "C:\binaries\13.exe")
Start-Process "C:\binaries\13.exe" -ArgumentList "/features + /quiet /norestart /ceip off /log C:\log\windowssdk10setup.log" -Wait -NoNewWindow

# BinScope: https://dxr.mozilla.org/mozilla-central/search?q=BinScope&redirect=false&case=false
$client.DownloadFile("https://github.com/mozilla-releng/OpenCloudConfig/raw/master/userdata/Configuration/FirefoxBuildResources/BinScope_x64.msi", "C:\binaries\14.msi")
Start-Process "msiexec" -ArgumentList "/i C:\binaries\14.msi /quiet" -Wait -NoNewWindow

# MozillaBuildSetup: Base Firefox on Windows build requirement
$client.DownloadFile("http://ftp.mozilla.org/pub/mozilla/libraries/win32/MozillaBuildSetup-2.2.0.exe", "C:\binaries\15.exe")
Start-Process "C:\binaries\15.exe" -ArgumentList "/S /D=C:\mozilla-build" -Wait -NoNewWindow

# NsisInstall: Bug 1236624 - NSIS 3.01
$client.DownloadFile("http://downloads.sourceforge.net/project/nsis/NSIS%203/3.01/nsis-3.01-setup.exe?r=http%3A%2F%2Fnsis.sourceforge.net%2FDownload&ts=1484218481&use_mirror=kent", "C:\binaries\16.exe")
Start-Process "C:\binaries\16.exe" -ArgumentList "/S /D=C:\mozilla-build\nsis-3.01" -Wait -NoNewWindow

# makensis_301: https://bugzilla.mozilla.org/show_bug.cgi?id=1236624#c53
cmd /c mklink "C:\mozilla-build\nsis-3.01\makensis-3.01.exe" "C:\mozilla-build\nsis-3.01\makensis.exe"

# bin_makensis_301: https://bugzilla.mozilla.org/show_bug.cgi?id=1236624#c53
cmd /c mklink "C:\mozilla-build\nsis-3.01\Bin\makensis-3.01.exe" "C:\mozilla-build\nsis-3.01\Bin\makensis.exe"

# msys_home: Maintenance Toolchain - not essential for building firefox
cmd /c mklink "C:\mozilla-build\msys\home" "C:\Users"

# DeleteMozillaBuildMercurial
Start-Process "cmd.exe" -ArgumentList "/c del C:\mozilla-build\python\Scripts\hg*" -Wait -NoNewWindow

# Mercurial: https://bugzilla.mozilla.org/show_bug.cgi?id=1390271
$client.DownloadFile("https://www.mercurial-scm.org/release/windows/mercurial-4.3.3-x64.msi", "C:\binaries\17.msi")
Start-Process "msiexec" -ArgumentList "/i C:\binaries\17.msi /quiet" -Wait -NoNewWindow

# MercurialConfig: Required by clonebundle and share hg extensions
$client.DownloadFile("https://raw.githubusercontent.com/mozilla-releng/OpenCloudConfig/master/userdata/Configuration/Mercurial/mercurial.ini", "C:\Program Files\Mercurial\Mercurial.ini")

# robustcheckout: Required by robustcheckout hg extension
$client.DownloadFile("https://raw.githubusercontent.com/mozilla-releng/OpenCloudConfig/master/userdata/Configuration/FirefoxBuildResources/robustcheckout.py", "C:\mozilla-build\robustcheckout.py")

# MercurialCerts
$client.DownloadFile("https://raw.githubusercontent.com/mozilla-releng/OpenCloudConfig/master/userdata/Configuration/Mercurial/cacert.pem", "C:\mozilla-build\msys\etc\cacert.pem")

# env_MOZILLABUILD: Absolutely required for mozharness builds. Python will fall in a heap, throwing misleading exceptions without this. :)
[Environment]::SetEnvironmentVariable("MOZILLABUILD", "C:\mozilla-build", "Machine")

# pip_upgrade_pip
Start-Process "C:\mozilla-build\python\python.exe" -ArgumentList "-m pip install --upgrade pip==8.1.2" -Wait -NoNewWindow

# pip_upgrade_setuptools
Start-Process "C:\mozilla-build\python\python.exe" -ArgumentList "-m pip install --upgrade setuptools==20.7.0" -Wait -NoNewWindow

# pip_upgrade_virtualenv
Start-Process "C:\mozilla-build\python\python.exe" -ArgumentList "-m pip install --upgrade virtualenv==15.0.1" -Wait -NoNewWindow

# pip_upgrade_wheel
Start-Process "C:\mozilla-build\python\python.exe" -ArgumentList "-m pip install --upgrade wheel==0.29.0" -Wait -NoNewWindow

# pip_upgrade_pypiwin32
Start-Process "C:\mozilla-build\python\python.exe" -ArgumentList "-m pip install --upgrade pypiwin32==219" -Wait -NoNewWindow

# pip_upgrade_requests
Start-Process "C:\mozilla-build\python\python.exe" -ArgumentList "-m pip install --upgrade requests==2.8.1" -Wait -NoNewWindow

# pip_upgrade_psutil
Start-Process "C:\mozilla-build\python\python.exe" -ArgumentList "-m pip install --upgrade psutil==4.1.0" -Wait -NoNewWindow

# ToolToolInstall
$client.DownloadFile("https://raw.githubusercontent.com/mozilla/build-tooltool/master/tooltool.py", "C:\mozilla-build\tooltool.py")

# Win32ToolToolManifest: Latest tooltool manifest from mozilla central
$client.DownloadFile("https://hg.mozilla.org/mozilla-central/raw-file/tip/browser/config/tooltool-manifests/win32/releng.manifest", "C:\Windows\Temp\releng.manifest.win32.tt")

# Win64ToolToolManifest: Latest tooltool manifest from mozilla central
$client.DownloadFile("https://hg.mozilla.org/mozilla-central/raw-file/tip/browser/config/tooltool-manifests/win64/releng.manifest", "C:\Windows\Temp\releng.manifest.win64.tt")

# ToolToolPreCacheWin32: Prepopulates the local tooltool cache
Start-Process "C:\mozilla-build\python\python.exe" -ArgumentList "C:\mozilla-build\tooltool.py fetch --url https://api.pub.build.mozilla.org/tooltool -c C:\builds\tooltool_cache --authentication-file C:\builds\relengapi.tok -m C:\Windows\Temp\releng.manifest.win32.tt" -Wait -NoNewWindow

# ToolToolPreCacheWin64: Prepopulates the local tooltool cache
Start-Process "C:\mozilla-build\python\python.exe" -ArgumentList "C:\mozilla-build\tooltool.py fetch --url https://api.pub.build.mozilla.org/tooltool -c C:\builds\tooltool_cache --authentication-file C:\builds\relengapi.tok -m C:\Windows\Temp\releng.manifest.win64.tt" -Wait -NoNewWindow

# env_TOOLTOOL_CACHE: Tells the build system where to find the local tooltool cache
[Environment]::SetEnvironmentVariable("TOOLTOOL_CACHE", "C:\builds\tooltool_cache", "Machine")

# env_PATH
[Environment]::SetEnvironmentVariable("PATH", "C:\Program Files\Mercurial;C:\mozilla-build\7zip;C:\mozilla-build\info-zip;C:\mozilla-build\kdiff3;C:\mozilla-build\moztools-x64\bin;C:\mozilla-build\mozmake;C:\mozilla-build\msys\bin;C:\mozilla-build\msys\local\bin;C:\mozilla-build\nsis-3.01;C:\mozilla-build\nsis-3.0b3;C:\mozilla-build\nsis-2.46u;C:\mozilla-build\python;C:\mozilla-build\python\Scripts;C:\mozilla-build\upx391w;C:\mozilla-build\wget;C:\mozilla-build\yasm;%PATH%", "Machine")

# reg_WindowsErrorReportingLocalDumps
New-Item -Path "HKLM:SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps" -Force

# reg_WindowsErrorReportingDontShowUI
New-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "DontShowUI" -Value "0x00000001" -PropertyType Dword -Force

# env_DXSDK_DIR
[Environment]::SetEnvironmentVariable("DXSDK_DIR", "C:\Program Files (x86)\Microsoft DirectX SDK (June 2010)", "Machine")

# GenericWorkerDirectory
md "C:\generic-worker"

# GenericWorkerDownload
$client.DownloadFile("https://github.com/taskcluster/generic-worker/releases/download/v10.2.2/generic-worker-windows-amd64.exe", "C:\generic-worker\generic-worker.exe")

# LiveLogDownload
$client.DownloadFile("https://github.com/taskcluster/livelog/releases/download/v1.1.0/livelog-windows-amd64.exe", "C:\generic-worker\livelog.exe")

# LiveLog_Get
New-NetFirewallRule -DisplayName "LiveLog_Get (TCP 60022 Inbound): Allow" -Direction Inbound -LocalPort 60022 -Protocol TCP -Action Allow

# LiveLog_Put
New-NetFirewallRule -DisplayName "LiveLog_Put (TCP 60023 Inbound): Allow" -Direction Inbound -LocalPort 60023 -Protocol TCP -Action Allow

# NSSMDownload
$client.DownloadFile("https://nssm.cc/ci/nssm-2.24-103-gdee49fc.zip", "C:\Windows\Temp\NSSMInstall.zip")

# NSSMInstall: NSSM is required to install Generic Worker as a service. Currently ZipInstall fails, so using 7z instead.
Start-Process "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x -oC:\ C:\Windows\Temp\NSSMInstall.zip" -Wait -NoNewWindow

# GenericWorkerInstall
Start-Process "C:\generic-worker\generic-worker.exe" -ArgumentList "install service --nssm C:\nssm-2.24-103-gdee49fc\win64\nssm.exe --config C:\generic-worker\generic-worker.config" -Wait -NoNewWindow

# GenericWorkerStateWait
$client.DownloadFile("https://raw.githubusercontent.com/mozilla-releng/OpenCloudConfig/master/userdata/Configuration/GenericWorker/run-generic-worker-format-and-reboot.bat", "C:\generic-worker\run-generic-worker.bat")

# HgShared: allows builds to use `hg robustcheckout ...`
md "y:\hg-shared"

# HgSharedAccessRights: allows builds to use `hg robustcheckout ...`
Start-Process "icacls.exe" -ArgumentList "y:\hg-shared /grant Everyone:(OI)(CI)F" -Wait -NoNewWindow

# LegacyHgShared: allows builds to use `hg share ...`
md "c:\builds\hg-shared"

# LegacyHgSharedAccessRights: allows builds to use `hg share ...`
Start-Process "icacls.exe" -ArgumentList "c:\builds\hg-shared /grant Everyone:(OI)(CI)F" -Wait -NoNewWindow

# CarbonClone: Bug 1316329 - support creation of symlinks by task users
Start-Process "C:\Program Files\Mercurial\hg.exe" -ArgumentList "clone --insecure https://bitbucket.org/splatteredbits/carbon C:\Windows\Temp\carbon" -Wait -NoNewWindow

# CarbonUpdate: Bug 1316329 - support creation of symlinks by task users
Start-Process "C:\Program Files\Mercurial\hg.exe" -ArgumentList "update 2.4.0 -R C:\Windows\Temp\carbon" -Wait -NoNewWindow

# CarbonInstall: Bug 1316329 - support creation of symlinks by task users
Start-Process "xcopy" -ArgumentList "C:\Windows\Temp\carbon\Carbon C:\Windows\System32\WindowsPowerShell\v1.0\Modules\Carbon /e /i /y" -Wait -NoNewWindow

# GrantEveryoneSeCreateSymbolicLinkPrivilege: Bug 1316329 - support creation of symlinks by task users
Start-Process "powershell" -ArgumentList "-command `"& {&'Import-Module' Carbon}`"; `"& {&'Grant-Privilege' -Identity Everyone -Privilege SeCreateSymbolicLinkPrivilege}`"" -Wait -NoNewWindow

# GrantGenericWorkerSeAssignPrimaryTokenPrivilege: Bug 1303455 - grant SeAssignPrimaryTokenPrivilege to g-w user
Start-Process "powershell" -ArgumentList "-command `"& {&'Import-Module' Carbon}`"; `"& {&'Grant-Privilege' -Identity GenericWorker -Privilege SeAssignPrimaryTokenPrivilege}`"" -Wait -NoNewWindow

# GrantGenericWorkerSeIncreaseQuotaPrivilege: Bug 1303455 - grant SeIncreaseQuotaPrivilege to g-w user
Start-Process "powershell" -ArgumentList "-command `"& {&'Import-Module' Carbon}`"; `"& {&'Grant-Privilege' -Identity GenericWorker -Privilege SeIncreaseQuotaPrivilege}`"" -Wait -NoNewWindow

# GrantGenericWorkerSeIncreaseBasePriorityPrivilege: Bug 1312383 - grant SeIncreaseBasePriorityPrivilege to g-w user
Start-Process "powershell" -ArgumentList "-command `"& {&'Import-Module' Carbon}`"; `"& {&'Grant-Privilege' -Identity GenericWorker -Privilege SeIncreaseBasePriorityPrivilege}`"" -Wait -NoNewWindow

# reg_PythonCpuPriority
New-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\python.exe\PerfOptions" -Name "CpuPriorityClass" -Value "0x00000006" -PropertyType Dword -Force

# reg_PythonIoPriority
New-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\python.exe\PerfOptions" -Name "IoPriority" -Value "0x00000002" -PropertyType Dword -Force

# reg_MercurialCpuPriority
New-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\hg.exe\PerfOptions" -Name "CpuPriorityClass" -Value "0x00000006" -PropertyType Dword -Force

# reg_MercurialIoPriority
New-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\hg.exe\PerfOptions" -Name "IoPriority" -Value "0x00000002" -PropertyType Dword -Force

# ZDriveAccessRights: facilitates loaner self provisioning
Start-Process "icacls.exe" -ArgumentList "z:\ /grant Everyone:(OI)(CI)F" -Wait -NoNewWindow

# KmsIn
New-NetFirewallRule -DisplayName "KmsIn (TCP 1688 Inbound): Allow" -Direction Inbound -LocalPort 1688 -Protocol TCP -Action Allow

# KmsOut
New-NetFirewallRule -DisplayName "KmsOut (TCP 1688 Outbound): Allow" -Direction Outbound -LocalPort 1688 -Protocol TCP -Action Allow
