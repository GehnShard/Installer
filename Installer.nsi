; Installer for Gehn Shard.
; Makes use of the Modern UI for NSIS.

;;;;;;;;;;;;
; Includes ;
;;;;;;;;;;;;
!include MUI2.nsh

;;;;;;;;;;;;;;;;;;;;;;
; Installer Settings ;
;;;;;;;;;;;;;;;;;;;;;;
BrandingText            "Gehn Shard"
CRCCheck                on
InstallDir              "$PROGRAMFILES\Gehn Shard"
OutFile                 "gehn_shard.exe"
RequestExecutionLevel   admin

;;;;;;;;;;;;;;;;;;;;
; Meta Information ;
;;;;;;;;;;;;;;;;;;;;
Name                "Gehn Shard"
VIAddVersionKey     "CompanyName"       "Guild of Writers"
VIAddVersionKey     "FileDescription"   "Gehn Shard"
VIAddVersionKey     "FileVersion"       "14"
VIAddVersionKey     "LegalCopyright"    "Guild of Writers"
VIAddVersionKey     "ProductName"       "Gehn Shard"
VIProductVersion    "14.0.0.0"

;;;;;;;;;;;;;;;;;;;;;
; MUI Configuration ;
;;;;;;;;;;;;;;;;;;;;;
!define MUI_ABORTWARNING
!define MUI_ICON                        "Resources\Icon.ico"
!define MUI_FINISHPAGE_RUN              "$INSTDIR\UruLauncher.exe"

; Custom Images :D
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP          "Resources\Header.bmp"
!define MUI_WELCOMEFINISHPAGE_BITMAP    "Resources\WelcomeFinish.bmp"

;;;;;;;;;;;;;
; Variables ;
;;;;;;;;;;;;;
Var InstallToUru
Var InstDirUru

;;;;;;;;;;;;;
; Functions ;
;;;;;;;;;;;;;

; Tries to find the Uru Live directory in the registry.
Function FindUruDir
    StrCmp      $InstallToUru "true" skip_this_step
    ReadRegStr  $InstDirUru HKLM "Software\MOUL" "Install_Dir"
    Goto done
    skip_this_step:
        Abort
    done:
FunctionEnd

; Verifies that the source folder is an Uru Live directory.
; The check for the PhysX DLL is required to ensure it is a valid Uru Live
; installation, and not just an Uru installation.
Function VerifyUruDir
    FindFirst   $0 $1 "$InstDirUru\UruExplorer.exe"
    StrCmp      $1 "" bad_uru_dir
    FindClose   $0
    FindFirst   $0 $1 "$InstDirUru\NxExtensions.dll"
    StrCmp      $1 "" bad_uru_dir
    FindClose   $0
    Goto        done
    bad_uru_dir:
        MessageBox MB_YESNO|MB_ICONEXCLAMATION \
            "The folder you selected does not appear to be a valid Uru Live \
            installation. Are you sure you want to use this directory?" \
            IDYES done
        Abort
    done:
FunctionEnd

; Checks if the installation directory is an existing Uru Live directory.
; The check for the PhysX DLL is required to ensure it is a valid Uru Live
; installation, and not just an Uru installation.
Function CheckIfDirIsUru
    FindFirst   $0 $1 "$INSTDIR\UruExplorer.exe"
    StrCmp      $1 "" done
    FindClose   $0
    FindFirst   $0 $1 "$INSTDIR\NxExtensions.dll"
    StrCmp      $1 "" done
    FindClose   $0
    MessageBox  MB_YESNO|MB_ICONEXCLAMATION \
        "Your install folder appears to be a previous Uru Live installation. \
        This will work, but you will be unable to use this installation to \
        access Cyan's MOULagain shard anymore. Are you sure you want to \
        continue?" \
        IDYES set_have_urudir
    Abort
    set_have_urudir:
        StrCpy  $InstallToUru "true"
    done:
FunctionEnd

;;;;;;;;;
; Pages ;
;;;;;;;;;
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE                   "Resources\GPLv3.txt"
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE           CheckIfDirIsUru
!insertmacro MUI_PAGE_DIRECTORY
!define MUI_PAGE_HEADER_TEXT                    "Choose Uru Live Location"
!define MUI_PAGE_HEADER_SUBTEXT                 "Choose the folder in which \
                                                Uru Live was installed."
!define MUI_DIRECTORYPAGE_TEXT_TOP              "To install Gehn Shard, you \
                                                must first have installed Myst \
                                                Online: Uru Live (again). You \
                                                now need to locate the folder \
                                                in which you installed Uru \
                                                Live (usually C:\Program \
                                                Files\Uru Live)."
!define MUI_DIRECTORYPAGE_TEXT_DESTINATION      "Uru Live Folder"
!define MUI_DIRECTORYPAGE_VARIABLE              $InstDirUru
!define MUI_PAGE_CUSTOMFUNCTION_PRE             FindUruDir
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE           VerifyUruDir
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

;;;;;;;;;;;;;
; Languages ;
;;;;;;;;;;;;;
!insertmacro MUI_LANGUAGE "English"

;;;;;;;;;;;;
; Sections ;
;;;;;;;;;;;;
Section "Files"
    SetOutPath  $INSTDIR
    File        "Files\UruLauncher.exe"
    File        "Files\server.ini"
    File        "Files\oalinst.exe"
    File        "Files\OpenAL32.dll"
    File        "Files\wrap_oal.dll"
    File        "Files\vcredist_x86.exe"
    File        "Files\dxwebsetup.exe"
    ExecWait    "$INSTDIR\vcredist_x86.exe /q /norestart"
    ExecWait    "$INSTDIR\oalinst.exe /s"
    ExecWait    "$INSTDIR\dxwebsetup.exe /q"

    WriteRegStr HKCU "Software\Gehn Shard" "" $INSTDIR
    WriteUninstaller "$INSTDIR\Uninstall.exe"

    CreateShortCut  "$SMPROGRAMS\Gehn Shard.lnk" "$INSTDIR\UruLauncher.exe"
SectionEnd

Section "dat"
    StrCmp          $InstallToUru "true" skip_this_step
    CreateDirectory "$INSTDIR\dat"
    CopyFiles       /Silent /FilesOnly "$InstDirUru\dat\*" "$INSTDIR\dat"
    skip_this_step:
SectionEnd

Section "sfx"
    StrCmp          $InstallToUru "true" skip_this_step
    CreateDirectory "$INSTDIR\sfx"
    CopyFiles       /Silent /FilesOnly "$InstDirUru\sfx\*.ogg" "$INSTDIR\sfx"
    skip_this_step:
SectionEnd

; Give everyone permissions to write to the shard folder.
; This is needed because the patcher likes to touch itself.
Section "SetPermissions"
    ExecWait 'cacls "$INSTDIR" /t /e /g "Authenticated Users":c'
SectionEnd

Section "Uninstall"
    Delete "$SMPROGRAMS\Gehn Shard.lnk"
    Delete "$INSTDIR\Uninstall.exe"
    RMDir /r "$INSTDIR"
    DeleteRegKey /ifempty HKCU "Software\Gehn Shard"
SectionEnd
