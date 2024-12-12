; Mouse Miscellaneous Utility - v0.1.3pre
; -------------------------------
; Google search, translate, picture, lens(WIP)
; Bonus: X-Mouse settings
; -------------------------------
; Copyright(c) 2023 Shadow912kage@gmail.com (MURASE, Takashi)
; Released under the MIT license
; http://www.opensource.org/licenses/mit-license.php

/*=====================================================================
 This script should be used in conjunction with a multi-button mouse.
 Please assign [F19]-[F24] keys to mouse buttons.
-----------------------------------------------------------------------
[F19] Maximize window
[F20] Minimize window
[F21] (WIP... Run Snipping Tool and Google Lens)
[F22] Google Image search for the selected text
[F23] Translate selected text with Google
[F24] Search Google for the selected text
=====================================================================*/

;;; My indentation coding style is two spaces.

; AutoHotKey 2.0 configuration
#Requires AutoHotkey v2.0
#Warn ; Enable warnings to assist with detecting common errors.
#SingleInstance force ; Determines whether a script is allowed to run again when it is already running.
#UseHook False ; Using the keyboard hook is usually preferred for hotkeys - but here we only need the mouse hook.
InstallMouseHook
A_MaxHotkeysPerInterval := 1000 ; Avoids warning messages for high speed wheel users.
SendMode "Input" ; Recommended for new scripts due to its superior speed and reliability.

TraySetIcon "mouse.png" ; Icon source from https://icooon-mono.com/
A_IconTip := "Mouse Misc. Utility v0.1.3pre" ; Go to Google Lens: WIP

/* X Mouse
https://elmony.gitlab.io/posts/2020/20200222_userpreferencesmask.html
=====
[HKEY_CURRENT_USER\Control Panel\Desktop]
"ActiveWndTrkTimeout"=dword:00000064
"UserPreferencesMask"=hex:91,00,27,80,10,00,00,00
-----
# UserPreferencesMask = 90,12,07,80,10,00,00,00 の場合で説明
# 先頭1バイト: 0x90
0x90(1001 0000)
Bit00 Active window tracking: 0
Bit01 Menu animation: 0
Bit02 Slide open combo boxes (Combo box animation): 0
Bit03 Smooth-scroll list boxes (List box smooth scrolling): 0 
Bit04 Gradient captions: 1 
Bit05 Keyboard cues): 0
Bit06 Active window tracking Z order: 0
Bit07 Hot tracking: 1
*/

; Registry handling for X Mouse
RegKey := "HKCU\Control Panel\Desktop"
RegValUPrefMask := "UserPreferencesMask"
RegValAWndTrkTout := "ActiveWndTrkTimeout"
XMFlgBitMsk := 0x0100000000000000
OnStartUPMaskStr := 0
OnStartAWTToutStr := 0
GetUPMaskAWTTout(&UPMask, &AWTTout) ; Get registory values of "UserPreferencesMask" and "ActiveWndTrkTimeout"
{
	global RegKey, RegValUPrefMask, RegValAWndTrkTout
	UPMask := RegRead(RegKey, RegValUPrefMask)
	AWTTout := RegRead(RegKey, RegValAWndTrkTout, "")
}
GetXMouseFlag(UPMask) ; Get X Mouse flag
{
	Global XMFlgBitMsk
	Return (XMFlgBitMsk & Integer("0x" UPMask))?True:False
}
SetUPMaskAWTTout(UPMask, AWTTout) ; Set registory values of "UserPreferencesMask" and "ActiveWndTrkTimeout"
{
	global RegKey, RegValUPrefMask, RegValAWndTrkTout
	RegWrite UPMask, "REG_BINARY", RegKey, RegValUPrefMask
	RegWrite AWTTout, "REG_DWORD", RegKey, RegValAWndTrkTout
}
GetUPMask(UPMask, XMFlag) ; Get X Mouse flag
{
	Global XMFlgBitMsk
	If XMFlag
		Return Format("{:X}", XMFlgBitMsk | Integer("0x" UPMask))
	Else
		Return Format("{:X}", ~XMFlgBitMsk & Integer("0x" UPMask))
}

; Get default values from registory.
GetUPMaskAWTTout(&OnStartUPMaskStr, &OnStartAWTToutStr)
DfltXMFlag := GetXMouseFlag(OnStartUPMaskStr)
DfltAWTTout := OnStartAWTToutStr

; X Mouse's menu and dialog
A_TrayMenu.Add() ; Add a separator line to AutoHotKey's menu
A_TrayMenu.Add("X Mouse settings", ConfXMouseFnc) ; Add menu item to AutoHotKey's menu

; X Mouse's Gui object
ConfXMouseGui := Gui("ToolWindow", "X Mouse")
;iconsize := 32
;hIcon := LoadPicture("mouse.ico", "Icon1 w" iconsize " h" iconsize, &imgtype)
;SendMessage(0x0080, 1, hIcon, ConfXMouseGui)
ConfXMouseGui.OnEvent("Close", CnclFncXMouse)
ConfXMEnbCkBx := ConfXMouseGui.Add("CheckBox", "vEnbXMouse", "The Activate and focus the window when the mouse hovers it.")
ConfXMEnbCkBx.Value := DfltXMFlag
ConfXMouseGui.Add("Text", "section xp+16 y+10", "The delay time of active and focus (1-1000) [msec]:")
ConfXMouseGui.Add("Edit")
ConfXMDlyTime := ConfXMouseGui.Add("UpDown", "vDlTXMouse Range1-1000", DfltAWTTout)
ConfXMouseGui.Add("Text", "xm", "If you change the settings, It becomes effective after restarting Windows.")
OkBtnConfXMouse := ConfXMouseGui.Add("Button", "Default w80 section", "Ok")
OkBtnConfXMouse.OnEvent("Click", OkFncXMouse)
ConfXMouseGui.Add("Text", "ys+5", "Store changed settings")
CnclBtnConfXMouse := ConfXMouseGui.Add("Button", "w80 section xm y+10", "Cancel")
CnclBtnConfXMouse.OnEvent("Click", CnclFncXMouse)
ConfXMouseGui.Add("Text", "ys+5", "Discard changed settings")
DfltBtnConfXMouse := ConfXMouseGui.Add("Button", "w80 section xm y+10", "Default")
DfltBtnConfXMouse.OnEvent("Click", DfltFncXMouse)
ConfXMouseGui.Add("Text", "ys+5", "Load default (on the start) settings")

SavedXMouse := ConfXMouseGui.Submit() ; Create initial saved Gui object

; X Mouse's callback functions: Ok/Cancel/Default button, Menu item
OkFncXMouse(*)
{
	Global
	SavedXMouse := ConfXMouseGui.Submit()
	SetUPMaskAWTTout(GetUPMask(OnStartUPMaskStr, SavedXMouse.EnbXMouse), SavedXMouse.DlTXMouse)
}
CnclFncXMouse(*)
{
	Global
	ConfXMEnbCkBx.Value := SavedXMouse.EnbXMouse
	ConfXMDlyTime.Value := SavedXMouse.DlTXMouse
	ConfXMouseGui.Submit()
}
DfltFncXMouse(*)
{
	Global
	ConfXMEnbCkBx.Value := DfltXMFlag
	ConfXMDlyTime.Value := DfltAWTTout
}
ConfXMouseFnc(*)
{
	Global
	ConfXMouseGui.Show()
}
; ***** End of X Mouse *****

; This script configuration
CBWT := 0.5 ; Clipboard Waiting Time[sec]
SSQU := "https://www.google.com/search?q=" ; Search Site Query URL
TSQU := "https://translate.google.com/?text=" ; Translate Site Query URL
TSQO := "&sl=auto&tl=ja&op=translate" ; Translate Site Query Option
PSQO := "&tbm=isch" ; Picture Search Query Option

; window control
F19::WinMaximize "A"
F20::WinMinimize "A"

; mouse button's hotkeys
ClipSaved := ""
SaveClipBd()
{
  global ClipSaved := ClipboardAll() ; Save the entire clipboard to a variable of your choice.
  A_Clipboard := "" ; Start off empty to allow ClipWait to detect when the text has arrived.
}
RstrClipBd()
{
  global ClipSaved
  A_Clipboard := ClipSaved ; Restore the original clipboard. Note the use of A_Clipboard (not ClipboardAll).
  ClipSaved := "" ; Free the memory in case the clipboard was very large.
}

; Please assign the following hotkeys to the optional buttons of the mouse.
;; Search selected text, using a clipboard as a temporary
F24::
{
  global CBWT, SSQU

  SaveClipBd()
  Send "^c"
  If ClipWait(CBWT) ; Wait for the clipboard to contain text.
    Run SSQU A_Clipboard
  RstrClipBd()
}
;; Tranlate selected text, using a clipboard as a temporary
F23::
{
  global CBWT, TSQU, TSQO

  SaveClipBd()
  Send "^c"
  If ClipWait(CBWT) ; Wait for the clipboard to contain text.
    Run TSQU A_Clipboard TSQO
  RstrClipBd()
}
;; Search Picture with selcted text, using a Clipboard as a temporary
F22::
{
  global CBWT, TSQU, PSQO

  SaveClipBd()
  Send "^c"
  If ClipWait(CBWT) ; Wait for the clipboard to contain text.
    Run SSQU A_Clipboard PSQO
  RstrClipBd()
}
;; Run Snipping Tool and Google Lens
F21::
{
	OnClipboardChange GetImgGoLens
	Win10Oct2018 := ">=10.0.17763" ; Version numbper of Windows 10 October 2018 Update or later,
																 ; Snip & Sketch was implemented.
	If VerCompare(A_OSVersion, Win10Oct2018)
		Send "#+s" ; Run Snip & Sketch(Win10) or Snipping Tool(Win11), Image format is PNG
	Else
		Run "snippingtool" ; Run Snipping Tool(Win7/8/8.1), Image format is BMP
}

;; ==========
; Snip & Sketch's data format(PNG), Byte order
; 00-31: Clipboard Snip & Sketch signature?:
;        0x09 0xC0 0x00 0x00 0x08 0x00 0x00 0x00
;        0x36 0x07 0x08 0x00 0x00 0x00 0x00 0x00
;        0xC9 0xC0 0x00 0x00 0x04 0x00 0x00 0x00
;        0x01 0x00 0x00 0x00 0x3A 0xC1 0x00 0x00
; 32-35: unknown, variable
; 36-43: PNG signature: 0x89 0x50(P) 0x4E(N) 0x47(G) 0x0D(\r) 0x0A(\n) 0x1A(EOF) 0x0A(\n)
; 44-47: chunk size: 0x00 0x00 0x00 0x0D(13 bytes)
; 48-51: chunk name: 0x49 0x48 0x44 0x52(IHDR)
; 52-55: image width pixels
; 56-59: image height pixels
;    60: color depth: 0x08
;    61: color type: 0x06
;    62: compression type: 0x00
;    63: filter type: 0x00
;    64: interlace type: 0x00
; 65-68: CRC
;   :
; The remaining chunks follow: sRGB, gAMA, pHYs, IDAT, and IEND
;; ==========

;/*
DebugLog := ""
^F2::
{ ; use DebugLog for printf debugging
	Global
	MsgBox DebugLog
	DebugLog := ""
}
ToHexPadZero(num, bytes, type)
{
	hexnum := Format("{:X}", num)
	hexnumlen := StrLen(hexnum)
	If (degits := bytes*2 - hexnumlen) > 0
	{
	  While(degits--)
		  pad .= "0"
		hexnum := pad . hexnum
	}
	Else If Mod(hexnumlen, 4) && Mod(hexnumlen, 2)
	{
		If (hexnumlen > 4) && (degits := 4 - Mod(hexnumlen, 4))
		{
			While(degits--)
				pad .= "0"
			hexnum := pad . hexnum
		}
		Else If degits := 2 - Mod(hexnumlen, 2)
		{
			While(degits--)
				pad .= "0"
			hexnum := pad . hexnum
		}
	}
	Switch(type)
	{
		case 1:
			hexnum := "0x" . hexnum
		case 2:
			hexnum := " 0x" . hexnum
	}
	Return hexnum
}
;*/
;; ==========
;; ----------
GetImgGoLens(type)
{
	Global DebugLog
	If type = 2 ; Clipboard data is image
	{
		ImgObj := ClipboardAll()
		pointer := ImgObj.Ptr
		rawsize := ImgObj.Size
		pictype := NumGet(pointer, 0, "UInt")
		blksize := NumGet(pointer, 4, "UInt")
		DebugLog := "Image data ptr adr: " ImgObj.Ptr "(" ToHexPadZero(ImgObj.Ptr, 0, 1) ")`n"
		DebugLog .= "Image raw data size: " ImgObj.Size "(" ToHexPadZero(ImgObj.Size, 0, 1) ")`n"
		DebugLog .= "Data type: " NumGet(pointer, 0, "UInt") "(" ToHexPadZero(NumGet(pointer, 0, "UInt"), 0, 1) ")`n"
		DebugLog .= "Data block size: " NumGet(pointer, 4, "UInt") "(" ToHexPadZero(NumGet(pointer, 4, "UInt"), 0, 1) ")`n"
		If (pictype = 0xC009) && (blksize = 0x0008)
			ImgDat := GetImgDataPNG(pointer, rawsize)
		If (pictype = 0x0002) || (pictype = 0x0008)
			ImgDat := GetImgDataBMP(pointer, pictype)
		SendGLens(ImgDat)
		ImgObj := ""
		ImgDat := ""
	}
	OnClipboardChange GetImgGoLens, 0
}
;; ==========
;; Get big-endian number
;; ----------
GetBgEdNum(p, bytes)
{
	i := 0
	num := 0
	While(i < bytes)
	{
		num <<= 8
		num += NumGet(p, i, "UChar")
		i++
	}
	Return num
}
;; ==========
;; Copy memory to dst form src
;; ----------
CpyBuf(src, dst, bytes)
{
	i := 0
	While(i < bytes)
	{
		NumPut("UChar",  NumGet(src, i, "UChar"), dst, i)
		i++
	}
}

;; ==========
;; Get PNG image data from clipboard
;; ----------
GetImgDataPNG(p, size)
{
	p += 36 ; Add Clipboard signature's(?) size
	size -= 36 ; Decrement a same size
	ImgDat := Buffer(size)
	CpyBuf(p, ImgDat, size)
	If !(d := IsPNGSig(p))
		Return False
	p += d
	If !(d := ChkChunks(p))
		Return False
	p += d
	Return ImgDat
}
;; ==========
;; Check a PNG signature
;; ----------
IsPNGSig(p)
{
  ;PNG signature: 0x89    'P'   'N'   'G'  '\r'  '\n'  EOF   '\n'
	PNGSig := Array(0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A)
	i := 0
	While(i < 8)
	{
		If (NumGet(p, i, "UChar") != PNGSig[i+1])
			Return 0 ; NOT PNG signature
		i++
	}
	Return i ; Return read bytes number
}
;; ==========
;; Check each chunks
;; ----------
ChkChunks(p)
{ ; Snip & Sketch PNG chunks are IHDR, sRGB, gAMA, pHYs, IDAT, and IEND.
	porig := p
	cname := ""
	While (cname != "IEND")
	{
		size := GetBgEdNum(p, 4)
		p += 4
		cname := StrGet(p, 4, 0)
		p += 4 + size
		crc := GetBgEdNum(p, 4)
		p += 4
	}
	Return (p - porig)
}

;; ==========
;; Get Windows BMP data from clipboard buffer
;; ----------
;; ImgDat := GetImgDataBMP(pointer, type)
;; Params pointer(Integer): source pointer, type: BMP type (only 8)
;; Return ImgDat(Buffer): BMP data
;; ----------
;; Reference:
;;   BMP file format - Wikipedia https://en.wikipedia.org/wiki/BMP_file_format
GetImgDataBMP(p, type)
{ ; type = 8:
  ;   Clipboard BMP data does not include the BITMAPFILEHEADER.
  ;   That data starts with a BITMAPINFOHEADER.
	;   Below is a 24-bit 'bit mask' block without an alpha channel(like a 256*8.8.8.0.0/RGB24).
	;   Next is the 'bitmap data' block.
	;   Each pixel has 32 bits. The byte order is blue, green, red, and alpha channel, and
	;   an alpha channel value is always 0xFF(8.8.8.8.0/ARGB32).
	; Windows BMP format on the Paint application(pbrush):
	;   BITMAPFILEHEADER(14 bytes), BITMAPINFOHEADER(40 bytes), no 'bit mask' block, and the 'bitmap data' block(8.8.8.0.0/RGB24).
	If type != 8
	{
		MsgBox "Sorry! BMP type: " type " format is unsupported."
		Return False
	}
	p += 8 ; Add a number of clipboard data types and block size bytes.
	BMPInfo := Object() ; for BMPInfoHeader
	BMPFile := Object() ; for BMPFileHeader
	p := GetBMPInfoHeader(p, BMPInfo, BMPFile)
	If !(BMPInfo)
		Return False
	BitMasksShifts := Map()
	p := GetBMPBitMsks(p, BitMasksShifts)
	ImgDat := Buffer(BMPFile.FileSize, 0)
	; BMPFileHeader
	NumPut("Char", 0x42, ImgDat, 0) ; 'B'
	NumPut("Char", 0x4D, ImgDat, 1) ; 'M'
	NumPut("UInt", BMPFile.FileSize, ImgDat, 2)
	NumPut("UInt", BMPFile.Offset, ImgDat, 10)
	; BMPInfoHeader
	NumPut("UInt", BMPInfo.HeaderSize, ImgDat, 14)
	NumPut("Int", BMPInfo.Width, ImgDat, 18)
	NumPut("Int", BMPInfo.Height, ImgDat, 22)
	NumPut("UShort", 1, ImgDat, 26)
	NumPut("UShort", BMPInfo.BitsPerPx, ImgDat, 28)
	NumPut("UInt", BMPInfo.DataSize, ImgDat, 34)
	; BMP pixel data
	dst := ImgDat.Ptr + BMPFile.Offset
	Loop BMPInfo.Height
	{
		Loop BMPInfo.Width
		{
			p := GetBMPPixelData(p, BitMasksShifts, &R, &G, &B)
			dst := SetBMPPixelData(dst, R, G, B)
		}
		dst += BMPInfo.LinePadding
	}
	Return ImgDat
}
;; ==========
;; Get BMPInfoHeader data and create BMPFileHeader data
;; pointer := GetBMPInfoHeader(pointer, BMPInfo, BMPFile)
;; ----------
;; 	Params pointer(Integer): source pointer, BMPInfo(Buffer): BMPInfoHeader, BMPFile(Buffer): BMPFileHeader
;; 	Return pointer(Integer): incremented pointer
GetBMPInfoHeader(pointer, BMPInfo, BMPFile)
{
	If (BMPInfo.HeaderSize := NumGet(pointer, 0, "UInt")) != 40 ; BITMAPINFOHEADER Size
		Return 0
	BMPInfo.Width := NumGet(pointer, 4, "Int") ; NOTICE! Signed INT
	BMPInfo.Height := NumGet(pointer, 8, "int") ; NOTICE! Signed INT
	BMPInfo.BitsPerPxRaw := NumGet(pointer, 14, "UShort")
	BMPInfo.BitsPerPx := BMPInfo.BitsPerPxRaw - 8
	BMPInfo.BytesPerPxRaw := Integer(BMPInfo.BitsPerPxRaw/8)
	BMPInfo.BytesPerPx := BMPInfo.BytesPerPxRaw  - 1
	BMPInfo.LinePadding := ((linemod := Mod(BMPInfo.BytesPerPx*BMPInfo.Width, 4))?(4 - linemod):0)
	BMPInfo.BytesPerLine := BMPInfo.BytesPerPx*BMPInfo.Width + BMPInfo.LinePadding
	BMPInfo.DataSizeRaw := NumGet(pointer, 20, "UInt") ; This value is 4*Width*Height
	BMPInfo.DataSize := BMPInfo.BytesPerLine*BMPInfo.Height ; Real BMP size is (3*Width + Padding)*Height
	BMPFile.Offset := 14 + BMPInfo.HeaderSize ; Offset addr of BMP data
	BMPFile.FileSize := BMPFile.Offset + BMPInfo.DataSize ; BMP file size
	Return (pointer + BMPInfo.HeaderSize) ; Add a number of BMPInfoHeader size
}
;; ==========
;; Get BMP bitmasks and bit-shifts data and shift width data of a each bitmask
;; Bit mask of 24-bits (4 bytes x 3).  The bitmask order is R, G, and B w/o the Alpha channel.
;; ----------
;; pointer := GetBMPBitMsks(pointer, BitMasksShifts)
;; 	Params pointer(Integer): source pointer, BitMasksShifts(Map): bitmasks and bit shift width data.
;;         BitMasksShifts := Object() with properties mask bits (.Mask) and shift width (.Shift)
;; 	Return pointer(Integer): incremented pointer
GetBMPBitMsks(pointer, BitMasksShifts)
{
	coder := ["R", "G", "B"]
	i := 1
	offset := 0
	Loop 3
	{
		BitMasksShifts[coder[i]] := Object()
		BitMasksShifts[coder[i]].Mask := NumGet(pointer, offset, "UInt")
		j := 0
		Loop 24
		{
			If (BitMasksShifts[coder[i]].Mask >> j) & 1
				Break
			j++
		}
		BitMasksShifts[coder[i]].Shift := j
		i++
		offset += 4
	}
	Return (pointer + 12) ; Add a number of bit mask size
}
;; ==========
;; Get BMP data from Clipboard buffer
;; ----------
;; pointer := GetBMPPixelData(pointer, BitMasksShifts, &R, &G, &B)
;;  params pointer(Integer): source pointer, BitMasksShifts(Map): bitmasks and bit shift width data.
;;         BitMasksShifts := Object() with properties mask bits (.Mask) and shift width (.Shift)
;;         &R, &G, &B: stored pixel data about each color
;; 	Return pointer(Integer): incremented pointer
GetBMPPixelData(pointer, BitMasksShifts, &R, &G, &B)
{
	rawdata := NumGet(pointer, 0, "UInt")
	R := (BitMasksShifts["R"].Mask & rawdata) >> BitMasksShifts["R"].Shift
	G := (BitMasksShifts["G"].Mask & rawdata) >> BitMasksShifts["G"].Shift
	B := (BitMasksShifts["B"].Mask & rawdata) >> BitMasksShifts["B"].Shift
	Return (pointer + 4) ; Add a size of "UInt" (4 bytes: R ,G, B, Alpha channel)
}
;; ==========
;; Set Windows BMP data to Buffer
;; ----------
;; pointer := SetBMPPixelData(pointer, R, G, B)
;;  Params pointer(Integer): destination pointer, R, G, B: pixel data about each color
;; 	Return pointer(Integer): incremented pointer
SetBMPPixelData(pointer, R, G, B)
{
	NumPut("UChar",  B, pointer, 0)
	NumPut("UChar",  G, pointer, 1)
	NumPut("UChar",  R, pointer, 2)
	Return (pointer + 3) ; Add a number of BMP pixel size (3 bytes: R, G, B)
}

;; ==========
;; ----------
SendGLens(buffer)
{
	FileDelete "test.png"
	FileAppend buffer, "test.png", "raw"
}
/* AHK
whr := ComObject("WinHttp.WinHttpRequest.5.1")
whr.Open("GET", "https://www.autohotkey.com/download/2.0/version.txt", true)
whr.Send()
; Using 'true' above and the call below allows the script to remain responsive.
whr.WaitForResponse()
version := whr.ResponseText
MsgBox version
*/

/*
Method: POST https://lens.google.com/v3/upload?ssb=1&cpe=1&&hl=ja&re=df&st=1685963099451&plm=ChAIARIMCNuC96MGEIDpydYB&vpw=1920&vph=1057&ep=gisbubb

Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7
Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryQdIQhatKnZi67zD6
DNT: 1
Sec-Fetch-Dest: document
Sec-Fetch-Mode: navigate
Sec-Fetch-Site: cross-site
Sec-Fetch-User: ?1
Upgrade-Insecure-Requests: 1
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36
X-Client-Data: CI22yQEIo7bJAQipncoBCNrkygEIlqHLAQjPms0BCKyczQEIhaDNAQiSps0BCIenzQEIr6rNAQi2ss0BCNSzzQEI2rTNAQicuc0B
sec-ch-ua: "Not.A/Brand";v="8", "Chromium";v="114", "Google Chrome";v="114"
sec-ch-ua-arch: "x86"
sec-ch-ua-bitness: "64"
sec-ch-ua-full-version: "114.0.5735.91"
sec-ch-ua-full-version-list: "Not.A/Brand";v="8.0.0.0", "Chromium";v="114.0.5735.91", "Google Chrome";v="114.0.5735.91"
sec-ch-ua-mobile: ?0
sec-ch-ua-model: ""
sec-ch-ua-platform: "Windows"
sec-ch-ua-platform-version: "10.0.0"
sec-ch-ua-wow64: ?0
=====
Method: POST https://lens.google.com/v3/upload?ssb=1&cpe=1&&hl=ja&re=df&st=1685963099451&plm=ChAIARIMCNuC96MGEIDpydYB&vpw=1920&vph=1057&ep=gisbubb
Status: 200 - OK

accept-ch: Sec-CH-UA-Arch, Sec-CH-UA-Bitness, Sec-CH-UA-Full-Version, Sec-CH-UA-Full-Version-List, Sec-CH-UA-Model, Sec-CH-UA-WoW64, Sec-CH-UA-Form-Factor, Sec-CH-UA-Platform, Sec-CH-UA-Platform-Version
alt-svc: h3=":443"; ma=2592000,h3-29=":443"; ma=2592000
cache-control: no-cache, no-store, max-age=0, must-revalidate
content-encoding: gzip
content-security-policy: require-trusted-types-for 'script';report-uri /_/LensWebStandaloneUi/cspreport
content-security-policy: script-src 'report-sample' 'nonce-ATtGkVkO4E4ZmmMlhSi5QA' 'unsafe-inline';object-src 'none';base-uri 'self';report-uri /_/LensWebStandaloneUi/cspreport;worker-src 'self'
content-security-policy: script-src 'unsafe-inline' 'self' https://apis.google.com https://ssl.gstatic.com https://www.google.com https://www.googletagmanager.com https://www.gstatic.com https://www.google-analytics.com https://www.googleapis.com/appsmarket/v2/installedApps/;report-uri /_/LensWebStandaloneUi/cspreport/allowlist
content-type: text/html; charset=utf-8
cross-origin-opener-policy: same-origin
cross-origin-resource-policy: cross-origin
date: Mon, 05 Jun 2023 11:04:59 GMT
expires: Mon, 01 Jan 1990 00:00:00 GMT
permissions-policy: ch-ua-arch=*, ch-ua-bitness=*, ch-ua-full-version=*, ch-ua-full-version-list=*, ch-ua-model=*, ch-ua-wow64=*, ch-ua-form-factor=*, ch-ua-platform=*, ch-ua-platform-version=*
pragma: no-cache
server: ESF
x-content-type-options: nosniff
x-frame-options: DENY
x-ua-compatible: IE=edge
x-xss-protection: 0
=====
https://lens.google.com/search?ep=gisbubb&hl=ja&re=df&p=ATHekxceQjtoasvxGaYxNCIrjQqqEBsh3psXAGKGyN8vT8TQWDGlKJlR-O0K8fPHKoAfu25cFFltsMlwaxVIDURd_5prjdRBe5tPGF0wEBYfu_5ToqOY7RqoV00VnmTgGQhPJXEgOtUMMjMvxBCkAEaMXSZhNSg-qbUpHQHpUe03KFH2MZlZg0nLbkWLpOZ18o7kdK7KUm313zSOe4DJzmkPUGaA25aeJ3p74HDZBStlmeppjDCBxc7aVQE2zkwXCSC68KtFNKQDcuifAhrzvqpSEsrl0lbII1tMIzJe3ybs7y2QVQFTIQ%3D%3D#lns=W251bGwsbnVsbCxudWxsLG51bGwsbnVsbCxudWxsLG51bGwsIkVrY0tKRE5pTWpFeE5HRTRMVEJoTVRVdE5EWTRaaTA0WVdVM0xXTTJPV001Tmpaa056VXdPQklmVFhsc1pscElUalJCVkZGV2QwMURZVjlYYUdaVlQxWjFYMUkyTUdsQ1p3PT0iXQ==
*/
/* ; don't work?
Image search:  http://www.google.com/searchbyimage?image_url=$LINK&sbisrc=ap
*/
