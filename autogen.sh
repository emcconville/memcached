#!/bin/sh

# Get the initial version.
perl version.pl 2> /dev/null

ACLOCAL_MIN_VERSION="1.9.0"
AUTOMAKE_MIN_VERSION="1.9.0"

# Configure echo parameters
case `echo "same\c"; echo " old"`,`echo -n same; echo " old"` in
  *c*,-n*)
    ECHO_N=""
    ECHO_C='
'
    ;;
  *c*)
    ECHO_N="-n"
    ECHO_C=""
    ;;
  *)
    ECHO_N=""
    ECHO_C="\c"
    ;;
esac

die() {
    echo "$@"
    exit 1
}

# Try to locate a program by using which, and verify that the file is an
# executable
locate_legacy_binary() {
  for f in $@
  do
	  file=`identify_default_binary $f`
	  if [ $? -eq 0 ]; then
			echo $file
			return 0
		fi
  done
  echo ""
  return 1
}

# Locate systems default program by respecting $PATH
identify_default_binary() {
  file=`which $1 2>/dev/null | grep -v '^no '`
  if test -n "$file" -a -x "$file"; then
    echo $file
    return 0
  fi
  echo ""
  return 1
}

# Assume GNU version is last word on first line
# Format version. ie. '1.10-p8' => '1.10.8'
identify_version() {
	echo `$1 --version | head -n 1 | awk '{print $NF}' | sed 's/[^0-9]/./g' | sed 's/\.\././g'`
	return 0
}

# Compare program version to min version
check_version() {
	VERSION_ERROR=1
	if test x$1 = x; then
		echo "Unable to resolve version number"
		exit 1
	fi
    current_version=$1
	if test x$2 = x; then
		echo "Unable to evaluate version numbers...missing \$min_version"
		exit 1
	fi
    min_version=$2
	
	current_version_major="`echo $current_version | cut -d. -f1`"
	current_version_minor="`echo $current_version | cut -d. -f2`"
	current_version_patch="`echo $current_version | cut -d. -f3`"
	min_version_major="`echo $min_version | cut -d. -f1`"
	min_version_minor="`echo $min_version | cut -d. -f2`"
	min_version_patch="`echo $min_version | cut -d. -f3`"
	if test x$current_version_major = x; then current_version_major=0 ; fi
	if test x$current_version_minor = x; then current_version_minor=0 ; fi
	if test x$current_version_patch = x; then current_version_patch=0 ; fi
	if test x$min_version_major = x; then min_version_major=0 ; fi
	if test x$min_version_minor = x; then min_version_minor=0 ; fi
	if test x$min_version_patch = x; then min_version_patch=0 ; fi
	
	if [ $min_version_major -lt $current_version_major ] ; then
		VERSION_ERROR=0
    elif [ $min_version_major -eq $current_version_major ] ; then
	  if [ $min_version_minor -lt $current_version_minor ] ; then
	    VERSION_ERROR=0
	  elif [ $min_version_minor -eq $current_version_minor ] ; then
	    if [ $min_version_patch -lt $current_version_patch ] ; then
			VERSION_ERROR=0
	    elif [ $min_version_patch -eq $current_version_patch ] ; then
			VERSION_ERROR=0
	    fi
	  fi
    fi
    return $VERSION_ERROR;
}

echo $ECHO_N "aclocal......$ECHO_C"
if test x$ACLOCAL = x; then
  ACLOCAL=`identify_default_binary aclocal`
  if [ $? -ne 0 ]; then
    die "Did not find a supported aclocal"
  else
	VERSION=`identify_version $ACLOCAL`
	check_version $VERSION $ACLOCAL_MIN_VERSION
	if [ $? -ne 0 ]; then
		ACLOCAL=`locate_legacy_binary aclocal-1.7 aclocal17 aclocal-1.5 aclocal15`
		if test x$ACLOCAL = x; then
			die "Did not find a supported aclocal"
		fi
	fi
  fi
fi
$ACLOCAL || exit 1
echo "OK"

echo $ECHO_N "autoheader...$ECHO_C"
AUTOHEADER=${AUTOHEADER:-autoheader}
$AUTOHEADER || exit 1
echo "OK" 


echo $ECHO_N "automake.....$ECHO_C"
if test x$AUTOMAKE = x; then
  AUTOMAKE=`identify_default_binary automake`
  if [ $? -ne 0 ]; then
    die "Did not find a supported automake"
  else
	VERSION=`identify_version $AUTOMAKE`
	check_version $VERSION $AUTOMAKE_MIN_VERSION
	if [ $? -ne 0 ]; then
		AUTOMAKE=`locate_legacy_binary automake-1.7`
		if test x$AUTOMAKE = x; then
		    die "Did not find a supported automake"
		fi
	fi
  fi
fi
$AUTOMAKE --foreign --add-missing || $AUTOMAKE --gnu --add-missing || exit 1
echo "OK"


echo $ECHO_N "autoconf.....$ECHO_C"
AUTOCONF=${AUTOCONF:-autoconf}
$AUTOCONF || exit 1
echo "OK"
