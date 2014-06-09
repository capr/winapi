--proc/monitor: multi-monitor API
setfenv(1, require'winapi')
require'winapi.winuser'

ffi.cdef[[
HMONITOR MonitorFromPoint(POINT pt, DWORD dwFlags);
HMONITOR MonitorFromRect(LPCRECT lprc, DWORD dwFlags);
HMONITOR MonitorFromWindow(HWND hwnd, DWORD dwFlags);

typedef struct tagMONITORINFO
{
    DWORD   cbSize;
    RECT    monitor_rect;
    RECT    work_rect;
    DWORD   dwFlags;
} MONITORINFO, *LPMONITORINFO;

typedef struct tagMONITORINFOEXW
{
    MONITORINFO;
    WCHAR       szDevice[32];
} MONITORINFOEXW, *LPMONITORINFOEXW;

BOOL GetMonitorInfoW(HMONITOR hMonitor, LPMONITORINFOEXW lpmi);
typedef BOOL (* MONITORENUMPROC)(HMONITOR, HDC, LPRECT, LPARAM);

BOOL EnumDisplayMonitors(
     HDC hdc,
     LPCRECT lprcClip,
     MONITORENUMPROC lpfnEnum,
     LPARAM dwData);
]]

MONITOR_DEFAULTTONULL     = 0x00000000
MONITOR_DEFAULTTOPRIMARY  = 0x00000001
MONITOR_DEFAULTTONEAREST  = 0x00000002

MONITORINFOF_PRIMARY = 0x00000001 --the only flag in dwFlags

MONITORINFOEX = struct{ctype = 'MONITORINFOEXW', size = 'cbSize',
	fields = sfields{
		'flags', 'dwFlags', flags, pass,
	}
}

function MonitorFromPoint(pt, mflags)
	return checkh(C.MonitorFromPoint(POINT(pt), flags(mflags)))
end

function MonitorFromRect(rect, mflags)
	return checkh(C.MonitorFromRect(RECT(rect), flags(mflags)))
end

function MonitorFromWindow(hwnd, mflags)
	return checkh(C.MonitorFromWindow(hwnd, flags(mflags)))
end

function GetMonitorInfo(hmonitor, info)
	info = MONITORINFOEX(info)
	checknz(C.GetMonitorInfoW(hmonitor, info))
	return info
end

function EnumDisplayMonitors(hdc, cliprect)
	local t = {}
	local cb = ffi.cast('MONITORENUMPROC', function(hmonitor, hdc, vrect)
		table.insert(t, hmonitor)
		return 1 --continue
	end)
	local ret = C.EnumDisplayMonitors(hdc, cliprect, cb, 0)
	cb:free()
	checknz(ret)
	return t
end


if not ... then
	for i,monitor in ipairs(EnumDisplayMonitors()) do
		local info = GetMonitorInfo(monitor)
		print(i, info.monitor_rect, info.work_rect)
	end
end
