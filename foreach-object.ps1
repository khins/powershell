# $filepath = 'C:\Users\Kevin\OneDrive'

# Get-ChildItem $filepath -File | ForEach-Object -MemberName {String}

#ForEach (item in collection) {
    # code to execute on each item
#}

#Read more: https://www.sharepointdiary.com/2020/07/powershell-foreach-foreach-object-guide.html#ixzz89zF3ZZVL


#Object
$Employee = [pscustomobject] @{
    Name = "Shan Mathew"
    Designation = "IT Manager"
    Country = "United States"
}

#Get All Properties of the Object
Foreach ($Property in $Employee.PSObject.Properties)
{
    Write-Host "$($Property.Name): $($Property.Value)"
}

#Read more: https://www.sharepointdiary.com/2020/07/powershell-foreach-foreach-object-guide.html#ixzz89zGa45w9

#Get All Files from a Folder
$Files = Get-ChildItem "C:\Users\Kevin\OneDrive\Documents\" | Where { !$_.PSIsContainer }
 
#Print Each File Name in the Console
ForEach ($File in $Files) {
    Write-host $File.Name
}

foreach ($file in $Files){
    Write-Host $File.Name -f Green

}





