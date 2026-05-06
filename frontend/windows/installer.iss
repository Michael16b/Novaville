[Setup]
AppId={{NOVAVILLE-APP-GUID-123456789}
AppName=Novaville
AppVersion=1.0.0
AppPublisher=Novaville
DefaultDirName={autopf}\Novaville
DisableProgramGroupPage=yes
OutputDir=..\build\windows\x64\installer
OutputBaseFilename=Novaville-Windows-Setup
SetupIconFile=runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern

; 🎨 POUR PERSONNALISER LE DESIGN (Couleurs Novaville) :
; Crée ces deux images au format .bmp, mets-les dans le dossier windows/
; et décommente les deux lignes ci-dessous.
; WizardImageFile=installer_gauche.bmp    // Image sur le panneau de gauche (164 x 314 pixels)
; WizardSmallImageFile=installer_logo.bmp // Petit logo en haut à droite (55 x 55 pixels)

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Copie l'exécutable principal et tous les fichiers annexes (.dll, data, etc.)
Source: "..\build\windows\x64\runner\Release\Novaville.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Novaville"; Filename: "{app}\Novaville.exe"
Name: "{autodesktop}\Novaville"; Filename: "{app}\Novaville.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\Novaville.exe"; Description: "{cm:LaunchProgram,Novaville}"; Flags: nowait postinstall skipifsilent