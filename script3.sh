names=(sahil kashish ravi krishan)
echo "${names[0]}"
echo " all the names are : ${names[*]}"
echo "the no of entries are : ${#names[*]}"
echo "entries after second are ${names[*]:1:2}"
names+=(hero hero2)

declare -A array2
array2=([1]=sahil [2]=kashish)
echo "the first entry is ${array2[1]}"


