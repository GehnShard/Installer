; Installer for Gehn Shard.
; Makes use of the Modern UI for NSIS.

;;;;;;;;;;;;
; Includes ;
;;;;;;;;;;;;
!include MUI2.nsh
!include WinVer.nsh

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
VIAddVersionKey     "FileVersion"       "27"
VIAddVersionKey     "LegalCopyright"    "Guild of Writers"
VIAddVersionKey     "ProductName"       "Gehn Shard"
VIProductVersion    "27.0.0.0"

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
!define MUI_COMPONENTSPAGE_NODESC
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

;;;;;;;;;;;;;
; Languages ;
;;;;;;;;;;;;;
!insertmacro MUI_LANGUAGE "English"

;;;;;;;;;;;;;;;;;
; Install Types ;
;;;;;;;;;;;;;;;;;
InstType           "Typical"
InstType           "Minimal"
InstType           "Complete"
InstType           /NOCUSTOM


;;;;;;;;;;;;
; Sections ;
;;;;;;;;;;;;
Section "-SetPath"
    SetOutPath  $INSTDIR
SectionEnd

Section "Visual C++ Runtime"
    SectionIn   1 2 3 RO

    File        "Files\vcredist_x86.exe"
    ExecWait    "$INSTDIR\vcredist_x86.exe /q /norestart"
SectionEnd

Section "URU Client"
    SectionIn   1 2 3 RO

    File        "Files\UruLauncher.exe"
    File        "Files\repair.ini"
    File        "Files\server.ini"

    WriteRegStr HKCU "Software\Gehn Shard" "" $INSTDIR
    WriteUninstaller "$INSTDIR\Uninstall.exe"

    CreateDirectory "$SMPROGRAMS\Gehn Shard"
    CreateShortCut  "$SMPROGRAMS\Gehn Shard\Gehn Shard.lnk" "$INSTDIR\UruLauncher.exe"
    CreateShortCut  "$SMPROGRAMS\Gehn Shard\Gehn Shard - Repair.lnk" "$INSTDIR\UruLauncher.exe" \
                    "/ServerIni=repair.ini /Repair"
    CreateShortCut  "$SMPROGRAMS\Gehn Shard\Gehn User Profile.lnk" "$LOCALAPPDATA\Uru - Gehn Shard"
    CreateShortCut  "$SMPROGRAMS\Gehn Shard\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
SectionEnd

Section "URU Assets"
    SectionIn   1 3 RO

    StrCmp      $InstallToUru "true" done
    Call        FindUruDir

    ; Check to see if we have a MOULa install. If we do, we'll want to
    ; copy the files. If not, automatically launch a patch-only repair.
    ; This will download just the files from Cyan's MOULa, then quit.
    FindFirst   $0 $1 "$InstDirUru\UruLauncher.exe"
    StrCmp      $1 "" done
    FindClose   $0
    Goto        done

    copy_assets:
    CreateDirectory "$INSTDIR\dat"
    CreateDirectory "$INSTDIR\sfx"
    CopyFiles       /Silent /FilesOnly "$InstDirUru\dat\*" "$INSTDIR\dat"
    CopyFiles       /Silent /FilesOnly "$InstDirUru\sfx\*.ogg" "$INSTDIR\sfx"

    done:
SectionEnd

; Give everyone permissions to write to the shard folder.
; This is needed because the patcher likes to touch itself.
Section "-SetPermissions"
    SectionIn   1 2 3 RO
    ExecWait    'cacls "$INSTDIR" /t /e /g "Authenticated Users":c'
SectionEnd

; This fires up the patcher if we are doing a complete install
Section "Update URU"
    SectionIn   3 RO

    ; We are not using the "/Repair" argument because it will not download the client root.
    ; That was desirable when we were fetching from MOULa, but now we fetch from Gehn itself :)
    ExecWait    "$INSTDIR\UruLauncher.exe /ServerIni=repair.ini /Image /NoSelfPatch /PatchOnly"
SectionEnd

Section "Uninstall"
    RMDir /r "$SMPROGRAMS\Gehn Shard"
    Delete "$INSTDIR\Uninstall.exe"
    RMDir /r "$INSTDIR"
    DeleteRegKey /ifempty HKCU "Software\Gehn Shard"
SectionEnd
