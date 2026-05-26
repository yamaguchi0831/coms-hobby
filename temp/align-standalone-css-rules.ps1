$folderName = (-join ([char[]](0x30db, 0x30d3, 0x30fc))) + '0520'
$dir = Join-Path ([Environment]::GetFolderPath('Desktop')) $folderName
$htmlPath = Join-Path $dir 'index-standalone-src.html'
$cssPath = Join-Path $dir 'styles.css'
$jsPath = Join-Path $dir 'app.js'

$html = Get-Content -Raw -Encoding UTF8 -LiteralPath $htmlPath
$css = Get-Content -Raw -Encoding UTF8 -LiteralPath $cssPath
$js = Get-Content -Raw -Encoding UTF8 -LiteralPath $jsPath

$classSet = [ordered]@{}
[regex]::Matches($html, 'class="([^"]+)"') | ForEach-Object {
    $_.Groups[1].Value -split '\s+' | Where-Object { $_ } | ForEach-Object {
        if (-not $classSet.Contains($_)) {
            $classSet[$_] = $true
        }
    }
}

function Convert-ClassName([string]$name) {
    if ($name -like 'hb__*') { return $name }
    if ($name -eq 'is-active') { return 'hb__u-is-active' }
    if ($name -like 'container*') { return "hb__l-$name" }

    $componentRoots = @(
        'btn',
        'link',
        'ph',
        'check',
        'tabs',
        'tab'
    )

    foreach ($root in $componentRoots) {
        if ($name -eq $root -or $name.StartsWith("$root--") -or $name.StartsWith("$root" + '__')) {
            return "hb__c-$name"
        }
    }

    if ($name -like 'tag--*') { return "hb__c-$name" }

    return "hb__p-$name"
}

$map = [ordered]@{}
foreach ($name in $classSet.Keys) {
    $map[$name] = Convert-ClassName $name
}

$html = [regex]::Replace($html, 'class="([^"]+)"', {
    param($match)
    $mapped = ($match.Groups[1].Value -split '\s+' | Where-Object { $_ } | ForEach-Object { $map[$_] }) -join ' '
    return "class=""$mapped"""
})

# Remove standalone font imports; base.css/project rules should own font-family.
$html = [regex]::Replace($html, "(?m)^\s*<link rel=""preconnect"" href=""https://fonts\.googleapis\.com"" />\r?\n?", '')
$html = [regex]::Replace($html, "(?m)^\s*<link rel=""preconnect"" href=""https://fonts\.gstatic\.com"" crossorigin />\r?\n?", '')
$html = [regex]::Replace($html, "(?m)^\s*<link href=""https://fonts\.googleapis\.com[^""]+"" rel=""stylesheet"" />\r?\n?", '')

# Remove generated SVG thumbnail template because it is not part of the production component surface.
$html = [regex]::Replace($html, '(?s)\r?\n?<template id="__bundler_thumbnail".*?</template>\r?\n?', "`r`n")

foreach ($old in ($map.Keys | Sort-Object Length -Descending)) {
    $new = $map[$old]
    $escaped = [regex]::Escape($old)
    $css = [regex]::Replace($css, "(?<![\w-])\.$escaped(?![\w-])", ".$new")
    $js = [regex]::Replace($js, "(?<![\w-])\.$escaped(?![\w-])", ".$new")
    $js = $js.Replace("'$old'", "'$new'")
    $js = $js.Replace("""$old""", """$new""")
}

$css = $css -replace 'font-family: "JetBrains Mono", ui-monospace, monospace;', 'font-family: "Noto Sans JP", sans-serif;'
$css = $css -replace 'font-size: 10px;', 'font-size: var(--hb-font-size-caption);'
$css = $css -replace 'font-size: 11px;', 'font-size: var(--hb-font-size-caption);'
$css = $css -replace 'font-size: 13px;', 'font-size: var(--hb-font-size-caption);'
$css = $css -replace 'font-size: 14px;', 'font-size: var(--hb-font-size-caption);'
$css = $css -replace 'font-size: 15px;', 'font-size: var(--hb-font-size-body);'
$css = $css -replace 'transition: transform \.15s ease, box-shadow \.2s ease, background \.2s ease;', 'transition: transform var(--hb-duration-base) var(--hb-ease-base), box-shadow var(--hb-duration-base) var(--hb-ease-base), background var(--hb-duration-base) var(--hb-ease-base);'
$css = $css -replace 'transition: transform \.2s ease, box-shadow \.2s ease;', 'transition: transform var(--hb-duration-base) var(--hb-ease-base), box-shadow var(--hb-duration-base) var(--hb-ease-base);'
$css = $css -replace 'transition: background \.15s ease, color \.15s ease;', 'transition: background var(--hb-duration-base) var(--hb-ease-base), color var(--hb-duration-base) var(--hb-ease-base);'
$css = $css -replace 'border-radius: 50%;', 'border-radius: var(--hb-radius-full);'
$css = $css -replace 'gap: 6px;', 'gap: var(--hb-space-xs);'
$css = $css -replace 'padding: 10px var\(--hb-space-md\);', 'padding: var(--hb-space-xs) var(--hb-space-md);'
$css = $css -replace 'padding: 10px var\(--hb-space-lg\);', 'padding: var(--hb-space-xs) var(--hb-space-lg);'
$css = $css -replace 'margin: 4px 0;', 'margin: var(--hb-space-2xs) 0;'
$css = $css -replace 'padding: 4px 14px;', 'padding: var(--hb-space-2xs) var(--hb-space-md);'
$css = $css -replace 'padding: 4px 10px;', 'padding: var(--hb-space-2xs) var(--hb-space-sm);'
$css = $css -replace 'padding: 3px 10px;', 'padding: var(--hb-space-2xs) var(--hb-space-sm);'
$css = $css -replace 'padding: 4px;', 'padding: var(--hb-space-2xs);'

Set-Content -LiteralPath $htmlPath -Value $html -Encoding UTF8
Set-Content -LiteralPath $cssPath -Value $css -Encoding UTF8
Set-Content -LiteralPath $jsPath -Value $js -Encoding UTF8

[pscustomobject]@{
    ClassesMapped = $map.Count
    Html = $htmlPath
    Css = $cssPath
    Js = $jsPath
}
