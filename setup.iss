#define AppName "shine"

[Setup]
AppName=shine
AppVersion=1.0.0
AppPublisher=Shine Yarn

DefaultDirName={localappdata}\Programs\{#AppName}

DefaultGroupName={#AppName}
OutputBaseFilename={#AppName}_安装程序
OutputDir=.

PrivilegesRequired=lowest

ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{userdesktop}\{#AppName}"; Filename: "{app}\{#AppName}.exe"; IconFilename: "{app}\{#AppName}.exe"

Name: "{userprograms}\{#AppName}\{#AppName}"; Filename: "{app}\{#AppName}.exe"

Name: "{userprograms}\{#AppName}\卸载 {#AppName}"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\{#AppName}.exe"; Description: "启动 {#AppName}"; Flags: nowait postinstall skipifsilent