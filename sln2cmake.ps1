param(
    [string] $file=$(throw 'sln file is required'),
    [string] $out =$(throw 'out file is required')
)

Set-Variable TEXT_PROJECT_TAG -Option Constant -Value "PROJ:"

$solutionDir = (Split-Path -Parent $file)
Write-Output "Solution Dir: $solutionDir"

rm $out
.\sln2text.ps1 -file $file -out $out

foreach ($line in (Get-Content $out)) {
    if($line.Trim().StartsWith($TEXT_PROJECT_TAG)) {
        $proj = $(Join-Path $solutionDir ($line.Split(",")[1].Trim()));
        Write-Output "Creating cmake projet for: $proj"
        .\vcproj2cmake.ps1 -file $proj -conf Debug
    }
}