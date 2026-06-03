; Smart-ÖPNV Planer – Windows-Setup (Inno Setup)
; Erzeugt Setup-Smart-OEPNV-Planer-x64.exe mit klassischem Installationsassistenten

#define MyAppName "Smart-ÖPNV Planer"
#define MyAppExeName "Smart-OEPNV-Planer.exe"
#define MyAppPublisher "Smart-ÖPNV"
#define MyAppURL "https://github.com/BydE-BusB12b/GPSAnsagen"
#define MyAppVersion "0.3.1"

[Setup]
AppId={{B4E8F2A1-3C9D-4E7F-8A1B-2D5E6F9C0A3B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
DefaultDirName={autopf}\Smart-OEPNV\Planer
DefaultGroupName=Smart-ÖPNV
DisableProgramGroupPage=no
LicenseFile=assets\LICENSE.txt
InfoBeforeFile=assets\INFO.txt
OutputDir=..\dist
OutputBaseFilename=Setup-Smart-OEPNV-Planer-x64
SetupIconFile=assets\planer.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
UninstallDisplayName={#MyAppName}

[Languages]
Name: "german"; MessagesFile: "compiler:Languages\German.isl"

[Tasks]
Name: "desktopicon"; Description: "Desktopsymbol erstellen"; GroupDescription: "Zusätzliche Symbole:"; Flags: checkedonce
Name: "launchapp"; Description: "Smart-ÖPNV Planer nach der Installation starten"; GroupDescription: "Abschluss:"; Flags: checkedonce

[Files]
Source: "..\publish\win-x64\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"
Name: "{group}\{#MyAppName} deinstallieren"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; WorkingDir: "{app}"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent; Tasks: launchapp

[UninstallDelete]
Type: filesandordirs; Name: "{userappdata}\Smart-OEPNV\Planer"

[Code]
function InitializeSetup(): Boolean;
begin
  Result := True;
end;
