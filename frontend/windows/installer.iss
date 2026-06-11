#define MyAppName GetEnv("APP_NAME")
#if MyAppName == ""
  #define MyAppName "Novaville"
#endif

[Setup]
AppId={{NOVAVILLE-APP-GUID-123456789}
AppName={#MyAppName}
AppVersion=1.0.0
AppPublisher={#MyAppName}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\build\windows\x64\installer
OutputBaseFilename={#MyAppName}-Windows-Setup
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
; L'exécutable généré par Flutter porte le nom du projet (frontend.exe). On le renomme dynamiquement.
Source: "..\build\windows\x64\runner\Release\frontend.exe"; DestDir: "{app}"; DestName: "{#MyAppName}.exe"; Flags: ignoreversion
; On copie le reste des fichiers sans l'exécutable d'origine pour éviter les doublons
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Excludes: "frontend.exe"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppName}.exe"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppName}.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppName}.exe"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent