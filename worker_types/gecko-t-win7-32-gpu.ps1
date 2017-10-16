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
$client.DownloadFile("https://papertrailapp.com/tools/papertrail-bundle.pem", "C:\Program Files\nxlog\cert\papertrail-bundle.pem")

# NxLogPaperTrailConfiguration: Maintenance Toolchain - not essential for building firefox
$client.DownloadFile("https://raw.githubusercontent.com/mozilla-releng/OpenCloudConfig/master/userdata/Configuration/nxlog/win7.conf", "C:\Program Files\nxlog\conf\nxlog.conf")

# Start_nxlog: Maintenance Toolchain - not essential for building firefox
Set-Service "nxlog" -StartupType Automatic -Status Running

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
$client.DownloadFile("http://7-zip.org/a/7z1602.exe", "C:\binaries\4.exe")
Start-Process "C:\binaries\4.exe" -ArgumentList "/S" -Wait -NoNewWindow

# SublimeText3: Maintenance Toolchain - not essential for building firefox
$client.DownloadFile("https://download.sublimetext.com/Sublime%20Text%20Build%203114%20Setup.exe", "C:\binaries\5.exe")
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

# MozillaBuildSetup: Base Firefox on Windows build requirement
$client.DownloadFile("http://ftp.mozilla.org/pub/mozilla/libraries/win32/MozillaBuildSetup-2.2.0.exe", "C:\binaries\6.exe")
Start-Process "C:\binaries\6.exe" -ArgumentList "/S /D=C:\mozilla-build" -Wait -NoNewWindow

# msys_home: Maintenance Toolchain - not essential for building firefox
cmd /c mklink "C:\mozilla-build\msys\home" "C:\Users"

# reg_PythonInstallPath
New-ItemProperty -Path "HKLM:SOFTWARE\Python\PythonCore\2.7\InstallPath" -Name "(Default)" -Value "C:\mozilla-build\python" -PropertyType String -Force

# reg_PythonPath
New-ItemProperty -Path "HKLM:SOFTWARE\Python\PythonCore\2.7\PythonPath" -Name "(Default)" -Value "C:\mozilla-build\python\Lib;C:\mozilla-build\python\DLLs;C:\mozilla-build\python\Lib\lib-tk" -PropertyType String -Force

# DeleteMozillaBuildMercurial
Start-Process "cmd.exe" -ArgumentList "/c del C:\mozilla-build\python\Scripts\hg*" -Wait -NoNewWindow

# Mercurial: https://bugzilla.mozilla.org/show_bug.cgi?id=1390271
$client.DownloadFile("https://www.mercurial-scm.org/release/windows/mercurial-4.3.3-x86.msi", "C:\binaries\7.msi")
Start-Process "msiexec" -ArgumentList "/i C:\binaries\7.msi /quiet" -Wait -NoNewWindow

# MercurialConfig: Required by clonebundle and share hg extensions
$client.DownloadFile("https://raw.githubusercontent.com/mozilla-releng/OpenCloudConfig/master/userdata/Configuration/Mercurial/mercurial.ini", "C:\Program Files\Mercurial\Mercurial.ini")

# robustcheckout: Required by robustcheckout hg extension
$client.DownloadFile("https://raw.githubusercontent.com/mozilla-releng/OpenCloudConfig/master/userdata/Configuration/FirefoxBuildResources/robustcheckout.py", "C:\mozilla-build\robustcheckout.py")

# MercurialCerts
$client.DownloadFile("https://raw.githubusercontent.com/mozilla-releng/OpenCloudConfig/master/userdata/Configuration/Mercurial/cacert.pem", "C:\mozilla-build\msys\etc\cacert.pem")

# env_MOZILLABUILD: Absolutely required for mozharness builds. Python will fall in a heap, throwing misleading exceptions without this. :)
[Environment]::SetEnvironmentVariable("MOZILLABUILD", "C:\mozilla-build", "Machine")

# env_PATH
[Environment]::SetEnvironmentVariable("PATH", "C:\Program Files\Mercurial;C:\mozilla-build\7zip;C:\mozilla-build\info-zip;C:\mozilla-build\kdiff3;C:\mozilla-build\moztools-x64\bin;C:\mozilla-build\mozmake;C:\mozilla-build\msys\bin;C:\mozilla-build\msys\local\bin;C:\mozilla-build\nsis-3.0b3;C:\mozilla-build\nsis-2.46u;C:\mozilla-build\python;C:\mozilla-build\python\Scripts;C:\mozilla-build\upx391w;C:\mozilla-build\wget;C:\mozilla-build\yasm;%PATH%", "Machine")

# ToolToolInstall
$client.DownloadFile("https://raw.githubusercontent.com/mozilla/build-tooltool/master/tooltool.py", "C:\mozilla-build\tooltool.py")

# reg_WindowsErrorReportingLocalDumps
New-Item -Path "HKLM:SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps" -Force

# reg_WindowsErrorReportingDontShowUI
New-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "DontShowUI" -Value "0x00000001" -PropertyType Dword -Force

# GenericWorkerDirectory
md "C:\generic-worker"

# GenericWorkerDownload
$client.DownloadFile("https://github.com/taskcluster/generic-worker/releases/download/v8.2.0/generic-worker-windows-386.exe", "C:\generic-worker\generic-worker.exe")

# LiveLogDownload
$client.DownloadFile("https://github.com/taskcluster/livelog/releases/download/v1.1.0/livelog-windows-386.exe", "C:\generic-worker\livelog.exe")

# LiveLog_Get
New-NetFirewallRule -DisplayName "LiveLog_Get (TCP 60022 Inbound): Allow" -Direction Inbound -LocalPort 60022 -Protocol TCP -Action Allow

# LiveLog_Put
New-NetFirewallRule -DisplayName "LiveLog_Put (TCP 60023 Inbound): Allow" -Direction Inbound -LocalPort 60023 -Protocol TCP -Action Allow

# GenericWorkerInstall
Start-Process "C:\generic-worker\generic-worker.exe" -ArgumentList "install startup --config C:\generic-worker\generic-worker.config" -Wait -NoNewWindow

# DisableDesktopInterrupt
$client.DownloadFile("https://raw.githubusercontent.com/mozilla-releng/OpenCloudConfig/master/userdata/Configuration/GenericWorker/disable-desktop-interrupt.reg", "C:\generic-worker\disable-desktop-interrupt.reg")

# GenericWorkerStateWait
$client.DownloadFile("https://raw.githubusercontent.com/mozilla-releng/OpenCloudConfig/master/userdata/Configuration/GenericWorker/run-generic-worker-format-and-reboot.bat", "C:\generic-worker\run-generic-worker.bat")

# PipConfDirectory: https://pip.pypa.io/en/stable/user_guide/#config-file
md "C:\ProgramData\pip"

# PipConf
$client.DownloadFile("https://raw.githubusercontent.com/mozilla-releng/OpenCloudConfig/master/userdata/Configuration/pip.conf", "C:\ProgramData\pip\pip.ini")

# virtualenv_support
md "C:\mozilla-build\python\Lib\site-packages\virtualenv_support"

# virtualenv_support_pywin32
$client.DownloadFile("https://pypi.python.org/packages/cp27/p/pypiwin32/pypiwin32-219-cp27-none-win32.whl#md5=a8b0c1b608c1afeb18cd38d759ee5e29", "C:\mozilla-build\python\Lib\site-packages\virtualenv_support\pypiwin32-219-cp27-none-win32.whl")

# virtualenv_support_pywin32_amd64
$client.DownloadFile("https://pypi.python.org/packages/cp27/p/pypiwin32/pypiwin32-219-cp27-none-win_amd64.whl#md5=d7bafcf3cce72c3ce9fdd633a262c335", "C:\mozilla-build\python\Lib\site-packages\virtualenv_support\pypiwin32-219-cp27-none-win_amd64.whl")

# HgShared: allows builds to use `hg robustcheckout ...`
md "y:\hg-shared"

# HgSharedAccessRights: allows builds to use `hg robustcheckout ...`
Start-Process "icacls.exe" -ArgumentList "y:\hg-shared /grant Everyone:(OI)(CI)F" -Wait -NoNewWindow

# PipCache: share pip cache across subsequent task users
md "y:\pip-cache"

# PipCacheAccessRights: share pip cache across subsequent task users
Start-Process "icacls.exe" -ArgumentList "y:\pip-cache /grant Everyone:(OI)(CI)F" -Wait -NoNewWindow

# env_PIP_DOWNLOAD_CACHE: share pip download cache between tasks
[Environment]::SetEnvironmentVariable("PIP_DOWNLOAD_CACHE", "y:\pip-cache", "Machine")

# TooltoolCache: share tooltool cache across subsequent task users
md "y:\tooltool-cache"

# TooltoolCacheAccessRights: share tooltool cache across subsequent task users
Start-Process "icacls.exe" -ArgumentList "y:\tooltool-cache /grant Everyone:(OI)(CI)F" -Wait -NoNewWindow

# env_TOOLTOOL_CACHE: share tooltool cache between tasks
[Environment]::SetEnvironmentVariable("TOOLTOOL_CACHE", "y:\tooltool-cache", "Machine")

# ngen_executeQueuedItems: https://blogs.msdn.microsoft.com/dotnet/2013/08/06/wondering-why-mscorsvw-exe-has-high-cpu-usage-you-can-speed-it-up
Start-Process "c:\Windows\Microsoft.NET\Framework\v4.0.30319\ngen.exe" -ArgumentList "executeQueuedItems" -Wait -NoNewWindow

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

# MozillaMaintenanceDir: Working directory for Mozilla Maintenance Service installation
md "C:\dsc\MozillaMaintenance"

# maintenanceservice_installer
$client.DownloadFile("https://github.com/mozilla-releng/OpenCloudConfig/blob/master/userdata/Configuration/Mozilla%20Maintenance%20Service/maintenanceservice_installer.exe?raw=true", "C:\dsc\MozillaMaintenance\maintenanceservice_installer.exe")

# maintenanceservice
$client.DownloadFile("https://github.com/mozilla-releng/OpenCloudConfig/blob/master/userdata/Configuration/Mozilla%20Maintenance%20Service/maintenanceservice.exe?raw=true", "C:\dsc\MozillaMaintenance\maintenanceservice.exe")

# maintenanceservice_install
Start-Process "C:\dsc\MozillaMaintenance\maintenanceservice_installer.exe" -ArgumentList "/s" -Wait -NoNewWindow

# MozFakeCA.cer
$client.DownloadFile("https://github.com/mozilla-releng/OpenCloudConfig/blob/master/userdata/Configuration/Mozilla%20Maintenance%20Service/MozFakeCA.cer?raw=true", "C:\dsc\MozillaMaintenance\MozFakeCA.cer")

# MozFakeCA.cer
Start-Process "certutil.exe" -ArgumentList "-addstore Root C:\dsc\MozillaMaintenance\MozFakeCA.cer" -Wait -NoNewWindow

# MozRoot.cer
$client.DownloadFile("https://github.com/mozilla-releng/OpenCloudConfig/blob/master/userdata/Configuration/Mozilla%20Maintenance%20Service/MozRoot.cer?raw=true", "C:\dsc\MozillaMaintenance\MozRoot.cer")

# MozRoot.cer
Start-Process "certutil.exe" -ArgumentList "-addstore Root C:\dsc\MozillaMaintenance\MozRoot.cer" -Wait -NoNewWindow

# reg_Mozilla_MaintenanceService_3932ecacee736d366d6436db0f55bce4_0_name
New-ItemProperty -Path "HKLM:SOFTWARE\Mozilla\MaintenanceService\3932ecacee736d366d6436db0f55bce4\0" -Name "name" -Value "Mozilla Corporation" -PropertyType String -Force

# reg_Mozilla_MaintenanceService_3932ecacee736d366d6436db0f55bce4_0_issuer
New-ItemProperty -Path "HKLM:SOFTWARE\Mozilla\MaintenanceService\3932ecacee736d366d6436db0f55bce4\0" -Name "issuer" -Value "Thawte Code Signing CA - G2" -PropertyType String -Force

# reg_Mozilla_MaintenanceService_3932ecacee736d366d6436db0f55bce4_0_programName
New-ItemProperty -Path "HKLM:SOFTWARE\Mozilla\MaintenanceService\3932ecacee736d366d6436db0f55bce4\0" -Name "programName" -Value "" -PropertyType String -Force

# reg_Mozilla_MaintenanceService_3932ecacee736d366d6436db0f55bce4_0_publisherLink
New-ItemProperty -Path "HKLM:SOFTWARE\Mozilla\MaintenanceService\3932ecacee736d366d6436db0f55bce4\0" -Name "publisherLink" -Value "" -PropertyType String -Force

# reg_Mozilla_MaintenanceService_3932ecacee736d366d6436db0f55bce4_1_name
New-ItemProperty -Path "HKLM:SOFTWARE\Mozilla\MaintenanceService\3932ecacee736d366d6436db0f55bce4\1" -Name "name" -Value "Mozilla Fake SPC" -PropertyType String -Force

# reg_Mozilla_MaintenanceService_3932ecacee736d366d6436db0f55bce4_1_issuer
New-ItemProperty -Path "HKLM:SOFTWARE\Mozilla\MaintenanceService\3932ecacee736d366d6436db0f55bce4\1" -Name "issuer" -Value "Mozilla Fake CA" -PropertyType String -Force

# reg_Mozilla_MaintenanceService_3932ecacee736d366d6436db0f55bce4_1_programName
New-ItemProperty -Path "HKLM:SOFTWARE\Mozilla\MaintenanceService\3932ecacee736d366d6436db0f55bce4\1" -Name "programName" -Value "" -PropertyType String -Force

# reg_Mozilla_MaintenanceService_3932ecacee736d366d6436db0f55bce4_1_publisherLink
New-ItemProperty -Path "HKLM:SOFTWARE\Mozilla\MaintenanceService\3932ecacee736d366d6436db0f55bce4\1" -Name "publisherLink" -Value "" -PropertyType String -Force

# reg_Mozilla_MaintenanceService_3932ecacee736d366d6436db0f55bce4_2_name
New-ItemProperty -Path "HKLM:SOFTWARE\Mozilla\MaintenanceService\3932ecacee736d366d6436db0f55bce4\2" -Name "name" -Value "Mozilla Corporation" -PropertyType String -Force

# reg_Mozilla_MaintenanceService_3932ecacee736d366d6436db0f55bce4_2_issuer
New-ItemProperty -Path "HKLM:SOFTWARE\Mozilla\MaintenanceService\3932ecacee736d366d6436db0f55bce4\2" -Name "issuer" -Value "DigiCert SHA2 Assured ID Code Signing CA" -PropertyType String -Force

# reg_Mozilla_MaintenanceService_3932ecacee736d366d6436db0f55bce4_2_programName
New-ItemProperty -Path "HKLM:SOFTWARE\Mozilla\MaintenanceService\3932ecacee736d366d6436db0f55bce4\2" -Name "programName" -Value "" -PropertyType String -Force

# reg_Mozilla_MaintenanceService_3932ecacee736d366d6436db0f55bce4_2_publisherLink
New-ItemProperty -Path "HKLM:SOFTWARE\Mozilla\MaintenanceService\3932ecacee736d366d6436db0f55bce4\2" -Name "publisherLink" -Value "" -PropertyType String -Force

# GrantGenericWorkerMozillaRegistryWriteAccess: Bug 1353889 - Grant GenericWorker account write access to Mozilla registry key
Start-Process "powershell" -ArgumentList "-command `"& {& (Get-Acl -Path 'HKLM:\SOFTWARE\Mozilla').SetAccessRule(New-Object System.Security.AccessControl.RegistryAccessRule ('.\GenericWorker', 'FullControl', 'Allow'))}`"; `"& {& ((Get-Acl -Path 'HKLM:\SOFTWARE\Mozilla') | Set-Acl -Path 'HKLM:\SOFTWARE\Mozilla')}`"" -Wait -NoNewWindow

# KmsIn
New-NetFirewallRule -DisplayName "KmsIn (TCP 1688 Inbound): Allow" -Direction Inbound -LocalPort 1688 -Protocol TCP -Action Allow

# KmsOut
New-NetFirewallRule -DisplayName "KmsOut (TCP 1688 Outbound): Allow" -Direction Outbound -LocalPort 1688 -Protocol TCP -Action Allow

# nircmd
$client.DownloadFile("https://s3.amazonaws.com/windows-opencloudconfig-packages/nircmd/nircmd.exe", "C:\Windows\System32\nircmd.exe")

# nircmdc
$client.DownloadFile("https://s3.amazonaws.com/windows-opencloudconfig-packages/nircmd/nircmdc.exe", "C:\Windows\System32\nircmdc.exe")
