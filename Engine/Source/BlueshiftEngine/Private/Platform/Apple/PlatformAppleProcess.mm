#include "Precompiled.h"
#include "Platform/PlatformProcess.h"
#include "Core/Str.h"
#include "Core/WStr.h"

BE_NAMESPACE_BEGIN

// get the full path to the running executable
const wchar_t *PlatformAppleProcess::ExecutableFileName() {
	static wchar_t name[512] = L"";
	if (!name[0]) {
		NSString *nsExeName = [[[NSBundle mainBundle] executablePath] lastPathComponent];
		CFStringToWideString((__bridge CFStringRef)nsExeName, name);
	}
	return name;
}

const wchar_t *PlatformAppleProcess::ComputerName() {
	static wchar_t name[256] = L"";
	if (!name[0]) {
		char cname[COUNT_OF(name)];
		gethostname(cname, COUNT_OF(cname));
		WStr::Copynz(name, Str::ToWStr(cname).c_str(), COUNT_OF(name));
	}
	return name;
}

const wchar_t *PlatformAppleProcess::UserName() {
	static wchar_t name[256] = L"";
	if (!name[0]) {
		CFStringToWideString((__bridge CFStringRef)NSUserName(), name);
	}
	return name;
}

BE_NAMESPACE_END