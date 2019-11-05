# Working with list

## [https://stackoverflow.com/questions/44939747/bash-all-of-array-except-last-element](https://stackoverflow.com/questions/44939747/bash-all-of-array-except-last-element)

#### define a list
foo=( 1 2 3 )
#### get the everything in a list except for the first element
echo "${foo[@]:1}"
#### get the everything in a list except for the last element
echo "${foo[@]::${#foo[@]}-1}"
