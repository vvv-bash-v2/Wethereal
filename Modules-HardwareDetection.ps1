# Wethereal Ultimate Edition - Hardware Detection Module
# Detects CPU vendor (Intel/AMD) and ALL installed GPUs (Intel/AMD/NVIDIA, including
# hybrid laptop configurations with an integrated + a discrete GPU) so the rest of the
# tool can automatically adapt which optimizations it offers and applies.

#region CPU Detection

function Get-CPUVendorInfo {
    <#
        Returns a hashtable describing the installed CPU(s):
        Vendor      : "Intel", "AMD", or "Unknown"
        Name        : Friendly CPU name
        Cores       : Physical core count
        Threads     : Logical processor count
        IsHybrid    : $true if the CPU exposes Intel hybrid P-core/E-core topology
    #>
    try {
        $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop | Select-Object -First 1

        $vendor = switch -Regex ($cpu.Manufacturer) {
            'AuthenticAMD' { 'AMD' }
            'GenuineIntel' { 'Intel' }
            default {
                # Fallback to name-based detection if Manufacturer is non-standard
                if ($cpu.Name -match 'AMD|Ryzen|Threadripper|EPYC|Athlon') { 'AMD' }
                elseif ($cpu.Name -match 'Intel|Core\(TM\)|Xeon|Pentium|Celeron') { 'Intel' }
                else { 'Unknown' }
            }
        }

        # Rough hybrid-architecture detection (Intel 12th gen+ P-core/E-core designs)
        $isHybrid = $false
        if ($vendor -eq 'Intel' -and $cpu.Name -match 'i[3579]-1[2-9]\d{2,3}') {
            $isHybrid = $true
        }

        return @{
            Vendor   = $vendor
            Name     = $cpu.Name.Trim()
            Cores    = $cpu.NumberOfCores
            Threads  = $cpu.NumberOfLogicalProcessors
            IsHybrid = $isHybrid
        }
    }
    catch {
        return @{
            Vendor   = 'Unknown'
            Name     = 'Unknown CPU'
            Cores    = 0
            Threads  = 0
            IsHybrid = $false
        }
    }
}

function Get-CPUVendor {
    # Lightweight accessor kept for call sites that only need the vendor string
    return (Get-CPUVendorInfo).Vendor
}

#endregion

#region GPU Detection

function Get-GPUVendorList {
    <#
        Returns an array of hashtables, one per detected video controller, so hybrid
        systems (e.g. Intel iGPU + AMD/NVIDIA dGPU) are fully represented instead of
        only reporting the first adapter found.
        Each entry: Name, Vendor (NVIDIA/AMD/Intel/Unknown), IsActive
    #>
    try {
        $controllers = Get-CimInstance -ClassName Win32_VideoController -ErrorAction Stop
        if (-not $controllers) { return @() }

        $results = @()
        foreach ($gpu in $controllers) {
            $name = $gpu.Name
            if ([string]::IsNullOrWhiteSpace($name)) { continue }
            $nameLower = $name.ToLower()

            $vendor = if ($nameLower -match 'nvidia|geforce|quadro|\bgtx\b|\brtx\b') {
                'NVIDIA'
            }
            elseif ($nameLower -match 'amd|radeon|\brx\b|firepro|vega') {
                'AMD'
            }
            elseif ($nameLower -match 'intel|uhd|iris|hd graphics') {
                'Intel'
            }
            else {
                'Unknown'
            }

            # A controller with a non-zero current refresh rate / bpp is the one
            # actively driving a display; adapters at 0 are typically idle/disabled.
            $isActive = $gpu.CurrentBitsPerPixel -gt 0 -or $gpu.Status -eq 'OK'

            $results += @{
                Name     = $name.Trim()
                Vendor   = $vendor
                IsActive = $isActive
            }
        }

        return $results
    }
    catch {
        return @()
    }
}

function Get-GPUVendor {
    <#
        Backward-compatible accessor: returns the vendor of the PRIMARY GPU
        (first active adapter, or first adapter if none report as active).
        Kept because Show-Header, startup banner and the HTML report only need
        a single headline vendor string.
    #>
    $gpus = Get-GPUVendorList
    if ($gpus.Count -eq 0) { return 'Unknown' }

    $active = $gpus | Where-Object { $_.IsActive } | Select-Object -First 1
    if ($active) { return $active.Vendor }
    return $gpus[0].Vendor
}

#endregion

#region Unified Hardware Profile

function Get-HardwareProfile {
    <#
        Builds (and caches on $Script:Hardware) a complete picture of the machine:
        CPU vendor/name, every GPU detected, whether this is a hybrid multi-GPU
        system, and the distinct set of GPU vendors present. Every optimization
        function that needs to branch by vendor should read from this instead of
        re-querying WMI/CIM each time.
    #>
    param([switch]$Refresh)

    if ($Script:Hardware -and -not $Refresh) {
        return $Script:Hardware
    }

    $cpu = Get-CPUVendorInfo
    $gpus = Get-GPUVendorList
    $gpuVendors = @($gpus | ForEach-Object { $_.Vendor } | Where-Object { $_ -ne 'Unknown' } | Select-Object -Unique)

    $Script:Hardware = @{
        CPU           = $cpu
        GPUs          = $gpus
        GPUVendors    = $gpuVendors
        IsHybridGPU   = ($gpuVendors.Count -gt 1)
        PrimaryGPU    = if ($gpus.Count -gt 0) { $gpus[0] } else { $null }
    }

    return $Script:Hardware
}

function Show-HardwarePlatformSummary {
    <#
        Human-readable one-liner used by the startup banner, e.g.:
        "AMD Ryzen 9 7900X + AMD Radeon RX 7900 XTX (single-vendor AMD platform)"
    #>
    $hw = Get-HardwareProfile

    $cpuLabel = "$($hw.CPU.Vendor) CPU"
    if ($hw.GPUVendors.Count -eq 0) {
        $gpuLabel = "no discrete/integrated GPU detected"
    }
    elseif ($hw.GPUVendors.Count -eq 1) {
        $gpuLabel = "$($hw.GPUVendors[0]) GPU"
    }
    else {
        $gpuLabel = "hybrid GPU setup ($($hw.GPUVendors -join ' + '))"
    }

    return "$cpuLabel / $gpuLabel"
}

#endregion
