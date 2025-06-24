#!/usr/bin/bash

isPerlInstalled(){
  which perl > /dev/null
  if [  "${?}" != 0 ]; then
    echo "Perl is required to run this script"
    exit 1
  fi
}

isXMLTwigInstalled() {
  perl -MXML::Twig -e '1' &> /dev/null
  if [  "${?}" != 0 ]; then
    echo "XMLModule Twig is not installed script cannot execute"
    exit 1
  fi
}

#Check if perl exist in the system and that the twig module is also present
isPerlInstalled

while getopts "d" opt
do
    case $opt in
    (d) echo "Installed perl modules" ; perl -MFile::Find=find -MFile::Spec::Functions -Tlwe 'find { wanted => sub { print canonpath $_ if /\.pm\z/ }, no_chdir => 1 }, @INC' ; exit 1 ;;
    (*) printf "Illegal option '-%s'\n" "$opt" && exit 1 ;;
    esac
done

isXMLTwigInstalled

#perl -MFile::Find=find -MFile::Spec::Functions -Tlwe \
#'find { wanted => sub { print canonpath $_ if /\.pm\z/ }, no_chdir => 1 }, @INC'


# Get the current version of the project
VERSION=$(perl -MXML::Twig -e '
my $twig=XML::Twig->new();
$twig->parsefile("pom.xml");
print $_->text for $twig->findnodes("//project/version");'
)

# Explanation for the above perl script:
# First line imports twig to parse xml
# Second line opens the root pom.xml file
# Last line prints the value of the version xml node found in the project xml node

echo "Current detected version on root pom.xml is $VERSION"

# Extract the numeric part, decrement, and reconstruct
IFS='.' read -r MAJOR MINOR PATCH_SUFFIX <<< "$VERSION"
PATCH=$(echo "$PATCH_SUFFIX" | grep -o '^[0-9]\+')
SUFFIX=${PATCH_SUFFIX#"$PATCH"}
PATCH_PREV=$((PATCH - 1))
PREVIOUS_VERSION="$MAJOR.$MINOR.$PATCH_PREV$SUFFIX"

echo "Previous version is $PREVIOUS_VERSION"

# Count how many pom.xml files use this version
PROJECTS=$(grep -r --include "pom.xml" "$VERSION" | wc -l)

echo "$PROJECTS submodules are at this version"

# Count the same for the previous version
OLD_PROJECTS=$(grep -r --include "pom.xml" "$PREVIOUS_VERSION" | wc -l)

if [ "$OLD_PROJECTS" -gt 0 ]; then
  echo "There are submodules left at the last version"
  grep -r --include "pom.xml" "$PREVIOUS_VERSION"
else
  echo "No submodules with previous version detected"
fi