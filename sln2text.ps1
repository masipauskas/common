# History
# 

# sln2text - traverses the given visual studio solution and produces a list of projects with its all dependencies

param(
    [string] $file=$(throw 'sln file is required'),
    [string] $out =$(throw 'out file is required')
)

Set-Variable PROJECT_ENTRY_START_TAG -Option Constant -Value 'Project("{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}") ='
Set-Variable PROJECT_ENTRY_END_TAG -Option Constant -Value 'EndProject'
Set-Variable SECTION_ENTRY_START_TAG -Option Constant -Value 'ProjectSection(ProjectDependencies) = postProject'
Set-Variable SECTION_ENTRY_END_TAG -Option Constant -Value 'EndProjectSection'

Function parseProject($line) {
    #Strip out the project tag and remove double quotes
    $cleanedLine = $line.Replace($PROJECT_ENTRY_START_TAG, "").Replace('"','')

    $project = New-Object System.Object
    
    #Parse the project
    $arr = $cleanedLine.Split(",")

    $project | Add-Member -MemberType NoteProperty -Name GUID -Value $arr[2].Trim()
    $project | Add-Member -MemberType NoteProperty -Name Name -Value $arr[0].Trim()
    $project | Add-Member -MemberType NoteProperty -Name File -Value $arr[1].Trim()
    $project | Add-Member -MemberType NoteProperty -Name Dependencies -Value @()

    return $project
}

Function parseDependency($line) {
    $cleanedLine = $line.Trim().Replace('"','')

    $arr = $cleanedLine.Split("=")

    return $arr[0].Trim()
}

$projects = @{}

$currentProject = @()
$currentlyReadingTheProject = $FALSE
$currentlyReadingProjectDependencies = $FALSE

foreach($line in (get-content $file)) {
    if ($line.StartsWith($PROJECT_ENTRY_START_TAG)) {
        $currentProject = parseProject($line)
        $currentlyReadingTheProject = $TRUE
        continue
    }

    if ($line.Trim().Equals($SECTION_ENTRY_START_TAG)) {
        $currentlyReadingProjectDependencies = $TRUE
        continue
    }

    if ($line.Trim().Equals($SECTION_ENTRY_END_TAG)) {
        $currentlyReadingProjectDependencies = $FALSE
        continue
    }

    if ($line.Trim().Equals($PROJECT_ENTRY_END_TAG)) {
        $projects.Add($currentProject.GUID, $currentProject)
        $currentlyReadingTheProject = $FALSE
        continue
    }

    if ($currentlyReadingProjectDependencies) {
        $currentProject.Dependencies = $currentProject.Dependencies + (parseDependency($line))
        continue
    }
}

foreach ($p in $projects.Values) {
    [string]::Format("PROJ: {0}, {1}", $p.Name, $p.File) >> $out
    foreach($d in $p.Dependencies) {
        [string]::Format("  {0}, {1}", $projects[$d].Name, $projects[$d].File) >> $out
    }
}