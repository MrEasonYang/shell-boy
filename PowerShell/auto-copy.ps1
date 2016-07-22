param($From, $To, $Suffix)
$data = Dir $From -filter *.$Suffix -recurse
$data | Foreach-Object{
    echo $_.Name
    Copy-Item $_.FullName $To
}
