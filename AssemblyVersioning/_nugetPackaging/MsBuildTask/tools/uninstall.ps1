param($installPath, $toolsPath, $package, $project)

$project.Save()

# --- configure names:
$nameForAssemblyInfoFile = "AssemblyInformationalVersion.gen.cs"
$namespaceOfdll = "Nortal.Utilities.AssemblyVersioning"
$nameForDll = $namespaceOfdll + ".dll"
$nameForMSBuildTask = "GenerateExtendedAssemblyInfoTask"
$fullNameForMSBuildTaskFull = $namespaceOfdll + "." + $nameForMSBuildTask
# ---

#remove added files: DLL
$toolsItem = $project.ProjectItems.Item("_tools")
if ($toolsItem) 
{
	$itemToRemove = $toolsItem.ProjectItems.Item($nameForDll)
	try
	{
		Write-Host "Removing dll in _tools folder.. "
		if ($itemToRemove) { $itemToRemove.Delete() }
	}
	catch [Exception]
	{
		Write-Host "_tools/" + $nameForDll + " could not be removed as it is probably used by Visual Studio host. Please remove manually."
	}

	if ($toolsItem.ProjectItems.Count -eq 0)
	{
		Write-Host "Removing empty _tools folder.. "
		$toolsItem.Delete() 
	}
}

#remove added files: generated assembly info file
Write-Host "Removing autogenerated assemblyInfo file.. "
$itemToRemove = $project.ProjectItems.Item("Properties").ProjectItems.Item($nameForAssemblyInfoFile)
if ($itemToRemove) { $itemToRemove.Delete() }

$project.Save()

$xml = [XML] (gc $project.FullName)
$nsmgr = New-Object System.Xml.XmlNamespaceManager -ArgumentList $xml.NameTable
$nsmgr.AddNamespace('p',$xml.Project.GetAttribute("xmlns"))

# --- TASK: undo import of our MSBuild project extension
Write-Host "Removing versioning tooling from project file.."
$ourTargetImport = $xml.Project.SelectSingleNode("//p:Import[@Project='_tools\" + $namespaceOfdll + ".targets']", $nsmgr)
if (!$ourTargetImport)
{
	Write-Host "Removing MsBuild extensions from project file.."
	$ourTargetImport.Delete();
}

$xml.Save($project.FullName)