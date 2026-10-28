; Per-user Windows installer for the Windows release export.

#ifndef AppVersion
  #define AppVersion "0.1.0"
#endif
#ifndef ReleaseTag
  #define ReleaseTag "v0.1.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\..\dist\windows"
#endif
#ifndef IconFile
  #define IconFile "..\..\assets\branding\captain-tsubasa-2.ico"
#endif
#ifndef OutputDir
  #define OutputDir "..\..\dist"
#endif

[Setup]
AppId={{8C8A2DB4-0481-4C62-8B3F-D5981578D319}
AppName=Captain Tsubasa 2 Remake
AppVersion={#AppVersion}
AppPublisher=susimsek
AppPublisherURL=https://github.com/susimsek/captain-tsubasa-2-remake
DefaultDirName={localappdata}\Programs\Captain Tsubasa 2 Remake
DefaultGroupName=Captain Tsubasa 2 Remake
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
SetupIconFile="{#IconFile}"
UninstallDisplayIcon={app}\captain-tsubasa-2-remake.exe
OutputDir={#OutputDir}
OutputBaseFilename=captain-tsubasa-2-remake-{#ReleaseTag}-windows-x86_64-setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SourceDir}\captain-tsubasa-2-remake.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\THIRD_PARTY_NOTICES.txt"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\Captain Tsubasa 2 Remake"; Filename: "{app}\captain-tsubasa-2-remake.exe"
Name: "{autodesktop}\Captain Tsubasa 2 Remake"; Filename: "{app}\captain-tsubasa-2-remake.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\captain-tsubasa-2-remake.exe"; Description: "{cm:LaunchProgram,Captain Tsubasa 2 Remake}"; Flags: nowait postinstall skipifsilent
