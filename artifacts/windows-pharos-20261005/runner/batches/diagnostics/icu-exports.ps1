$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;
public static class CjguiIcuExports {
  [DllImport("kernel32.dll", CharSet=CharSet.Unicode, ExactSpelling=true, SetLastError=true)]
  public static extern IntPtr LoadLibraryExW(string name, IntPtr file, uint flags);
  [DllImport("kernel32.dll", CharSet=CharSet.Ansi, ExactSpelling=true, SetLastError=true)]
  public static extern IntPtr GetProcAddress(IntPtr module, string name);
  [DllImport("kernel32.dll", CharSet=CharSet.Unicode, ExactSpelling=true, SetLastError=true)]
  public static extern uint GetModuleFileNameW(IntPtr module, StringBuilder path, uint size);
}
'@
$module=[CjguiIcuExports]::LoadLibraryExW('icu.dll',[IntPtr]::Zero,0x00000800)
if($module -eq [IntPtr]::Zero){throw "icu_system_load_failed:win32=$([Runtime.InteropServices.Marshal]::GetLastWin32Error())"}
$path=[Text.StringBuilder]::new(32768)
$length=[CjguiIcuExports]::GetModuleFileNameW($module,$path,[uint32]$path.Capacity)
if(!$length){throw "icu_path_query_failed:win32=$([Runtime.InteropServices.Marshal]::GetLastWin32Error())"}
$names=@('ubrk_open','ubrk_close','ubrk_isBoundary','ubrk_preceding','ubrk_following')
$resolved=@{}
foreach($name in $names){
  if([CjguiIcuExports]::GetProcAddress($module,$name) -ne [IntPtr]::Zero){$resolved[$name]=$name;continue}
  for($version=3;$version -le 99;$version++){
    $candidate="${name}_${version}"
    if([CjguiIcuExports]::GetProcAddress($module,$candidate) -ne [IntPtr]::Zero){$resolved[$name]=$candidate;break}
  }
  if(!$resolved.ContainsKey($name)){$resolved[$name]=$null}
}
[PSCustomObject]@{IcuPath=$path.ToString();Exports=$resolved}|ConvertTo-Json -Depth 4
