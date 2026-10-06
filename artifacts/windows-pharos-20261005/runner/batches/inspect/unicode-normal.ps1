[PSCustomObject]@{ Marker='正常消费'; Cjk='编辑器'; ProcessArchitecture=if ([IntPtr]::Size -eq 8) {'x64'} else {'x86'}; Path=(Get-Location).Path } | ConvertTo-Json -Compress
