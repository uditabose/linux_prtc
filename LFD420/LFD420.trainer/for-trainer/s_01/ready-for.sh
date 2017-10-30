#!/bin/bash
#
# Setup development system for Linux Foundation courses
#
# Copyright (c) 2013 Chris Simmonds <chris@2net.co.uk>
#               2013-2017 Behan Webster <behanw@converseincode.com>
#               2014-2016 Jan-Simon Möller <dl9pf@gmx.de>
#
# Licensed under GPL
#
# Originally conceived by Chris Simmonds for LF315/Android Internals
# Massive rewrite and updates by Behan Webster (Maintainer)
# Further updates by Jan-Simon Möller
#
# Version 6.30: 2017-09-07
#     - Rename COURSE to ACTIVITY to make it more generic
#     - Add md5sum checks for downloading tarballs
#     - Add better docker support
#     - Add better stress support
#===============================================================================
VERSION=6.30

#===============================================================================
#
# You can define requirements for a particular course by defining the following
# variables where LFXXXX is your course number:
#
#   TITLE[LFXXXX]=""            # Name of the course
#   WEBPAGE[LFXXXX]="http://..."# LF URL for course
#   ARCH[LFXXXX]=x86_64         # Required CPU arch (optional)
#   CPUFLAGS[LFXXXX]="vmx aes"  # Required CPU flags (optional)
#   CPUS[LFXXXX]=2              # How many CPUS/cores are required
#   PREFER_CPUS[LFXXXX]=4       # How many CPUS would be preferred
#   BOGOMIPS[LFXXXX]=4000       # How many cumulative BogoMIPS you need
#   RAM[LFXXXX]=2               # How many GiB of RAM you need
#   DISK[LFXXXX]=30             # How many GiB of Disk you need free in $HOME
#   BOOT[LFXXXX]=30             # How many MiB of Disk you need free in /boot
#   CONFIGS[LFXXXX]="KSM"       # Which CONFIG_* kernel variables are required (optional)
#   DISTRO_ARCH[LFXXXX]=x86_64  # Required Linux distro arch (optional)
#   INTERNET[LFXXXX]=y          # Is internet access required? (optional)
#   CARDREADER[LFXXXX]=Required # Is a card reader or USB mass storage device required? (optional)
#   NATIVELINUX[LFXXXX]=Required# Is Native Linux required for this course? (optional)
#   VMOKAY[LFXXXX]=Okay         # Can this course be done on a VM? (optional)
#   SYMLINKS[LFXXXX]="/bin/sh:!dash /usr/bin/python:!^/opt/"
#                               # Symlink patterns you want to satisfy
#   VERSIONS[LFXXXX]="bash:>4 gcc:=5 python:<3"
#                               # --versions you want to check
#   EXTRAS[LFXXXX]="LFD460_%COURSE_VERSION%/"
#                               # Download extra things from course materials
#   RUNCODE[LFXXXX]=lfXXX_func  # Run this bash function after install (optional)
#   DISTROS[LFXXXX]="Fedora-21+ CentOS-6+ Ubuntu-16.04+"
#                               # List of distros you can support.
#                               #   DistroName
#                               #   DistroName:arch
#                               #   DistroName-release
#                               #   DistroName-release+
#                               #   DistroName:arch-release
#                               #   DistroName:arch-release+
#
# Note: I know BogoMIPS aren't a great measure of CPU speed, but it's what we have
# easy access to.
#
# You can also specify required packages for your distro. All the appropriate
# package lists for the running machine will be checked. This allows you to
# keep package lists for particular distros, releases, arches and classes.
# For example:
#
#   PACKAGES[Ubuntu]="gcc less"
#   PACKAGES[Ubuntu_LFD320]="stress trace-cmd"
#   PACKAGES[Ubuntu-14.04]="git-core"
#   PACKAGES[Ubuntu-12.04]="git"
#   PACKAGES[Ubuntu-12.04_LFD450]="gparted u-boot-tools"
#   PACKAGES[Ubuntu_LFS550]="build-dep_wireshark"
#   PACKAGES[RHEL]="gcc less"
#   PACKAGES[RHEL-6]="git"
#   PACKAGES[RHEL-6_LF320]="trace-cmd"
#
# Missing packages are listed so the user can install them manually, or you can
# rerun this script with --install to do it automatically.
#
# You can also copy the identical package list from another course with:
#
#   COPYPACKAGES[LFDXXX] = "LFDYYY"
#
# Support for all distros is not yet finished, but I've templated in code where
# possible. If you can add code to support a distro, please send a patch!
#
# If you want to see extra debug output, set DEBUG=1 2 or 3
#
#    DEBUG=2 ./ready-for.sh LFD450
# or
#    ./ready-for.sh --debug=2 LFD450
# or
#    ./ready-for.sh -DD LFD450
#

#===============================================================================
RED="\e[0;31m"
GREEN="\e[0;32m"
YELLOW="\e[0;33m"
CYAN="\e[0;36m"
BLUE="\e[0;34m"
BACK="\e[0m"

#-------------------------------------------------------------------------------
ask() {
    echo -ne "${YELLOW}WARN${BACK}: $* " >&2
}

#-------------------------------------------------------------------------------
bare_debug() {
    [[ -z $DEBUG ]] || echo "$@" >&2
}

#-------------------------------------------------------------------------------
bug() {
    local MSG=$1 CODE=$2
    warn "Hmm... That's not right...\n    $MSG\n    Probably a bug. Please send the output of the following to behanw@converseincode.com\n      $CODE"
}

#-------------------------------------------------------------------------------
debug() {
    local LEVEL=$1; shift
    local OPT
    if [[ $1 == -* ]] ; then
        OPT=$1; shift
    fi
    if [[ -n $DEBUG && $LEVEL -le $DEBUG ]] ; then
        # shellcheck disable=SC2086
        bare_debug $OPT "D:" "$@"
    fi
}

#-------------------------------------------------------------------------------
divider() {
    echo '--------------------------------------------------------------------------------'
}

#-------------------------------------------------------------------------------
dothis() {
    echo -e "${BLUE}$*${BACK}"
}

#-------------------------------------------------------------------------------
export MYPID=$$
error() {
    echo E: "$@" >&2
    set -e
    kill -TERM $MYPID 2>/dev/null
}

#-------------------------------------------------------------------------------
fail() {
    echo -e "${RED}FAIL${BACK}:" "$@" >&2
}

#-------------------------------------------------------------------------------
fix_missing() {
    local MSG=$1 CMD1=$2 CMD2=$3
    highlight "$MSG by running:"
    # shellcheck disable=SC2086
    dothis "  "$CMD1
    if [[ -n $CMD2 ]] ; then
        highlight "or by:"
        # shellcheck disable=SC2086
        dothis "  "$CMD2
    fi
}

#-------------------------------------------------------------------------------
highlight() {
    echo -e "${YELLOW}$*${BACK}" >&2
}

#-------------------------------------------------------------------------------
notice() {
    local OPT
    if [[ $1 == -* ]] ; then
        OPT=$1; shift
    fi
    if [[ -n $OPT || -z $NO_WARN ]] ; then
        # shellcheck disable=SC2086
        echo $OPT -e "${CYAN}NOTE${BACK}: $*" >&2
    fi
}

#-------------------------------------------------------------------------------
pass() {
    [[ -n $NO_PASS ]] || echo -e "${GREEN}PASS${BACK}: $*"
}

#-------------------------------------------------------------------------------
progress() {
    [[ -z $PROGRESS ]] || echo -en "$1" >&2
}

#-------------------------------------------------------------------------------
verbose() {
    [[ -z $VERBOSE ]] || echo -e "INFO:" "$@" >&2
}

#-------------------------------------------------------------------------------
warn() {
    local OPT
    if [[ $1 == -* ]] ; then
        OPT=$1; shift
    fi
    if [[ -n $OPT || -z $NO_WARN ]] ; then
        # shellcheck disable=SC2086
        echo $OPT -e "${YELLOW}WARN${BACK}: $*" >&2
    fi
}

#-------------------------------------------------------------------------------
warn_wait() {
    if [[ -n $YES ]] ; then
        debug 1 "warn_wait: always --yes, so not asking; just continue."
        return 0
    fi
    warn -n "$*\n    Continue? [Yn] " >&2
    read ANS
    case $ANS in
        Y*|y*|1*) return 0 ;;
        *) [[ -z $ANS ]] || return 1 ;;
    esac
    return 0
}

#===============================================================================
# Check that we're running on Linux
if [[ $(uname -s) != Linux || -n $SIMULATE_FAILURE ]] ; then
    echo "FAIL: You need to run this on Linux machine you intend to use for the class, not on $(uname -s)"
    exit 1
fi

#===============================================================================
# The minimum version of bash required to run this script is bash v4
if bash --version | egrep -q 'GNU bash, version [1-3]' ; then
    fail "This script requires at least version 4 of bash"
    fail "You are running: $(bash --version | head -1)"
    exit 1
fi

#===============================================================================
check_root() {
    if [[ $USER == root || $HOME == /root ]] ; then
        fail "Please don't run as root"
        notice "Sudo will be used internally by this script as required."
        exit 1
    fi
}
check_root


#===============================================================================
CMDNAME=${CMDNAME:-$0}
CMDBASE=$(basename "$CMDNAME")
usage() {
    COURSE=${COURSE# }
    echo "Usage: $CMDBASE [options] [course]"
    echo "    --distro               List current Linux distro"
    echo "    --install              Install missing packages for the course"
    echo "    --remove [--all]       Remove installed packages for the course"
    echo "    --list                 List all supported courses"
    echo "    --no-cache             Don't use previously cached output."
    echo "    --no-course-files      Don't install course files"
    echo "    --no-extras            Don't download extra materials"
    echo "    --no-install           Don't check installed packages"
    echo "    --no-recommends        Don't install recommended packages"
    echo "    --no-vm                Don't download virtual machine"
    echo "    --update               Update to latest version of this script"
    echo "    --verify               Verify script MD5sum"
    echo "    --version              List script version"
    echo "    --verbose              Turn on extra messages"
    echo "    --yes                  Answer 'yes' to every question"
    echo
    echo "Example: $CMDBASE --install ${COURSE:-LFD450}"
    exit 0
}

#===============================================================================
# Command option parsing
COURSE=
CMDOPTS="$*"
while [[ $# -gt 0 ]] ; do
    case "$1" in
        -AD|-ALFD|--all-lfd) ALL_LFD=y ;;
        -AS|-ALFS|--all-lfs) ALL_LFS=y ;;
        -A|--all|--all-activities) ALL_ACTIVITIES=y ;;
        -ap|--all-packages) ALL_PKGS=y ;;
        --check-packages) CHECK_PKGS=y ;;
        --curl) USECURL=y ;;
        -D|--debug=1|--debug) DEBUG=1; VERBOSE=y ;;
        -DD|--debug=2) DEBUG=2; VERBOSE=y ;;
        -DDD|--debug=3) DEBUG=3; VERBOSE=y ;;
        --detect-vm) DETECT_VM=y ;;
        --dry-run|--dryrun) DRYRUN=echo ;;
        --distro) WHICH_DISTRO=y ;;
        -i|--install) INSTALL=y ;;
        --force-update) FORCEUPDATE=y ;;
        --gather-info) GATHER_INFO=y ;;
        --graphiz|--dot) if [[ -d $2 ]] ; then GRAPHVIZ=$2; shift; else GRAPHVIZ=y; fi ;;
        --json) JSON=y ;;
        -l|--list) LIST_ACTIVITIES=y; break ;;
        --list-distro*) LIST_DISTROS=y; break ;;
        -P|--list-packages) LIST_PKGS=y ;;
        -L|--list-requirements) LIST_REQS=y ;;
        --no-cache|--nocache) NOCACHE=y ;;
        -C|--no-course-files) NOCM=y ;;
        -E|--no-extras) NOEXTRAS=y ;;
        -I|--no-install) NOINSTALL=y ;;
        --no-network) NONETWORK=y; DONTUPDATE=y ;;
        -R|--no-recommends) NORECOMMENDS=y ;;
        -N|--no-vm*) NOVM=y ;;
        -O|--override-distro) DISTRO=$2; DIST_LIST=$2; shift ;;
        -p|--packages) LIST_PKGS=y; PKGS="${PKGS# } $2"; shift ;;
        -r|--remove) REMOVE=y ;;
        --progress) PROGRESS=y ;;
        --simulate-failure) SIMULATE_FAILURE=y; NOCACHE=y ;;
        --trace) set -x ;;
        --try-all-activities) TRY_ALL_ACTIVITIES=y ;;
        --update-*) UPDATE=${1#--update-}; VERIFY=''; VERBOSE=y ;;
        --update) UPDATE=y; VERBOSE=y ;;
        --verify-*) UPDATE=''; VERIFY=${1#--verify-} ;;
        --verify) VERIFY=y ;;
        -U|--user) USER=$2; HOME=$(getent passwd "$2" | cut -d: -f6); shift ;;
        -v|--verbose) VERBOSE=y ;;
        -V|--version) echo $VERSION; exit 0 ;;
        -y|--yes) YES=y ;;
        LFD*|LFS*) COURSE="${COURSE# } $1" ;;
        [0-9][0-9][0-9]) COURSE="${COURSE# } LFD$1" ;;
        -h*|--help*|*) usage ;;
    esac
    shift
done
PKGS="${PKGS# }"
debug 1 "main: Command Line Parameters: CMD=$CMDNAME => $CMDOPTS ($PKGS)"
debug 1 "main: COURSE=$COURSE $(env | grep '=y$')"

#===============================================================================
CONFFILE="$HOME/.${CMDBASE%.sh}.rc"
if [[ -f $CONFFILE ]] ; then
    notice "Reading $CONFFILE"
    source "$CONFFILE"
fi

#===============================================================================
# Allow info to be gathered in order to fix distro detection problems
gather() {
    local FILE
    FILE=$(which "$1" 2>/dev/null || echo "$1")
    shift
    if [[ -n $FILE && -e $FILE ]] ; then
        echo "--- $FILE ---------------------------------------------"
        if [[ -x $FILE ]] ; then
            "$FILE" "$@"
        else
            cat "$FILE"
        fi
    fi
}

#===============================================================================
gather_info() {
    divider
    /bin/bash --version | head -1
    gather lsb_release --all
    gather /etc/lsb-release
    gather /etc/os-release
    gather /etc/debian_version
    gather /etc/apt/sources.list
    gather /etc/redhat-release
    gather /etc/SuSE-release
    gather /etc/arch-release
    gather /etc/gentoo-release
    divider
    exit 0
}
[[ -n $GATHER_INFO ]] && gather_info

#===============================================================================
# Just in case we're behind a proxy server (the system will add settings to /etc/environment)
[[ -f /etc/environment ]] && . /etc/environment
export all_proxy http_proxy https_proxy ftp_proxy

#===============================================================================
# See if version is less than the other
version_greater_equal() {
    local i LEN VER1 VER2
    IFS=. read -r -a VER1 <<< "$1"
    IFS=. read -r -a VER2 <<< "$2"
    # shellcheck disable=SC2145
    debug 3 "version_greater_equal: $1(${#VER1[*]})[${VER1[@]}] $2(${#VER2[*]})[${VER2[@]}]"
    LEN=$( (( ${#VER1[*]} > ${#VER2[*]} )) && echo ${#VER1[*]} || echo ${#VER2[*]})
    for ((i=0; i<LEN; i++)) ; do
        VER1[i]=${VER1[i]#0}; VER1[i]=${VER1[i]:-0}
        VER2[i]=${VER2[i]#0}; VER2[i]=${VER2[i]:-0}
        debug 3 "  version_greater_equal: Compare ${VER1[i]} and ${VER2[i]}"
        (( ${VER1[i]:-0} > ${VER2[i]:-0} )) && return 0
        (( ${VER1[i]:-0} < ${VER2[i]:-0} )) && return 1
    done
    return 0
}

#===============================================================================
# See if md5sum is the same
md5cmp() {
    local FILE=$1 MD5=$2
    debug 3 "md5cmp FILE=$FILE MD5=$MD5"
    [[ $MD5 = $(md5sum "$FILE" | awk '{print $1}') ]] || return 1
    return 0
}

CMCACHE="$HOME/.cache/${CMDBASE%.sh}"

#===============================================================================
# Clean meta variable cache
clean_cache(){
    debug 1 "clean_cache: $CMCACHE"
    mkdir -p "$CMCACHE"
    [[ -z "$CMCACHE/*.conf" ]] || rm -rf "$CMCACHE/*.conf"
}

#===============================================================================
cache_output() {
    local ACTIVITY="$1"
    local CMD="$2"
    local OUTPUT="$CMCACHE/$ACTIVITY-${CMDBASE%.sh}.output"
    debug 1 "cache_output: ACTIVITY=$ACTIVITY CMD=$CMD OUTPUT=$OUTPUT"

    mkdir -p "$CMCACHE"
    find "$CMCACHE" -mtime +0 -type f -print0 | xargs -0 --no-run-if-empty rm -f

    if [[ -n $NOCACHE || -n $VERBOSE ]] ; then
        "$CMD"
        rm -f "$OUTPUT"
    elif [[ -s $OUTPUT ]] ; then
        cat "$OUTPUT"
    else
        "$CMD" 2>&1 | tee "$OUTPUT"
    fi
}

#===============================================================================
# URLS
LFURL="https://training.linuxfoundation.org"
LFCM="$LFURL/cm"
UPGRADE="$LFCM/prep"
LFDTRAINING="$LFURL/linux-courses/development-training"
LFSTRAINING="$LFURL/linux-courses/system-administration-training"
VMURL="VIRTUAL_MACHINE_IMAGES"

CMUSERNAME=LFtraining
CMPASSWORD=Penguin2014
WGET_PASS="--user=$CMUSERNAME --password=$CMPASSWORD"
CURL_PASS="--user $CMUSERNAME:$CMPASSWORD"

WGET_VERSION=$(wget --version | awk '{print $3; exit}')
WGET_PROGRESS="--quiet --progress=bar"
WGET_TIMEOUT="--timeout=10"

if version_greater_equal "$WGET_VERSION" 1.17 ; then
    WGET_PROGRESS="$WGET_PROGRESS --show-progress"
fi

CURL_TIMEOUT="--location --connect-timeout 10"

#===============================================================================
# Download file (try wget, then curl, then perl)
get() {
    local URL=$1 WGET_OPTS=$2 CURL_OPTS=$3
    if [[ -n $NONETWORK ]] ; then
        warn "get $URL: No network selected."
        return 1
    elif [[ -z $USECURL ]] && which wget >/dev/null ; then
        debug 2 "  get: wget --quiet --no-cache $WGET_TIMEOUT $WGET_OPTS $URL"
        # shellcheck disable=SC2086
        $DRYRUN wget --quiet --no-cache $WGET_TIMEOUT $WGET_OPTS "$URL" -O- 2>/dev/null || return 1
    elif which curl >/dev/null ; then
        debug 2 "  get: curl $CURL_TIMEOUT $CURL_OPTS $URL"
        # shellcheck disable=SC2086
        $DRYRUN curl $CURL_TIMEOUT $CURL_OPTS "$URL" 2>/dev/null || return 1
    elif which perl >/dev/null ; then
        debug 2 "  perl LWP::Simple $URL"
        $DRYRUN perl -MLWP::Simple -e "getprint '$URL'" 2>/dev/null || return 1
    else
        warn "No download tool found."
        return 1
    fi
    return 0
}


WGET_CM_OPTS="$WGET_PASS --no-check-certificate $WGET_TIMEOUT"
CURL_CM_OPTS="$CURL_PASS $CURL_TIMEOUT"

#===============================================================================
# Get File from web site
get_file() {
    local ACTIVITY=${1%/}
    local FILE=$2
    local TODIR=$3
    local PARTIAL=$4
    debug 1 "get_file ACTIVITY=$ACTIVITY FILE=$FILE TODIR=$TODIR PARTIAL=$PARTIAL"

    local URL="$LFCM/$ACTIVITY${FILE:+/$FILE}"

    [[ -z $TODIR ]] || pushd "$TODIR" >/dev/null
    if [[ -n $NONETWORK ]] ; then
        warn "get_file $FILE: No network selected."
        return 1
    elif [[ -z $USECURL ]] && which wget >/dev/null ; then
        local OPTS
        if [[ -n $FILE ]] ; then
            OPTS="--continue $WGET_PROGRESS"
        else
            OPTS="--quiet -O -"
        fi
        debug 2 "  get_file: wget $WGET_CM_OPTS $OPTS $URL"
        # shellcheck disable=SC2086
        $DRYRUN wget $WGET_CM_OPTS $OPTS "$URL"
    elif which curl >/dev/null ; then
        local OPTS="-s"
        [[ -z $FILE ]] || OPTS="-# -O"
        if [[ $PARTIAL = y ]] ; then
            rm -f "$FILE"
        elif [[ -z $PARTIAL && -f $FILE ]] ; then
            notice "Verifying $FILE... (for curl)"
            tar tf "$FILE" >/dev/null 2>&1 || rm -f "$FILE"
        fi
        debug 2 "  get_file: curl $CURL_CM_OPTS $OPTS $URL"
        # shellcheck disable=SC2086
        [[ -f $FILE ]] || $DRYRUN curl $CURL_CM_OPTS $OPTS "$URL"
    else
        warn "No download tool found."
        return 1
    fi
    [[ -z $TODIR ]] || popd >/dev/null
    return 0
}

#===============================================================================
# Try to get file
try_file() {
    local ACTIVITY=${1%/}
    local FILE=$2
    local TODIR=$3
    debug 1 "try_file ACTIVITY=$ACTIVITY FILE=$FILE TODIR=$TODIR"

    local URL OPTS SIZE
    URL=$LFCM/$ACTIVITY${FILE:+/$FILE}
    debug 2 "  try_file: wget $OPTS $URL"
    SIZE=$(wget "$OPTS" "$URL" 2>&1 | awk '/Length:/ {print $2}')

    local LOCALFILE="$TODIR/$FILE"
    debug 2 "  try_file: LOCALFILE=$LOCALFILE"
    if [[ -f $LOCALFILE && $(stat --format="%s" "$LOCALFILE") -eq $SIZE ]] ; then
        debug 1 "Already downloaded $LOCALFILE"
        return 1
    fi
    return 0
}

#===============================================================================
# Get meta variable (cache lookups)
get_var(){
    local KEY=$1
    local ACTIVITY=${2# }
    debug 1 "get_var: KEY=$KEY ACTIVITY=$ACTIVITY"

    mkdir -p "$CMCACHE"
    local CONF="${CMDBASE%.sh}.conf"
    local FILE="$CMCACHE/$ACTIVITY-$CONF"
    debug 2 "  get_var: CONF=$CONF FILE=$FILE"
    if [[ ! -e $FILE ]] ; then
        (get_file "$ACTIVITY/.$CONF" && get_file ".$ACTIVITY-$CONF") >"$FILE"
    fi
    awk -F= '/'"$KEY"'=/ {print $2}' "$FILE" | sed -e 's/^"\(.*\)"$/\1/'
}

#===============================================================================
# Get Extras
get_activity_file() {
    local ACTIVITY=$1
    local KIND=${2:-SOLUTIONS}
    debug 1 "get_activity_file: ACTIVITY=$ACTIVITY"
    local FILE VER

    if [[ -n $NONETWORK ]] ; then
        warn "get_activity_file: No network selected"
        return
    fi

    # Find newest SOLUTIONS file
    # shellcheck disable=SC2086
    FILE=$(get_file "$ACTIVITY" \
        | awk -F\" '/'$KIND'/ {print $8}' \
        | sed -Ee 's/^(.*V)([0-9.]+)(_.*)$/\2.0.0 \1\2\3/' \
        | sort -t. -n -k1,1 -k2,2 -k3,3 \
        | awk 'END {print $2}')
    # shellcheck disable=SC2086
    if [[ -z $FILE ]] ; then
        FILE=$(get_file "$ACTIVITY" \
        | awk -F\" '/'$KIND'/ {print $8}' \
        | sort | tail -1)
    fi

    if [[ -n $FILE ]] ; then
        VER=$(sed -re 's/^.*(V[0-9.]+).*$/\1/' <<<$FILE)
        debug 2 "   get_activity_file: ACTIVITY=$ACTIVITY FILE=$FILE VER=$VER"
        echo "$FILE" "$VER"
    else
        debug 2 "   get_activity_file: No files found for $ACTIVITY"
    fi
}

clean_cache


#===============================================================================
# Check for updates
check_version() {
    verbose "Checking for updated script"
    [[ -z $DONTUPDATE ]] || return

    if [[ -n $NONETWORK ]] ; then
        warn "check_version: No network selected"
        return
    fi

    local URL="$UPGRADE"
    local CMD="$CMDBASE"
    local META="${CMD/.sh/}.meta"
    local NEW="${TMPDIR:-/tmp}/${CMD/.sh/.$$}"

    #---------------------------------------------------------------------------
    # Beta update
    if [[ $UPDATE =~ ...* || $VERIFY =~ ...* ]] ; then
        if [[ $UPDATE =~ ...* ]] ; then
            URL+="/$UPDATE"
        elif [[ $VERIFY =~ ...* ]] ; then
            URL+="/$VERIFY"
        fi
        FORCEUPDATE=y
    fi

    #---------------------------------------------------------------------------
    # Get metadata
    local VER MD5 OTHER
    # shellcheck disable=SC2086
    read -r VER MD5 OTHER <<< "$(get $URL/$META)"

    #---------------------------------------------------------------------------
    # Verify metadata
    if [[ -n $VERIFY ]] ; then
        if [[ -n $MD5 ]] ; then
            if md5cmp "$CMDNAME" "$MD5" ; then
                pass "md5sum matches"
            elif md5cmp "$CMDNAME" "$OTHER" ; then
                MD5="$OTHER"
                pass "md5sum matches"
            else
                fail "md5sum failed (you might want to run a --force-update to re-download)"
            fi
#        elif [[ -z $VER ]] ; then
#            return
        else
            warn "md5sum can't be checked, none found"
        fi
        exit 0
    fi

    #---------------------------------------------------------------------------
    # Get update for script
    INTERNET_AVAILABLE=y
    debug 1 "  check_version: ver:$VERSION VER:$VER MD5:$MD5"
    [[ -n $FORCEUPDATE ]] && UPDATE=y
    if [[ -n $FORCEUPDATE ]] || ( ! md5cmp "$CMDNAME" "$MD5" && ! version_greater_equal "$VERSION" "$VER" ) ; then
        if [[ -n $UPDATE ]] ; then
            if get "$URL/$CMD" >"$NEW" ; then
                mv "$NEW" "$CMDNAME"
                chmod 755 "$CMDNAME"
                if [[ $UPDATE =~ ...* ]] ; then
                    warn "Now running $UPDATE version of this script"
                else
                    notice "A new version of this script was found. Upgrading..."
                    # shellcheck disable=SC2086
                    [[ -n $COURSE ]] && DONTUPDATE=1 eval bash "$CMDNAME" $CMDOPTS
                fi
            else
                rm -f "$NEW"
                warn "No script found"
            fi
        else
            notice "A new version of this script was found. (use \"$CMDNAME --update\" to download)"
        fi
    else
        verbose "No update found"
    fi
    [[ -z $UPDATE ]] || exit 0
}
check_version

#===============================================================================
# Make associative arrays
declare -A DEBREL DISTRO_ALIASES DISTRO_NAMES FALLBACK PACKAGES

#===============================================================================
# Create empty Package lists for all distros
#===============================================================================
PACKAGES[CentOS]=
PACKAGES[CentOS-6]=
PACKAGES[CentOS-7]=
#-------------------------------------------------------------------------------
PACKAGES[Debian]=
PACKAGES[Debian-7]=
PACKAGES[Debian-8]=
PACKAGES[Debian-9]=
PACKAGES[Debian-999]=
#-------------------------------------------------------------------------------
PACKAGES[Fedora]=
PACKAGES[Fedora-23]=
PACKAGES[Fedora-24]=
PACKAGES[Fedora-25]=
PACKAGES[Fedora-26]=
PACKAGES[Fedora-999]=
#-------------------------------------------------------------------------------
PACKAGES[LinuxMint]=
PACKAGES[LinuxMint-17]=
PACKAGES[LinuxMint-17.1]=
PACKAGES[LinuxMint-17.2]=
PACKAGES[LinuxMint-17.3]=
PACKAGES[LinuxMint-18]=
PACKAGES[LinuxMint-18.1]=
#-------------------------------------------------------------------------------
PACKAGES[openSUSE]=
PACKAGES[openSUSE-13.2]=
PACKAGES[openSUSE-42.1]=
PACKAGES[openSUSE-42.2]=
PACKAGES[openSUSE-42.3]=
PACKAGES[openSUSE-999]=
#-------------------------------------------------------------------------------
PACKAGES[RHEL]=
PACKAGES[RHEL-6]=
PACKAGES[RHEL-7]=
#-------------------------------------------------------------------------------
PACKAGES[Ubuntu]=
PACKAGES[Ubuntu-12.04]=
PACKAGES[Ubuntu-14.04]=
PACKAGES[Ubuntu-16.04]=
PACKAGES[Ubuntu-16.10]=
PACKAGES[Ubuntu-17.04]=
#-------------------------------------------------------------------------------
PACKAGES[SLES]=
PACKAGES[SLES-12.2]=

#===============================================================================
# If we can't find settings/packages for a distro fallback to the next one
FALLBACK=(
    [CentOS]="RHEL"
    [CentOS-6]="RHEL-6"
    [CentOS-7]="RHEL-7"
    [Debian]="Ubuntu"
    [Debian-7]="Ubuntu-12.04"
    [Debian-8]="Debian-7 Ubuntu-14.04"
    [Debian-9]="Debian-8 Ubuntu-17.04 Ubuntu-16.04"
    [Debian-999]="Debian-9 Debian-8 Ubuntu-17.04 Ubuntu-16.04"
    [Fedora]="RHEL CentOS"
    [Fedora-23]="Fedora"
    [Fedora-24]="Fedora-23"
    [Fedora-25]="Fedora-24"
    [Fedora-26]="Fedora-25 Fedora-24"
    [Fedora-999]="Fedora-26 Fedora-25"
    [LinuxMint]="Ubuntu"
    [LinuxMint-17]="Ubuntu-14.04 Debian-8"
    [LinuxMint-17.1]="LinuxMint-17 Ubuntu-14.04 Debian-8"
    [LinuxMint-17.2]="LinuxMint-17.1 LinuxMint-17 Ubuntu-14.04 Debian-8"
    [LinuxMint-17.2]="LinuxMint-17.2 LinuxMint-17.1 LinuxMint-17 Ubuntu-14.04 Debian-8"
    [LinuxMint-18]="Ubuntu-16.04"
    [LinuxMint-18.1]="LinuxMint-18 Ubuntu-16.04"
    [Mint]="LinuxMint Ubuntu"
    [RHEL]="CentOS"
    [RHEL-6]="CentOS-6"
    [RHEL-7]="CentOS-7"
    [openSUSE-13.2]="openSuse"
    [openSUSE-42.1]="openSuse-13.2"
    [openSUSE-42.2]="openSuse-42.1"
    [openSUSE-42.3]="openSuse-42.2"
    [openSUSE-999]="openSuse-42.3 openSuse-42.2"
    [SLES]="openSUSE"
    [SLES-12.2]="openSUSE-13.2"
    [SUSE]="openSUSE"
    [Ubuntu]="Debian"
    [Ubuntu-12.04]="Debian-7"
    [Ubuntu-14.04]="Debian-8"
    [Ubuntu-16.04]="Ubuntu-14.04"
    [Ubuntu-16.10]="Ubuntu-16.04"
    [Ubuntu-17.04]="Ubuntu-16.10 Ubuntu-16.04"
    [Kubuntu]="Ubuntu"
    [XUbuntu]="Ubuntu"
)

#===============================================================================
# Distro release aliases
DISTRO_ALIASES=(
    [Debian-sid]="Debian-999"
    [Fedora-Rawhide]="Fedora-999"
    [openSUSE-Tumbleweed]="openSUSE-999"
    [Ubuntu-LTS]="Ubuntu-12.04 Ubuntu-14.04 Ubuntu-16.04"
    [Ubuntu-12.04+LTS]="Ubuntu-12.04 Ubuntu-14.04 Ubuntu-16.04"
    [Ubuntu-12.04+LTS+]="Ubuntu-12.04 Ubuntu-14.04 Ubuntu-16.04+"
    [Ubuntu-14.04+LTS]="Ubuntu-14.04 Ubuntu-16.04"
    [Ubuntu-14.04+LTS+]="Ubuntu-14.04 Ubuntu-16.04+"
    [Ubuntu-16.04+LTS]="Ubuntu-16.04"
    [Ubuntu-16.04+LTS+]="Ubuntu-16.04+"
)

#===============================================================================
# Distro release code names
DISTRO_NAMES=(
    [Debian-999]="Debian-sid"
    [Fedora-999]="Fedora-Rawhide"
    [openSUSE-999]="openSUSE-Tumbleweed"
)

#===============================================================================
# Distro release code names
DEBREL=(
    [hamm]=2
    [slink]=2.1
    [potato]=2.2
    [woody]=3
    [sarge]=3.1
    [etch]=4
    [lenny]=5
    [squeeze]=6
    [wheezy]=7
    [jessie]=8
    [stretch]=9
    [buster]=10
    [stable]=9
    [testing]=10
    [sid]=999
    [unstable]=999
)

#===============================================================================
# Some classes have been renamed
declare -A ACTIVITY_ALIASES
ACTIVITY_ALIASES=(
    [LFD211]=LFD301
    [LFD262]=LFD301
    [LFD305]=LFD301
    [LFD312]=LFD401
    [LFD320]=LFD420
    [LFD331]=LFD430
    [LFD404]=LFD460
    [LFD405]=LFD460
    [LFD410]=LFD450
    [LFD411]=LFD450
    [LFD414]=LFD415
    [LFD5420]=LFD420
    [LFS101]=LFS101x
    [LFS102]=LFS300
    [LFS220]=LFS301
    [LFS230]=LFS311
    [LFS520]=LFS452
    [LFS540]=LFS462
    [LFS541]=LFS462
    [LFS550]=LFS465
    [LFS551]=LFS465
)

declare -A ARCH BOGOMIPS BOOT CONFIGS CPUFLAGS CPUS \
    TITLE WEBPAGE DISK DISTROS DISTRO_ARCH DISTRO_BL DISTRO_DEFAULT \
    INTERNET CARDREADER NATIVELINUX OS OS_NEEDS PREFER_CPUS SYMLINKS RAM \
    COPYPACKAGES RECOMMENDS RUNCODE VERSIONS VMOKAY EXTRAS VMS INCLUDES \
    INPERSON VIRTUAL SELFPACED MOOC INSTR_LED_CLASS SELFPACED_CLASS PREREQ

#===============================================================================
# Default Requirements
#===============================================================================
INPERSON=y
VIRTUAL=y
SELFPACED=n
MOOC=n
#INSTR_LED_CLASS=
#SELFPACED_CLASS=
#PREREQ=
OS=Linux
OS_NEEDS=
ARCH=x86_64
#CPUFLAGS=
CPUS=1
PREFER_CPUS=2
BOGOMIPS=2000
RAM=1
DISK=5
#BOOT=128
#CONFIGS=
#INTERNET=Required
#CARDREADER=y
#NATIVELINUX=y
VMOKAY=Acceptable
DISTRO_ARCH=x86_64
DISTRO_DEFAULT[LFD]="Ubuntu-16.04"
DISTRO_DEFAULT[LFS]="CentOS-7"
#DISTROS="Arch-2012+ Gentoo-2+"
DISTROS[LFD]="CentOS-7+ Debian-8+ Fedora-24+ LinuxMint-18+ openSUSE-42.1+ RHEL-7+ Ubuntu-16.04+LTS+ SLES-12+"
DISTROS[LFS]="CentOS-7+ Debian-8+ Fedora-23+ LinuxMint-17+ openSUSE-42.1+ RHEL-7+ Ubuntu-14.04+LTS+ SLES-12+"
DISTRO_BL="CentOS-6 Debian-7 RHEL-6 LinuxMint-16 Ubuntu-12.04 Ubuntu-12.10 Ubuntu-13.04 Ubuntu-13.10 Ubuntu-14.10 Ubuntu-15.04 Ubuntu-15.10 Ubuntu-16.10"
#INCLUDES=
EXTRAS=
VMS=
#-------------------------------------------------------------------------------
PACKAGES=
COPYPACKAGES=
RECOMMENDS=

#===============================================================================
# Remove shellcheck errors
export OS_NEEDS

#===============================================================================
ANYOS="Linux, MacOS, Windows"
UNIXOS="Linux, MacOS"
REMOTE_NEEDS="modern web browser, terminal emulation program (ssh or putty)"
BBBKIT="devboard, usb-serial, card-reader, usb-ethernet, SD-card"
BBBKITIMG="$BBBKIT:BBB_kit"
BBBLCDKIT="$BBBKIT, LCD-screen"
BBBLCDKITIMG="$BBBLCDKIT:LCD_kit"

#===============================================================================
# Common strings
DISCOURAGED="Highly Discouraged"
PROVIDED="Required (one will be Provided)"
RECOMMENDED="Highly Recommended"
REQUIRED="Required"
#VMPREFERRED="The use of a VM for this class is preferable"
VMNOTOKAY="This course can't be run on a VM; you will be running VMs under a Linux host"

#===============================================================================
enable_extras() {
    local ACTIVITY=$1

    EXTRAS[$ACTIVITY]="${ACTIVITY}_%COURSE_VERSION%/"
}

#===============================================================================
# Build packages
#===============================================================================
PACKAGES[@build]="autoconf automake bison flex gdb make patch"
RECOMMENDS[@build]="ccache texinfo"
#-------------------------------------------------------------------------------
PACKAGES[Ubuntu_@build]="build-essential libc6-dev libncurses5-dev libtool manpages"
PACKAGES[Ubuntu-12.04_@build]="g++-multilib"
PACKAGES[Ubuntu-14.04_@build]="libtool"
PACKAGES[Debian-8_@build]="-libtool libtool-bin"
PACKAGES[Ubuntu-16.04_@build]="[Debian-8_@build]"
#-------------------------------------------------------------------------------
PACKAGES[RHEL_@build]="gcc gcc-c++ glibc-devel ncurses-devel"
#-------------------------------------------------------------------------------
PACKAGES[openSUSE_@build]="[RHEL_@build] makeinfo -texinfo"

#===============================================================================
# Common packages used in various places
#===============================================================================
PACKAGES[@common]="bzip2 curl dos2unix file gawk git gzip sudo tar tree unzip wget"
RECOMMENDS[@common]="emacs gnome-tweak-tool gparted mc net-tools rsync screen zip"
#-------------------------------------------------------------------------------
PACKAGES[Ubuntu_@common]="diffuse gnupg gnupg2 htop iputils-ping tofrodos unp vim xz-utils"
RECOMMENDS[Ubuntu_@common]="aptitude synaptic"
#-------------------------------------------------------------------------------
PACKAGES[RHEL_@common]="gnupg2 vim-enhanced"
RECOMMENDS[RHEL-6_@common]="-gnome-tweak-tool"
PACKAGES[RHEL-7_@common]="NetworkManager-tui xz"
PACKAGES[Fedora_@common]="[RHEL-7_@common]"
RECOMMENDS[Fedora_@common]="[RHEL_@common] diffuse"
#-------------------------------------------------------------------------------
PACKAGES[openSUSE_@common]="gpg2 vim xz"
RECOMMENDS[openSUSE_@common]="mlocate gnome-tweak-tool"
RECOMMENDS[openSUSE-999_@common]="net-tools-deprecated"

#===============================================================================
# Docker packages
#===============================================================================
PACKAGES[RHEL_@docker]="docker"
PACKAGES[openSUSE_@docker]="docker"
PACKAGES[Ubuntu_@docker]="docker.io"
PACKAGES[Ubuntu-12.04_@docker]="-docker.io"
PACKAGES[Debian_@docker]="[Ubuntu-12.04_@docker]"
PACKAGES[Debian-999_@docker]="docker.io"

#===============================================================================
# Embedded packages
#===============================================================================
PACKAGES[@embedded]="bc lzop screen"
RECOMMENDS[@embedded]="minicom"
#-------------------------------------------------------------------------------
RECOMMENDS[Fedora_@embedded]="cutecom"
PACKAGES[CentOS_@embedded]="dnsmasq dtc glibc-static nfs-utils"
RECOMMENDS[CentOS_@embedded]="uboot-tools"
PACKAGES[CentOS-7_@embedded]="-dtc"
RECOMMENDS[CentOS-7_@embedded]="-uboot-tools"
#-------------------------------------------------------------------------------
PACKAGES[openSUSE_@embedded]="dtc nfs-kernel-server"
RECOMMENDS[openSUSE_@embedded]="cutecom u-boot-tools"
RECOMMENDS[openSUSE-42.1_@embedded]="-cutecom"
#-------------------------------------------------------------------------------
PACKAGES[Ubuntu_@embedded]="device-tree-compiler dnsmasq-base dosfstools eject
	gperf mtd-utils nfs-kernel-server parted"
RECOMMENDS[Ubuntu_@embedded]="cutecom u-boot-tools"

#===============================================================================
# Kernel related packages
#===============================================================================
PACKAGES[@kernel]="crash cscope gitk sysfsutils indent"
#-------------------------------------------------------------------------------
PACKAGES[Debian_@kernel]="exuberant-ctags libfuse-dev libssl-dev
	manpages-dev nfs-common"
RECOMMENDS[Debian_@kernel]="libglade2-dev libgtk2.0-dev qt4-default sparse
	symlinks"
PACKAGES[Ubuntu_@kernel]="[Debian_@kernel] hugepages libhugetlbfs-dev linux-crashdump"
PACKAGES[Ubuntu-12.04_@kernel]="libncurses5-dev -qt4-default"
PACKAGES[Ubuntu-14.04_@kernel]="liblzo2-dev"
PACKAGES[Ubuntu-16.04_@kernel]="[Ubuntu-14.04_@kernel]"
RECOMMENDS[Ubuntu-16.04_@kernel]="qt4-dev-tools"
#-------------------------------------------------------------------------------
RECOMMENDS[LinuxMint-17_@kernel]="qt4-default libglade2-dev"
#-------------------------------------------------------------------------------
PACKAGES[Debian-7_@kernel]="[Ubuntu-12.04_@kernel]"
PACKAGES[Debian-8_@kernel]="[Ubuntu-14.04_@kernel]"
#-------------------------------------------------------------------------------
PACKAGES[RHEL_@kernel]="ctags fuse-devel kernel-devel libhugetlbfs-devel
	ncurses-devel nfs-utils"
RECOMMENDS[RHEL_@kernel]="gtk2-devel libglade2-devel qt-devel slang-devel sparse"
#-------------------------------------------------------------------------------
PACKAGES[openSUSE_@kernel]="ctags fuse-devel kernel-devel lzo-devel
	libhugetlbfs ncurses-devel"
RECOMMENDS[openSUSE_@kernel]="gtk2-devel libglade2-devel libopenssl-devel slang-devel sparse"
PACKAGES[openSUSE-999_@kernel]="libhugetlbfs-devel"

#===============================================================================
# Kernel dump related packages
#===============================================================================
PACKAGES[@kdump]="crash kexec-tools"
#-------------------------------------------------------------------------------
PACKAGES[Debian_@kdump]="kdump-tools"
PACKAGES[Ubuntu_@kdump]="[Debian_@kdump] linux-crashdump"
#-------------------------------------------------------------------------------
PACKAGES[openSUSE_@kdump]="kdump yast2-kdump"

#===============================================================================
# Stress packages
#===============================================================================
PACKAGES[Debian_@stress]="stress stress-ng"
PACKAGES[Debian-7_@stress]="-stress-ng"
PACKAGES[Ubuntu-12.04_@stress]="[Debian-7_@stress]"
PACKAGES[Ubuntu-14.04_@stress]="[Ubuntu-12.04_@stress]"
PACKAGES[RHEL-6_@stress]="stress"
PACKAGES[RHEL-7_@stress]="stress-ng"
PACKAGES[Fedora_@stress]="stress"
PACKAGES[Fedora-26_@stress]="-stress stress-ng"
PACKAGES[openSUSE_@stress]="stress-ng"
PACKAGES[openSUSE-13.2_@stress]="-stress-ng"
PACKAGES[openSUSE-42.1_@stress]="[openSUSE-13.2_@stress]"

#===============================================================================
# Sysadm related packages
#===============================================================================
PACKAGES[@sysadm]="bonnie++ collectl dstat gnuplot libtool m4 mdadm memtest86+
	mlocate sysstat"
PACKAGES[Ubuntu_@sysadm]="iftop"
PACKAGES[openSUSE_@sysadm]="bonnie -dstat termcap"

#===============================================================================
# Trace/perf related packages
#===============================================================================
PACKAGES[@trace]="iotop strace trace-cmd"
PACKAGES[Debian_@trace]="ltrace"
PACKAGES[Debian-7_@trace]="-kernelshark linux-tools -trace-cmd"
PACKAGES[Debian-8_@trace]="kernelshark"
PACKAGES[Debian-999_@trace]="kernelshark linux-perf"
PACKAGES[Ubuntu_@trace]="kernelshark ltrace -linux-tools linux-tools-generic"
PACKAGES[Ubuntu-12.04_@trace]="-linux-tools-generic"
PACKAGES[RHEL_@trace]="perf"
PACKAGES[Fedora_@trace]="kernelshark perf"
PACKAGES[openSUSE_@trace]="kernelshark perf"

#===============================================================================
# Virt related packages
#===============================================================================
PACKAGES[@virt]="qemu-kvm virt-manager"
PACKAGES[Debian_@virt]="libvirt-daemon-system libvirt-clients"
PACKAGES[Ubuntu_@virt]="libvirt-bin"
PACKAGES[RHEL_@virt]="libvirt"
PACKAGES[openSUSE_@virt]="[RHEL_@virt] libvirt-client libvirt-daemon"
PACKAGES[openSUSE-13.2_@virt]="-qemu-kvm"

#===============================================================================
# Extra requirements for LFD301
#===============================================================================
TITLE[LFD301]="Introduction to Linux for Developers and GIT"
WEBPAGE[LFD301]="$LFDTRAINING/introduction-to-linux-for-developers"
INTERNET[LFD301]="$REQUIRED"
#-------------------------------------------------------------------------------
PACKAGES[LFD301]="@build @common @stress @sysadm @trace 
	cvs gparted lvm2 subversion sysstat tcpdump wireshark"
RECOMMENDS[LFD301]="iptraf-ng gnome-system-monitor ksysguard yelp"
PACKAGES[Debian_LFD301]="git-cvs git-daemon-sysvinit git-gui git-svn gitk gitweb
	libcurl4-openssl-dev libexpat1-dev libssl-dev"
RECOMMENDS[Debian_LFD301]="default-jdk"
RECOMMENDS[Ubuntu-12.04_LFD301]="-iptraf-ng iptraf"
PACKAGES[RHEL_LFD301]="git-all expat-devel openssl-devel"
RECOMMENDS[RHEL-6_LFD301]="-iptraf-ng iptraf kdebase -ksysguard ksysguardd"
PACKAGES[Fedora_LFD301]="[RHEL_LFD301]"
RECOMMENDS[Fedora_LFD301]="[RHEL_LFD301]"
RECOMMENDS[openSUSE_LFD301]="kdebase4-workspace -ksysguard"

#===============================================================================
# Extra requirements for LFD401
#===============================================================================
TITLE[LFD401]="Developing Applications for Linux"
WEBPAGE[LFD401]="$LFDTRAINING/developing-applications-for-linux"
#-------------------------------------------------------------------------------
PACKAGES[LFD401]="@build @common valgrind ddd sysstat"
PACKAGES[Ubuntu_LFD401]="electric-fence kcachegrind"
PACKAGES[RHEL_LFD401]="ElectricFence"
PACKAGES[Fedora_LFD401]="[RHEL_LFD401] kcachegrind"
PACKAGES[openSUSE_LFD401]="[Fedora_LFD401]"

#===============================================================================
# Extra requirements for LFD415
#===============================================================================
TITLE[LFD415]="Inside Android: An Intro to Android Internals"
WEBPAGE[LFD415]="$LFDTRAINING/inside-android-an-intro-to-android-internals"
VIRTUAL[LFD415]=n
ARCH[LFD415]=x86_64
CPUS[LFD415]=4
PREFER_CPUS[LFD415]=8
BOGOMIPS[LFD415]=10000
RAM[LFD415]=8
DISK[LFD415]=150
#DISTRO_ARCH[LFD415]=x86_64
INTERNET[LFD415]="$REQUIRED"
CARDREADER[LFD415]="$PROVIDED"
NATIVELINUX[LFD415]="$RECOMMENDED"
VMOKAY[LFD415]="$DISCOURAGED"
DISTROS[LFD415]="Ubuntu:amd64-14.04"
DISTRO_DEFAULT[LFD415]="Ubuntu-14.04"
RUNCODE[LFD415-12.04]=lfd415_1204_extra
INCLUDES[LFD415]="$BBBLCDKITIMG"
enable_extras "LFD415"
#===============================================================================
PACKAGES[LFD415]="@build @common @embedded vinagre"
#-------------------------------------------------------------------------------
PACKAGES[Ubuntu_LFD415]="ant gcc-multilib g++-multilib lib32ncurses5-dev lib32z1-dev
	libc6-dev-i386 libgl1-mesa-dev libx11-dev libxml2-utils python-markdown
	x11proto-core-dev xsltproc zlib1g-dev"
#PACKAGES[Ubuntu-12.04_LFD415]="libgl1-mesa-glx:i386 libncurses5-dev:i386
#	libreadline6-dev:i386 libx11-dev:i386 mingw32 zlib1g-dev:i386"
PACKAGES[Ubuntu-14.04_LFD415]="mingw32 openjdk-7-jdk"
PACKAGES[Ubuntu-16.04_LFD415]="openjdk-8-jdk"
#-------------------------------------------------------------------------------
#PACKAGES[Debian-7_LFD415]="ant libreadline6 libsdl-image1.2 libx11-dev zlib1g-dev"
#PACKAGES[Debian-999_LFD415]="-mingw32"
#-------------------------------------------------------------------------------
#PACKAGES[openSUSE_LFD415]="Mesa-devel libxml2-devel libxml2-tools
#    python-Markdown xorg-x11-proto-devel ant readline-devel"
#PACKAGES[openSUSE-13.2_LFD415]="-xorg-x11-proto-devel"
#-------------------------------------------------------------------------------
#PACKAGES[RHEL_LFD415]="libxml2-devel xorg-x11-proto-devel ant readline-devel"
#===============================================================================
lfd415_1204_extra() {
    local ACTIVITY=$1

    verbose "Running ldf415_extra for $ACTIVITY"
    GLSO=/usr/lib/i386-linux-gnu/libGL.so
    GLSOVER=/usr/lib/i386-linux-gnu/mesa/libGL.so.1
    if [[ -e $GLSOVER && ! -e $GLSO || -n $SIMULATE_FAILURE ]] ; then
        if [[ -z $INSTALL ]] ; then
            warn "Need to add missing symlink for libGL.so"
            fix_missing "You can do so" \
                "$0 --install $ACTIVITY" \
                "sudo ln -s $GLSOVER $GLSO"
        else
            notice "Adding missing symlink for libGL.so"
            sudo ln -s $GLSOVER $GLSO
        fi
    fi
}

#===============================================================================
# Extra requirements for LFD420
#===============================================================================
TITLE[LFD420]="Linux Kernel Internals and Debugging"
WEBPAGE[LFD420]="$LFDTRAINING/linux-kernel-internals-and-debugging"
BOOT[LFD420]=128	# Room for 2 more kernels
DISK[LFD420]=9
#VMOKAY[LFD420]="$VMPREFERRED"
#-------------------------------------------------------------------------------
PACKAGES[LFD420]="@build @common @kernel @stress @trace"

#===============================================================================
# Extra requirements for LFD430
#===============================================================================
TITLE[LFD430]="Developing Linux Device Drivers"
WEBPAGE[LFD430]="$LFDTRAINING/developing-linux-device-drivers"
PREREQ[LFD430]="LFD420"
BOOT[LFD430]=128	# Room for 2 more kernels
DISK[LFD430]=9
#VMOKAY[LFD430]="$VMPREFERRED"
#-------------------------------------------------------------------------------
PACKAGES[LFD430]="[LFD420]"

#===============================================================================
# Extra requirements for LFD432
#===============================================================================
TITLE[LFD432]="Optimizing Device Drivers for Power Efficiency"
WEBPAGE[LFD432]="$LFDTRAINING/optimizing-linux-device-drivers-for-power-efficiency"
PREREQ[LFD432]="LFD420"
VIRTUAL[LFD432]=n
#------------------------------------------------------------------------------n
PACKAGES[LFD432]="[LFD420] @kdump gkrellm"
PACKAGES[Ubuntu_LFD432]="lm-sensors xsensors"
PACKAGES[openSUSE_LFD432]="sensors"
PACKAGES[RHEL_LFD432]="xsensors"

#===============================================================================
# Extra requirements for LFD435
#===============================================================================
TITLE[LFD435]="Embedded Linux Device Drivers"
WEBPAGE[LFD435]="$LFDTRAINING/developing-embedded-linux-device-drivers"
PREREQ[LFD435]="LFD420"
VIRTUAL[LFD435]=n
BOOT[LFD435]=128	# Room for 2 more kernels
DISK[LFD435]=10
CARDREADER[LFD435]="$PROVIDED"
NATIVELINUX[LFD435]="$RECOMMENDED"
VMOKAY[LFD435]="$DISCOURAGED"
# shellcheck disable=SC2034
INCLUDES[LFD435]="$BBBKITIMG"
#-------------------------------------------------------------------------------
PACKAGES[LFD435]="[LFD420] @embedded"

#===============================================================================
# Extra requirements for LFD440
#===============================================================================
TITLE[LFD440]="Linux Kernel Debugging and Security"
WEBPAGE[LFD440]="$LFDTRAINING/linux-kernel-debugging-and-security"
PREREQ[LFD440]="LFD420"
BOOT[LFD440]=128	# Room for 2 more kernels
DISK[LFD440]=9
#VMOKAY[LFD440]="$VMPREFERRED"
#-------------------------------------------------------------------------------
PACKAGES[LFD440]="[LFD420] @kdump"
PACKAGES[Ubuntu_LFD440]="policycoreutils"
RECOMMENDS[Ubuntu_LFD440]="libdw-dev libaudit-dev libelf-dev binutils-dev
	libnuma-dev liblzma-dev"
RECOMMENDS[Ubuntu-16.04_LFD440]="libunwind-dev"

#===============================================================================
# Extra requirements for LFD450
#===============================================================================
TITLE[LFD450]="Embedded Linux Development"
WEBPAGE[LFD450]="$LFDTRAINING/embedded-linux-development"
VIRTUAL[LFD450]=n
ARCH[LFD450]=x86_64
CPUS[LFD450]=2
PREFER_CPUS[LFD450]=4
BOGOMIPS[LFD450]=5000
RAM[LFD450]=2
DISK[LFD450]=30
INTERNET[LFD450]="$REQUIRED"
CARDREADER[LFD450]="$PROVIDED"
NATIVELINUX[LFD450]="$RECOMMENDED"
VMOKAY[LFD450]="$DISCOURAGED"
INCLUDES[LFD450]="$BBBKITIMG"
#-------------------------------------------------------------------------------
PACKAGES[LFD450]="@build @common @embedded @kernel @trace help2man gperf rsync"
PACKAGES[Ubuntu_LFD450]="libtool squashfs-tools"
RECOMMENDS[Ubuntu_LFD450]="libpython-dev"
PACKAGES[Ubuntu-12.04_LFD450]="-libpython-dev"
PACKAGES[Ubuntu-14.04_LFD450]="libtool"
PACKAGES[Ubuntu-16.04_LFD450]="libtool-bin"
RECOMMENDS[RHEL_LFD450]="python-devel"
RECOMMENDS[Fedora_LFD450]="[RHEL_LFD450] perl-ExtUtils-MakeMaker python3-devel"
RECOMMENDS[Fedora-26]="-python-devel python2-devel"

#===============================================================================
# Extra requirements for LFD455
#===============================================================================
#TITLE[LFD455]="Advanced Embedded Linux Development"
#WEBPAGE[LFD455]="$LFDTRAINING/embedded-linux-development"
#PREREQ[LFD455]="LFD435 LFD450"
#VIRTUAL[LFD455]=n
#CPUS[LFD455]=2
#PREFER_CPUS[LFD455]=4
#BOGOMIPS[LFD455]=3000
#RAM[LFD455]=2
#DISK[LFD455]=30
#INTERNET[LFD455]="$REQUIRED"
#CARDREADER[LFD455]="$PROVIDED"
#NATIVELINUX[LFD455]="$RECOMMENDED"
#VMOKAY[LFD455]="$DISCOURAGED"
#INCLUDES[LFD455]="$BBBKITIMG"
#-------------------------------------------------------------------------------
#COPYPACKAGES[LFD455]="LFD450"

#===============================================================================
# Extra requirements for LFD460
#===============================================================================
TITLE[LFD460]="Building Embedded Linux with the Yocto Project"
WEBPAGE[LFD460]="$LFDTRAINING/embedded-linux-development-with-yocto-project"
PREREQ[LFD460]="LFD450"
VIRTUAL[LFD460]=n
CPUS[LFD460]=4
PREFER_CPUS[LFD460]=8
BOGOMIPS[LFD460]=20000
RAM[LFD460]=4
DISK[LFD460]=100
INTERNET[LFD460]="$REQUIRED"
CARDREADER[LFD460]="$PROVIDED"
NATIVELINUX[LFD460]="$RECOMMENDED"
VMOKAY[LFD460]="$DISCOURAGED"
# shellcheck disable=SC2034
INCLUDES[LFD460]="$BBBKITIMG"
SYMLINKS[LFD460]="/usr/bin/python:!^/opt/"
#VERSIONS[LFD460]="python:<3"
enable_extras "LFD460"
#-------------------------------------------------------------------------------
PACKAGES[LFD460]="@build @common @embedded chrpath cpio diffstat
	python python-ply python-progressbar socat xterm"
#-------------------------------------------------------------------------------
PACKAGES[Ubuntu_LFD460]="daemon gcc-multilib libarchive-dev libglib2.0-dev libxml2-utils
        python-pexpect python3-pexpect python-sqlite libsdl2-dev python3-progressbar
	python3 python3-pip python3-ply sqlite3 xsltproc"
RECOMMENDS[Ubuntu_LFD460]="default-jre"
PACKAGES[Ubuntu-12.04_LFD460]="-libsdl2-dev -python3-pip -python3-pexpect -python3-progressbar"
PACKAGES[Ubuntu-14.04_LFD460]="libnfs1 libsdl1.2-dev"
PACKAGES[Ubuntu-16.04_LFD460]="libnfs8"
PACKAGES[Debian-7_LFD460]="[Ubuntu-14.04_LFD460] -python3-pexpect -python3-progressbar"
PACKAGES[Debian-8_LFD460]="libnfs4"
PACKAGES[Debian-9_LFD460]="[Ubuntu-16.04_LFD460]"
PACKAGES[RHEL_LFD460]="cpp daemonize diffutils libarchive-devel pexpect 
	perl tar SDL-devel sqlite which"
PACKAGES[RHEL-7_LFD460]="perl-Data-Dumper perl-Text-ParseWords perl-Thread-Queue"
PACKAGES[Fedora_LFD460]="[RHEL-7_LFD460] cpp daemonize diffutils findutils
	libarchive-devel perl perl-bignum python3 python3-pexpect python3-pip
	python3-ply SDL-devel which"
PACKAGES[Fedora-24_LFD460]="python-pexpect"
PACKAGES[Fedora-24_LFD460]="-python-ply"
PACKAGES[Fedora-26_LFD460]="-python -python-ply"
PACKAGES[Fedora-999_LFD460]="[Fedora-26_LFD460] -python-progressbar"
PACKAGES[openSUSE_LFD460]="libarchive-devel libSDL-devel python3 python3-curses
	python3-pexpect python3-pip python3-ply python-curses python-xml which"
PACKAGES[openSUSE-13.2_LFD460]="-python-pexpect -python3-pexpect"
PACKAGES[openSUSE-42.2_LFD460]="libnfs8"
PACKAGES[openSUSE-999_LFD460]="-python-ply"

#===============================================================================
# Extra requirements for LFD461
#===============================================================================
TITLE[LFD461]="KVM for Developers"
WEBPAGE[LFD461]="$LFDTRAINING/kvm-for-developers"
#-------------------------------------------------------------------------------
PACKAGES[LFD461]="@build @common @trace @virt"
#-------------------------------------------------------------------------------
PACKAGES[Ubuntu_LFD461]="g++"
PACKAGES[Debian_LFD461]="[Ubuntu_LFD461]"
PACKAGES[LinuxMint_LFD461]="[Ubuntu_LFD461]"
PACKAGES[RHEL_LFD461]="kernel-devel"
PACKAGES[CentOS_LFD461]="[RHEL_LFD461]"
PACKAGES[Fedora_LFD461]="[RHEL_LFD461]"
PACKAGES[openSUSE_LFD461]="[RHEL_LFD461]"

#===============================================================================
#=== End of LFD Course Definitions =============================================
#===============================================================================

#===============================================================================
# Extra requirements for LFS101x
#===============================================================================
TITLE[LFS101x]="Introduction to Linux"
WEBPAGE[LFS101x]="$LFSTRAINING/introduction-to-linux"
INPERSON[LFS101x]=n
VIRTUAL[LFS101x]=n
SELFPACED[LFS101x]=y
MOOC[LFS101x]=y
INTERNET[LFS101x]="$REQUIRED"
#-------------------------------------------------------------------------------
PACKAGES[LFS101x]="@common @sysadm"

#===============================================================================
# Extra requirements for LFS151
#===============================================================================
TITLE[LFS151]="Introduction to Cloud Infrastructure Technologies"
WEBPAGE[LFS151]="$LFSTRAINING/introduction-to-cloud-infrastructure-technologies"
INPERSON[LFS151]=n
VIRTUAL[LFS151]=n
SELFPACED[LFS151]=y
INTERNET[LFS151]="$REQUIRED"
#-------------------------------------------------------------------------------
PACKAGES[LFS151]="@common"

#===============================================================================
# Extra requirements for LFS152
#===============================================================================
TITLE[LFS152]="Introduction to OpenStack"
WEBPAGE[LFS152]="$LFSTRAINING/introduction-to-openstack"
INPERSON[LFS152]=n
VIRTUAL[LFS152]=n
SELFPACED[LFS152]=y
INTERNET[LFS152]="$REQUIRED"
#-------------------------------------------------------------------------------
OS[LFS152]="$ANYOS"
OS_NEEDS[LFS152]="$REMOTE_NEEDS"

#===============================================================================
# Extra requirements for LFS161
#===============================================================================
TITLE[LFS161]="Introduction to DevOps: Transforming and Improving Operations"
WEBPAGE[LFS161]="$LFSTRAINING/introduction-to-devops-transforming-and-improving"
INPERSON[LFS161]=n
VIRTUAL[LFS161]=n
SELFPACED[LFS161]=y
INTERNET[LFS161]="$REQUIRED"
#-------------------------------------------------------------------------------
OS[LFS161]="$ANYOS"
OS_NEEDS[LFS161]="$REMOTE_NEEDS"
#-------------------------------------------------------------------------------
PACKAGES[LFS161]="@common"

#===============================================================================
# Extra requirements for LFS201
#===============================================================================
TITLE[LFS201]="Essentials of System Administration"
WEBPAGE[LFS201]="$LFSTRAINING/essentials-of-system-administration"
INSTR_LED_CLASS[LFS201]="LFS301"
#-------------------------------------------------------------------------------
INPERSON[LFS201]=n
VIRTUAL[LFS201]=n
SELFPACED[LFS201]=y
PACKAGES[LFS201]="@build @common @sysadm @trace cryptsetup lvm2 quota xfsprogs"
PACKAGES[Debian_LFS201]="btrfs-tools"
PACKAGES[Debian-999_LFS201]="-btrfs-tools btrfs-progs"
PACKAGES[RHEL_LFS201]="btrfs-progs"
PACKAGES[RHEL-6_LFS201]="-cryptsetup"

#===============================================================================
# Extra requirements for LFS211
#===============================================================================
TITLE[LFS211]="Linux Networking and Administration"
WEBPAGE[LFS211]="$LFSTRAINING/linux-network-and-administration"
INPERSON[LFS211]=n
VIRTUAL[LFS211]=n
SELFPACED[LFS211]=y
INSTR_LED_CLASS[LFS211]="LFS311"
#-------------------------------------------------------------------------------
PACKAGES[LFS211]="@build @common @sysadm @trace ftp mutt nmap postfix vsftpd"
PACKAGES[Ubuntu_LFS211]="bsd-mailx dovecot-imapd dovecot-lmtpd dovecot-pop3d
	openssh-server"
RECOMMENDS[Ubuntu_LFS211]="zenmap"
PACKAGES[RHEL_LFS211]="dovecot mailx openssh-server"
PACKAGES[openSUSE_LFS211]="dovecot22 mailx openssh"
RECOMMENDS[openSUSE_LFS211]="zenmap"
PACKAGES[openSUSE-13.2_LFS211]="-dovecot22"

#===============================================================================
# Extra requirements for LFS216
#===============================================================================
TITLE[LFS216]="Linux Security Fundamentals"
WEBPAGE[LFS216]="$LFSTRAINING/linux-security-fundamentals"
INPERSON[LFS216]=n
VIRTUAL[LFS216]=n
SELFPACED[LFS216]=y
INSTR_LED_CLASS[LFS216]="LFS416"
#ARCH[LFS216]=x86_64
CPUS[LFS216]=4
BOGOMIPS[LFS216]=20000
RAM[LFS216]=8
DISK[LFS216]=30
INTERNET[LFS216]="$REQUIRED"
CPUFLAGS[LFS216]=vmx
CONFIGS[LFS216]="HAVE_KVM KSM"
NATIVELINUX[LFS216]="$REQUIRED"
VMOKAY[LFS216]="$VMNOTOKAY"
enable_extras "LFS216"
VMS[LFS216]="CentOS7 Ubuntu-16-04"
#-------------------------------------------------------------------------------
PACKAGES[LFS216]="@build @common @virt"
#-------------------------------------------------------------------------------
PACKAGES[Ubuntu_LFS216]="apache2-utils"
PACKAGES[RHEL_LFS216]="kernel-devel"
PACKAGES[openSUSE_LFS216]="[RHEL_LFS216]"

#===============================================================================
# Extra requirements for LFS232
#===============================================================================
TITLE[LFS232]="Cloud Foundry for Developers"
WEBPAGE[LFS232]="$LFSTRAINING/cloud-foundry-for-developers"
INPERSON[LFS232]=n
VIRTUAL[LFS232]=n
SELFPACED[LFS232]=y
#-------------------------------------------------------------------------------
OS[LFS232]="$ANYOS"
OS_NEEDS[LFS232]="$REMOTE_NEEDS, Cloud Foundry CLI"
#-------------------------------------------------------------------------------
#ARCH[LFS232]=x86_64
INTERNET[LFS232]="$REQUIRED"
#PACKAGES[LFS232]="@common"

#===============================================================================
# Extra requirements for LFS252
#===============================================================================
TITLE[LFS252]="OpenStack Administration Fundamentals"
WEBPAGE[LFS252]="$LFSTRAINING/openstack-administration-fundamentals"
PREREQ[LFS252]="LFS152"
INPERSON[LFS252]=n
VIRTUAL[LFS252]=n
SELFPACED[LFS252]=y
#-------------------------------------------------------------------------------
OS[LFS252]="$ANYOS"
OS_NEEDS[LFS252]="$REMOTE_NEEDS"
INTERNET[LFS252]="$REQUIRED"

#===============================================================================
# Extra requirements for LFS253
#===============================================================================
TITLE[LFS253]="Containers Fundamentals"
WEBPAGE[LFS253]="$LFSTRAINING/containers-fundamentals"
INPERSON[LFS253]=n
VIRTUAL[LFS253]=n
SELFPACED[LFS253]=y
#-------------------------------------------------------------------------------
OS[LFS253]="$ANYOS"
OS_NEEDS[LFS253]="$REMOTE_NEEDS"
#-------------------------------------------------------------------------------
INTERNET[LFS253]="$REQUIRED"
DISTROS[LFS253]="${DISTROS[LFD]}"
PACKAGES[LFS253]="@docker"

#===============================================================================
# Extra requirements for LFS254
#===============================================================================
TITLE[LFS254]="Containers for Developers and Quality Assurance"
WEBPAGE[LFS254]="$LFSTRAINING/containers-for-developers-and-quality-assurance"
PREREQ[LFS254]="LFS253"
INPERSON[LFS254]=n
VIRTUAL[LFS254]=n
SELFPACED[LFS254]=y
#-------------------------------------------------------------------------------
OS[LFS254]="$ANYOS"
OS_NEEDS[LFS254]="$REMOTE_NEEDS, Docker"
#-------------------------------------------------------------------------------
INTERNET[LFS254]="$REQUIRED"
DISTROS[LFS254]="${DISTROS[LFD]}"
PACKAGES[LFS254]="@docker"

#===============================================================================
# Extra requirements for LFS258
#===============================================================================
TITLE[LFS258]="Kubernetes Fundamentals"
WEBPAGE[LFS258]="$LFSTRAINING/kubernetes-fundamentals"
INPERSON[LFS258]=n
VIRTUAL[LFS258]=n
SELFPACED[LFS258]=y
RAM[LFS258]=4
#-------------------------------------------------------------------------------
OS[LFS258]="$UNIXOS"
OS_NEEDS[LFS258]="$REMOTE_NEEDS, VirtualBox, Kubernetes CLI (kubectl)"
#-------------------------------------------------------------------------------
INTERNET[LFS258]="$REQUIRED"
PACKAGES[Ubuntu_LFS258]="virtualbox"
PACKAGES[Debian-9_LFS258]="-virtualbox"
PACKAGES[openSUSE_LFS258]="virtualbox"

#===============================================================================
# Extra requirements for LFS265
#===============================================================================
TITLE[LFS265]="Software Defined Networking Fundamentals"
WEBPAGE[LFS265]="$LFSTRAINING/software-defined-networking-fundamentals"
INPERSON[LFS265]=n
VIRTUAL[LFS265]=n
SELFPACED[LFS265]=y
INSTR_LED_CLASS[LFS265]="LFS465"
CPUS[LFS265]=2
PREFER_CPUS[LFS265]=4
BOGOMIPS[LFS265]=10000
RAM[LFS265]=4
DISK[LFS265]=20
CONFIGS[LFS265]=OPENVSWITCH
DISTROS[LFS265]=Ubuntu:amd64-16.04
DISTRO_DEFAULT[LFS265]=Ubuntu-16.04
#-------------------------------------------------------------------------------
PACKAGES[LFS265]="@common"
#-------------------------------------------------------------------------------
PACKAGES[Ubuntu_LFS265]="default-jre libxml2-dev libxslt1-dev maven mininet
	openvswitch-switch openvswitch-test openvswitch-testcontroller
	python-openvswitch snmp snmpd tshark wireshark wireshark-doc"
RECOMMENDS[Ubuntu_LFS265]="build-dep_wireshark"
PACKAGES[Ubuntu-12.04_LFS265]="-mininet -openvswitch-testcontroller"
PACKAGES[Ubuntu-14.04_LFS265]="-openvswitch-testcontroller"
PACKAGES[Debian_LFS265]="-" # Forcing empty list so it doesn't fallback to Ubuntu
PACKAGES[Debian-999_LFS265]="[Ubuntu_LFS265]"
PACKAGES[LinuxMint_LFS265]="-"

#===============================================================================
# Extra requirements for LFS300
#===============================================================================
TITLE[LFS300]="Fundamentals of Linux"
WEBPAGE[LFS300]="$LFSTRAINING/fundamentals-of-linux"
#-------------------------------------------------------------------------------
PACKAGES[LFS300]="@common"

#===============================================================================
# Extra requirements for LFS301
#===============================================================================
TITLE[LFS301]="Linux System Administration"
WEBPAGE[LFS301]="$LFSTRAINING/linux-system-administration"
SELFPACED_CLASS[LFS301]="LFS201"
#-------------------------------------------------------------------------------
COPYPACKAGES[LFS301]="LFS201"

#===============================================================================
# Extra requirements for LFS311
#===============================================================================
TITLE[LFS311]="Advanced Linux System Administration and Networking"
WEBPAGE[LFS311]="$LFSTRAINING/advanced-linux-system-administration-and-networking"
SELFPACED_CLASS[LFS311]="LFS211"
#-------------------------------------------------------------------------------
COPYPACKAGES[LFS311]="LFS211"

#===============================================================================
# Extra requirements for LFS416
#===============================================================================
TITLE[LFS416]="Linux Security"
WEBPAGE[LFS416]="$LFSTRAINING/linux-security"
SELFPACED_CLASS[LFS416]="LFS216"
#ARCH[LFS416]=x86_64
CPUS[LFS416]=4
BOGOMIPS[LFS416]=20000
RAM[LFS416]=8
DISK[LFS416]=30
INTERNET[LFS416]="$REQUIRED"
CPUFLAGS[LFS416]=vmx
CONFIGS[LFS416]="HAVE_KVM KSM"
NATIVELINUX[LFS416]="$REQUIRED"
VMOKAY[LFS416]="$VMNOTOKAY"
enable_extras "LFS416"
VMS[LFS416]="CentOS7 Ubuntu-16-04"
#-------------------------------------------------------------------------------
COPYPACKAGES[LFS416]="LFS216"

#===============================================================================
# Extra requirements for LFS422
#===============================================================================
TITLE[LFS422]="High Availability Linux Architecture"
WEBPAGE[LFS422]="$LFSTRAINING/high-availability-linux-architecture"
#ARCH[LFS422]=x86_64
CPUS[LFS422]=2
PREFER_CPUS[LFS422]=4
RAM[LFS422]=4
DISK[LFS422]=40
#DISTRO_ARCH[LFS422]=x86_64
INTERNET[LFS422]="$REQUIRED"
CPUFLAGS[LFS422]=vmx
VMOKAY[LFS422]="Acceptable (with nested virtualization)"
#DISTROS[LFS422]="Ubuntu:amd64-14.04 Ubuntu:amd64-16.04"
DISTROS[LFS422]="CentOS:amd64-7+ DebianUbuntu:amd64-14.04+LTS+"
DISTRO_BL[LFS422]="CentOS-6 Ubuntu-12.10 Ubuntu-13.04 Ubuntu-13.10 Ubuntu-14.10 Ubuntu-15.04 Ubuntu-15.10 Ubuntu-16.10 Ubuntu-17.04"
#-------------------------------------------------------------------------------
PACKAGES[LFS422]="@common @sysadm @trace @virt"

#===============================================================================
# Extra requirements for LFS426
#===============================================================================
TITLE[LFS426]="Linux Performance Tuning"
WEBPAGE[LFS426]="$LFSTRAINING/linux-performance-tuning"
#ARCH[LFS426]=x86_64
CPUS[LFS426]=2
PREFER_CPUS[LFS426]=4
BOGOMIPS[LFS426]=20000
RAM[LFS426]=2
DISK[LFS426]=5
NATIVELINUX[LFD426]="$RECOMMENDED"
VMOKAY[LFD426]="$DISCOURAGED"
#DISTRO_ARCH[LFS426]=x86_64
INTERNET[LFS426]="$REQUIRED"
#-------------------------------------------------------------------------------
PACKAGES[LFS426]="@build @common @stress @sysadm @trace @virt blktrace blktrace crash
	fio hdparm lynx mdadm sysstat systemtap valgrind"
PACKAGES[Debian_LFS426]="cpufrequtils iozone3 libaio-dev libblas-dev libncurses5-dev
	nfs-kernel-server zlib1g-dev"
PACKAGES[Debian-999_LFS426]="lmbench"
PACKAGES[Ubuntu_LFS426]="[Debian_LFS426] hugepages lmbench nfs-kernel-server oprofile"
PACKAGES[Ubuntu-12.04_LFS426]="-oprofile"
PACKAGES[RHEL_LFS426]="blas-devel kernel-devel libaio-devel libhugetlbfs-utils
	ncurses-devel oprofile perl-Time-HiRes zlib-devel"
PACKAGES[RHEL-6_LFS426]="cpufrequtils"
PACKAGES[RHEL-7_LFS426]="-"
PACKAGES[openSUSE_LFS426]="blas-devel kernel-devel libaio-devel ncurses-devel
	nfs-kernel-server oprofile zlib-devel zlib-devel-static"
PACKAGES[openSUSE-42.1_LFS426]="iozone"
PACKAGES[openSUSE-42.2_LFS426]="[openSUSE-42.1_LFS426]"
PACKAGES[openSUSE-999_LFS426]="[openSUSE-42.1_LFS426]"

#===============================================================================
# Extra requirements for LFS430
#===============================================================================
TITLE[LFS430]="Linux Enterprise Automation"
WEBPAGE[LFS430]="$LFSTRAINING/linux-enterprise-automation"
#-------------------------------------------------------------------------------
PACKAGES[LFS430]="@build @common @sysadm @trace"

#===============================================================================
# Extra requirements for LFS452
#===============================================================================
TITLE[LFS452]="Essentials of OpenStack Administration"
WEBPAGE[LFS452]="$LFSTRAINING/essentials-of-openstack-administration"
#-------------------------------------------------------------------------------
INTERNET[LFS452]="$REQUIRED"
PACKAGES[LFS452]="@common @sysadm"
#-------------------------------------------------------------------------------
OS[LFS452]="$ANYOS"
OS_NEEDS[LFS452]="$REMOTE_NEEDS"

#===============================================================================
# Extra requirements for LFS462
#===============================================================================
TITLE[LFS462]="Introduction to Linux KVM Virtualization"
WEBPAGE[LFS462]="$LFSTRAINING/linux-kvm-virtualization"
CPUS[LFS462]=2
PREFER_CPUS[LFS462]=4
BOGOMIPS[LFS462]=10000
RAM[LFS462]=4
DISK[LFS462]=40
CPUFLAGS[LFS462]=vmx
CONFIGS[LFS462]="HAVE_KVM KSM"
NATIVELINUX[LFS462]="$REQUIRED"
VMOKAY[LFS462]="This course can't be run on a VM"
#-------------------------------------------------------------------------------
PACKAGES[LFS462]="@build @common @virt"
#-------------------------------------------------------------------------------
PACKAGES[Ubuntu_LFS462]="g++"
PACKAGES[Ubuntu-17.04_LFS462]="ebtables firewalld"
PACKAGES[RHEL_LFS462]="kernel-devel"
PACKAGES[openSUSE_LFS462]="[RHEL_LFS462]"

#===============================================================================
# Extra requirements for LFS465
#===============================================================================
TITLE[LFS465]="Software Defined Networking with OpenDaylight"
WEBPAGE[LFS465]="$LFSTRAINING/software-defined-networking-with-opendaylight"
SELFPACED_CLASS[LFS465]="LFS265"
CPUS[LFS465]=2
PREFER_CPUS[LFS465]=4
BOGOMIPS[LFS465]=10000
RAM[LFS465]=4
DISK[LFS465]=20
CONFIGS[LFS465]="OPENVSWITCH"
DISTROS[LFS465]="Ubuntu:amd64-16.04+LTS+"
# shellcheck disable=SC2034
DISTRO_DEFAULT[LFS465]="Ubuntu-16.04"
#-------------------------------------------------------------------------------
COPYPACKAGES[LFS465]="LFS265"

#===============================================================================
#=== End of LFS Course Definitions =============================================
#===============================================================================

#==============================================================================
list_grep() {
    local REGEX
    REGEX=$(sed -e 's/\+/\\+/g' <<<$1); shift
    # shellcheck disable=SC2086
    debug 3 "list_grep REGEX=$REGEX => "$*
    sed 's/ /\n/g' <<< "$@" | egrep "$REGEX" | sort -u
}

#===============================================================================
list_sort() {
    sed 's/ /\n/g' <<< "$@" | sort -u
}

#===============================================================================
value() {
    local VAR=$1
    local ACTIVITY=$2
    local LIST
    # shellcheck disable=SC2016
    LIST='${'$VAR'['$ACTIVITY']} ${'$VAR'['${ACTIVITY:0:3}']} $'$VAR

    for V in $LIST; do
        V=$(eval echo "$V")
        if [[ -n $V ]] ; then
            echo "$V"
            return
        fi
    done
}

#===============================================================================
for_each_activity() {
    local CODE=$1; shift
    local ACTIVITIES ACTIVITY
    ACTIVITIES=$(list_sort "$@")
    debug 1 "for_each_activity: CODE=$CODE ACTIVITIES=$ACTIVITIES"
    for ACTIVITY in $ACTIVITIES ; do
        debug 2 "  for_each_activity: eval $CODE $ACTIVITY"
        eval "$CODE $ACTIVITY"
    done
}

#===============================================================================
supported_activity() {
    local ACTIVITY=$1
    [[ -n ${TITLE[$ACTIVITY]} ]] || warn "Unsupported activity: $ACTIVITY"
}


#===============================================================================
check_activity() {
    local ACTIVITY=$1
    local DESC=${TITLE[$ACTIVITY]}
    debug 1 "check_activity: ACTIVITY=$ACTIVITY"

    if [[ -z $DESC ]] ; then
        if DESC=$(get_var TITLE "$ACTIVITY") && [[ -n $DESC ]] ; then
            debug 2 "  check_activity: Custom $ACTIVITY"
        elif [[ -n ${ACTIVITY_ALIASES[$ACTIVITY]} ]] ; then
            debug 2 "  check_activity: Alias $ACTIVITY"
            ACTIVITY=${ACTIVITY_ALIASES[$ACTIVITY]}
            DESC=${TITLE[$ACTIVITY]}
        fi
        debug 2 "  check_activity: ACTIVITY=$ACTIVITY DESC=$DESC"
    fi

    if [[ -n $DESC ]] ; then
        highlight "Checking that this computer is suitable for $ACTIVITY: $DESC"
    else
        warn "Unknown \"$ACTIVITY\"; checking defaults requirements instead"
    fi
}

#===============================================================================
try_activity() {
    local ACTIVITY=$1 NEWACTIVITY=$2
    [[ -n ${TITLE[$NEWACTIVITY]} ]] || return 1
    if warn_wait "I think you meant $NEWACTIVITY (not $ACTIVITY)" ; then
        echo "$NEWACTIVITY"
    else
        echo "$ACTIVITY"
    fi
}

#===============================================================================
spellcheck_activity() {
    local ACTIVITY=$1
    local ACTIVITIES
    [[ -n $ACTIVITY ]] || return 0
    if [[ -n ${TITLE[$ACTIVITY]} ]] ; then
        echo "$ACTIVITY"
    elif ACTIVITIES=$(get_var COURSES "$ACTIVITY") && [[ -n $ACTIVITIES ]] ; then
        echo "$ACTIVITIES"
    else
        try_activity "$ACTIVITY" "${ACTIVITY/LFD/LFS}" \
            || try_activity "$ACTIVITY" "${ACTIVITY/LFS/LFD}" \
            || echo "$ACTIVITY"
    fi
}

#===============================================================================
find_activity() {
    local ACTIVITY=$1

    if [[ -n $ACTIVITY && -n ${ACTIVITY_ALIASES[$ACTIVITY]} ]] ; then
        notice "$ACTIVITY is an alias for ${ACTIVITY_ALIASES[$ACTIVITY]}"
        ACTIVITY=${ACTIVITY_ALIASES[$ACTIVITY]}
    fi
    spellcheck_activity "$ACTIVITY"
}

#===============================================================================
# List available activities
list_activities() {
    echo "Available (${#TITLE[@]}) options:"
    for D in ${!TITLE[*]}; do
        echo "  $D - ${TITLE[$D]}"
    done | sort
    exit 0
}
[[ -n $LIST_ACTIVITIES ]] && list_activities

#===============================================================================
# Try package list for all activities
try_all_activities() {
    # shellcheck disable=SC2086
    for D in $(list_sort ${!TITLE[*]}); do
        divider
        NO_PASS=1 $CMDNAME \
                ${NOCM:+--no-course-files} \
                ${NOEXTRAS:+--no-extras} \
                ${NOINSTALL:+--no-install} \
                ${NORECOMMENDS:+--no-recommends} \
                ${NOVM:+--no-vm} \
                "$D"
    done
    exit 0
}
[[ -n $TRY_ALL_ACTIVITIES ]] && try_all_activities

#===============================================================================
# shellcheck disable=SC2005,SC2046,SC2086
[[ -n $ALL_LFD ]] && COURSE=$(echo $(list_grep LFD ${!TITLE[*]}))
# shellcheck disable=SC2005,SC2046,SC2086
[[ -n $ALL_LFS ]] && COURSE=$(echo $(list_grep LFS ${!TITLE[*]}))
# shellcheck disable=SC2005,SC2046,SC2086
[[ -n $ALL_ACTIVITIES ]] && COURSE=$(echo $(list_sort ${!TITLE[*]}))

#===============================================================================
ORIG_COURSE=$COURSE
# shellcheck disable=SC2046,SC2086
COURSE=$(list_sort $(for_each_activity find_activity $COURSE))
debug 1 "main: Initial classes=$COURSE"

declare -A DISTS

#===============================================================================
distrib_list() {
    for D in ${!PACKAGES[*]}; do
        echo "$D"
    done | sed -e 's/_.*$//' | grep -- - | sort -u
}

#===============================================================================
list_distro_names() {
    local DISTS D
    DISTS=$(distrib_list)
    for D in $DISTS ; do
       if [[ -n ${DISTRO_NAMES[$D]} ]] ; then
           echo "${DISTRO_NAMES[$D]}"
       else
           echo "$D"
       fi
    done
}

#===============================================================================
distrib_ver() {
    local DID=$1 DREL=$2
    local AVAIL_INDEXES AVAIL_RELS DVER
    debug 1 "distrib_ver: DID=$DID DREL=$DREL"
    AVAIL_INDEXES=$(for D in ${!PACKAGES[*]}; do
        echo "$D"
    done | grep "$DID" | sort -ru)
    # shellcheck disable=SC2086
    debug 2 "  distrib_ver: Available package indexes for $DID:" $AVAIL_INDEXES
    AVAIL_RELS=$(for R in $AVAIL_INDEXES; do
        R=${R#*-}
        echo "${R%_*}"
    done | grep -v "^$DID" | sort -ru)
    # shellcheck disable=SC2086
    debug 2 "  distrib_ver: Available distro releases for $DID:" $AVAIL_RELS
    DVER=1
    for R in $AVAIL_RELS ; do
        if version_greater_equal "$DREL" "$R" ; then
            DVER="$R"
            break
        fi
    done
    debug 1 "  distrib_ver: We're going to use $DID-$DVER"
    echo "$DVER"
}

#===============================================================================
# Do a lookup in DB of KEY
lookup() {
    local DB=$1
    local KEY=$2
    debug 2 "  lookup: DB=$DB KEY=$KEY"
    [[ -n $KEY ]] || return
    local DATA
    DATA=$(eval "echo \${$DB[$KEY]}")
    if [[ -n $DATA ]] ; then
        debug 2 "    lookup: hit $DB[$KEY] -> $DATA"
        echo "$DATA"
        return 0
    fi
    return 1
}

#===============================================================================
# Do a lookup in DB for DIST[-RELEASE] and if not found, consult FALLBACK distros
lookup_fallback() {
    local DB=$1
    local NAME=$2
    local DIST=$3
    local RELEASE=$4
    debug 2 "  lookup_fallback: DB=$DB NAME=$NAME DIST=$DIST RELEASE=$RELEASE"
    DIST+=${RELEASE:+-$RELEASE}
    local KEY
    debug 2 "    lookup_fallback: $DIST => ${FALLBACK[${DIST:-no_distro}]}"
    for KEY in $DIST ${FALLBACK[${DIST:-no_distro}]} ; do
        KEY+=${NAME:+_$NAME}
        lookup "$DB" "$KEY" && return
    done
}

#===============================================================================
# Do a lookup in DB for NAME, DIST_NAME, DIST-RELEASE_NAME
get_db() {
    local DB=$1
    local NAME=$2
    local DIST=$3
    local RELEASE=$4
    local RESULT
    debug 3 "get_db: DB=$DB NAME=$NAME DIST=$DIST RELEASE=$RELEASE"

    RESULT="$(lookup "$DB" "$NAME")"
    RESULT+=" $(lookup_fallback "$DB" "$NAME" "$DIST" '')"
    RESULT+=" $(lookup_fallback "$DB" "$NAME" "$DIST" "$RELEASE")"
    # shellcheck disable=SC2086
    debug 3 "  get_db: RESULT="$RESULT
    # shellcheck disable=SC2086
    echo $RESULT
}

#===============================================================================
# Recursively expand macros in package list
pkg_list_expand() {
    local DB=$1; shift
    local DID=$1; shift
    local DREL=$1; shift
    local KEY PKGS
    # shellcheck disable=SC2086
    debug 3 "  pkg_list_expand: DB=$DB DID=$DID DREL=$DREL PLIST="$*

    for KEY in "$@" ; do
        case $KEY in
            @*) PKGS=$(get_db "$DB" "$KEY" "$DID" "$DREL")
                # shellcheck disable=SC2086
                pkg_list_expand "$DB" "$DID" "$DREL" $PKGS ;;
            [*) PKGS=$(eval "echo \${$DB$KEY}") #]
                debug 3 "    pkg_list_expand: lookup macro $DB$KEY -> $PKGS"
                [[ $KEY != $PKGS ]] || error "Recursive package list: $KEY"
                # shellcheck disable=SC2086
                pkg_list_expand "$DB" "$DID" "$DREL" $PKGS ;;
            *) echo "$KEY" ;;
        esac
    done
}

#===============================================================================
# Handle removing packages from the list: foo -foo
pkg_list_contract() {
    local BEFORE AFTER
    BEFORE=$(list_sort "$@")
    AFTER=$BEFORE
    # shellcheck disable=SC2086
    debug 3 "  pkg_list_contract BEFORE="$BEFORE
    for PKG in $BEFORE; do
        if [[ $PKG == -* ]] ; then
            AFTER=$(for P in $AFTER; do
                echo "$P"
            done | egrep -v "^-?${PKG#-}$")
        fi
    done
    # shellcheck disable=SC2086
    debug 3 "  pkg_list_contract: AFTER="$AFTER
    # shellcheck disable=SC2086
    list_sort $AFTER
}

#===============================================================================
# Check package list for obvious problems
pkg_list_check() {
    for PKG in "${!PACKAGES[@]}" "${!RECOMMENDS[@]}"; do
        case "$PKG" in
            @*|*_@*) >/dev/null;;
            *@*) fail "'$PKG' is likely invalid. I think you meant '${PKG/@/_@}'";;
            *-LF*) fail "'$PKG' is likely invalid. I think you meant '${PKG/-LF/_LF}'";;
            LF*_*) fail "'$PKG' is likely invalid. I think you meant '$(sed -re 's/(LF....)_([^_]+)/\2_\1/')'";;
            *) >/dev/null;;
        esac
    done
}

#===============================================================================
# Build package list
# TODO: Needs to be tested more with other distros
package_list() {
    local DID=$1
    local DREL=$2
    local ACTIVITY=$3
    local DVER PLIST LIST RLIST
    debug 1 "package_list: DID=$DID DREL=$DREL ACTIVITY=$ACTIVITY"

    pkg_list_check

    if [[ -n ${COPYPACKAGES[$ACTIVITY]} ]] ; then
        debug 1 "package_list: COPYPACKAGES $ACTIVITY -> ${COPYPACKAGES[$ACTIVITY]}"
        ACTIVITY=${COPYPACKAGES[$ACTIVITY]}
    fi

    DVER=$(distrib_ver "$DID" "$DREL")

    #---------------------------------------------------------------------------
    PLIST=$(get_db PACKAGES "" "$DID" "$DVER"; get_db PACKAGES "$ACTIVITY" "$DID" "$DVER")
    # shellcheck disable=SC2086
    debug 2 "package_list: PLIST="$PLIST
    # shellcheck disable=SC2046,SC2086
    LIST=$(list_sort $(pkg_list_expand PACKAGES "$DID" "$DVER" $PLIST))
    # shellcheck disable=SC2086
    debug 1 "package_list: PACKAGES LIST="$LIST

    if [[ -z $NORECOMMENDS ]] ; then
        RLIST=$(get_db RECOMMENDS "" "$DID" "$DVER"; get_db RECOMMENDS "$ACTIVITY" "$DID" "$DVER")
        # shellcheck disable=SC2086
        debug 2 "package_list: RLIST="$RLIST
        # shellcheck disable=SC2046,SC2086
        LIST=$(list_sort $LIST $(pkg_list_expand RECOMMENDS "$DID" "$DVER" $PLIST $RLIST))
        # shellcheck disable=SC2086
        debug 2 "package_list: +RECOMMENDS LIST="$LIST
    fi


    # shellcheck disable=SC2086
    LIST=$(pkg_list_contract $LIST)
    # shellcheck disable=SC2086
    debug 1 "package_list: Final packages for $DID-${DVER}_$ACTIVITY:" $LIST
    echo "$LIST"
}

CKCACHE="$CMCACHE"

#===============================================================================
# Check Packages
check_packages() {
    local ACTIVITIES="$*"
    local DISTS D DIST P
    local SEARCH="./scripts/pkgsearch"
    if [[ ! -x $SEARCH ]] ; then
        error "$SEARCH not found"
    fi
    # shellcheck disable=SC2086
    [[ -n $ACTIVITIES ]] || ACTIVITIES=$(list_sort ${!TITLE[*]})
    # shellcheck disable=SC2086
    debug 1 "check_packages: ACTIVITIES="$ACTIVITIES

    mkdir -p "$CKCACHE"
    [[ -z $NOCACHE ]] || $SEARCH --dropcache

    DISTS=$(distrib_list)
    # shellcheck disable=SC2086
    debug 1 "  check_packages: DISTS="$DISTS
    for C in $ACTIVITIES; do
        local CHECKED="$CKCACHE/$C-checked" CP=""
        if [[ -z $NOCACHE && -e $CHECKED ]] ; then
            verbose "Already checked $C"
            [[ -n $VERBOSE ]] || cat "$CHECKED"
            continue
        fi
        supported_activity "$C"

        CP="$C "
        [[ -n $VERBOSE ]] || progress "$CP"
        for DIST in $DISTS; do
            CP="$CP."
            [[ -n $VERBOSE ]] || progress '.'
            # shellcheck disable=SC2086
            P=$(package_list ${DIST/-/ } $C)
            # shellcheck disable=SC2086
            debug 2 "    check_packages: P="$P
            local OPTS OUTPUT
            [[ -n $VERBOSE ]] || OPTS="--quiet --progress"
            # shellcheck disable=SC2086
            debug 2 "    check_packages: $SEARCH $OPTS -df $DIST "$P
            # shellcheck disable=SC2086
            OUTPUT=$($SEARCH $OPTS -df "$DIST" $P)
            if [[ -n $OUTPUT ]] ; then
                [[ -n $VERBOSE ]] || echo
                notice "Checking $DIST for $C..."
                echo "$OUTPUT"
                CHECKED=""
            fi
        done

        [[ -n $VERBOSE ]] || progress "\n"
        if [[ -n $CHECKED ]] ; then
            echo "$CP" > "$CHECKED"
        fi
    done
    [[ -n $VERBOSE ]] || echo
}

#===============================================================================
# List Packages
list_packages() {
    local ACTIVITIES=$1
    local DISTS D DIST PL P

    DISTS=$(distrib_list)
    # shellcheck disable=SC2086
    debug 1 "list_packages: ACTIVITIES=$ACTIVITIES PKGS=$PKGS DISTS="$DISTS

    if [[ -n $ACTIVITIES ]] ; then
        supported_activity "$ACTIVITIES"
    else
        # shellcheck disable=SC2086
        ACTIVITIES=$(list_sort ${!TITLE[*]})
    fi
    for D in $ACTIVITIES; do
        notice "Listing packages for $D..."
        for DIST in $DISTS; do
            # shellcheck disable=SC2086
            PL=$(package_list ${DIST/-/ } $D)
            # shellcheck disable=SC2086
            debug 2 PL1=$PL
            # shellcheck disable=SC2086
            [[ -z $PKGS ]] || PL=$(list_grep "^$PKGS$" $PL)
            # shellcheck disable=SC2086
            debug 2 PL2=$PL
            for P in $PL ; do
                echo -e "$DIST\t$P"
            done
        done
    done
}

#===============================================================================
# List All Packages
list_all_packages() {
    debug 1 "list_all_packages: List All Packages"

    local K
    # shellcheck disable=SC2086
    for K in $(list_sort ${!PACKAGES[*]}) ; do
        echo "PACKAGES[$K]=${PACKAGES[$K]}"
    done
    # shellcheck disable=SC2086
    for K in $(list_sort ${!RECOMMENDS[*]}) ; do
        echo "RECOMMENDS[$K]=${RECOMMENDS[$K]}"
    done
}

#===============================================================================
if [[ -n $ALL_PKGS ]] ; then
    list_all_packages
    exit 0
fi
if [[ -n $LIST_DISTROS ]] ; then
    list_distro_names
    exit 0
fi


#===============================================================================
# Determine Distro and release
guess_distro() {
    local DISTRO=$1
    debug 1 "guess_distro: DISTRO=$DISTRO"
    local DISTRIB_SOURCE DISTRIB_ID DISTRIB_RELEASE DISTRIB_CODENAME DISTRIB_DESCRIPTION DISTRIB_ARCH
    #-------------------------------------------------------------------------------
    if [[ -f /etc/lsb-release ]] ; then
        DISTRIB_SOURCE+="/etc/lsb-release"
        . /etc/lsb-release
    fi
    #-------------------------------------------------------------------------------
    if [[ -z $DISTRIB_ID ]] ; then
        if [[ -f /usr/bin/lsb_release ]] ; then
            DISTRIB_SOURCE+=" lsb_release"
            DISTRIB_ID=$(lsb_release -is 2>/dev/null)
            DISTRIB_RELEASE=$(lsb_release -rs 2>/dev/null)
            DISTRIB_CODENAME=$(lsb_release -cs 2>/dev/null)
            DISTRIB_DESCRIPTION=$(lsb_release -ds 2>/dev/null)
        fi
    fi
    #-------------------------------------------------------------------------------
    if [[ -f /etc/os-release ]] ; then
        DISTRIB_SOURCE+=" /etc/os-release"
        . /etc/os-release
        DISTRIB_ID=${DISTRIB_ID:-${ID^}}
        DISTRIB_RELEASE=${DISTRIB_RELEASE:-$VERSION_ID}
        DISTRIB_DESCRIPTION=${DISTRIB_DESCRIPTION:-$PRETTY_NAME}
    fi
    #-------------------------------------------------------------------------------
    if [[ -f /etc/debian_version ]] ; then
        DISTRIB_SOURCE+=" /etc/debian_version"
        DISTRIB_ID=${DISTRIB_ID:-Debian}
        [[ -n $DISTRIB_CODENAME ]] || DISTRIB_CODENAME=$(sed 's|^.*/||' /etc/debian_version)
        [[ -n $DISTRIB_RELEASE ]] || DISTRIB_RELEASE=${DEBREL[$DISTRIB_CODENAME]:-$DISTRIB_CODENAME}
    #-------------------------------------------------------------------------------
    elif [[ -f /etc/SuSE-release ]] ; then
        DISTRIB_SOURCE+=" /etc/SuSE-release"
        [[ -n $DISTRIB_ID ]] || DISTRIB_ID=$(awk 'NR==1 {print $1}' /etc/SuSE-release)
        [[ -n $DISTRIB_RELEASE ]] || DISTRIB_RELEASE=$(awk '/^VERSION/ {print $3}' /etc/SuSE-release)
        [[ -n $DISTRIB_CODENAME && $DISTRIB_CODENAME != "n/a" ]] || DISTRIB_CODENAME=$(awk '/^CODENAME/ {print $3}' /etc/SuSE-release)
    #-------------------------------------------------------------------------------
    elif [[ -f /etc/redhat-release ]] ; then
        DISTRIB_SOURCE+=" /etc/redhat-release"
        if egrep -q "^Red Hat Enterprise Linux" /etc/redhat-release ; then
            [[ -n $DISTRIB_RELEASE ]] || DISTRIB_RELEASE=$(awk '{print $7}' /etc/redhat-release)
        elif egrep -q "^CentOS|Fedora" /etc/redhat-release ; then
            DISTRIB_ID=$(awk '{print $1}' /etc/redhat-release)
            [[ -n $DISTRIB_RELEASE ]] || DISTRIB_RELEASE=$(awk '{print $3}' /etc/redhat-release)
        fi
        DISTRIB_ID=${DISTRIB_ID:-RHEL}
        [[ -n $DISTRIB_CODENAME ]] || DISTRIB_CODENAME=$(sed 's/^.*(//; s/).*$//;' /etc/redhat-release)
    #-------------------------------------------------------------------------------
    elif [[ -e /etc/arch-release ]] ; then
        DISTRIB_SOURCE+=" /etc/arch-release"
        DISTRIB_ID=${DISTRIB_ID:-Arch}
        # Arch Linux doesn't have a "release"...
        # So instead we'll look at the modification date of pacman
        # shellcheck disable=SC2012
        [[ -n $DISTRIB_RELEASE ]] || DISTRIB_RELEASE=$(ls -l --time-style=+%Y.%m /bin/pacman | cut -d' ' -f6)
    #-------------------------------------------------------------------------------
    elif [[ -e /etc/gentoo-release ]] ; then
        DISTRIB_SOURCE+=" /etc/gentoo-release"
        DISTRIB_ID=${DISTRIB_ID:-Gentoo}
        [[ -n $DISTRIB_RELEASE ]] || DISTRIB_RELEASE=$(cut -d' ' -f5 /etc/gentoo-release)
    fi
    #-------------------------------------------------------------------------------
    if [[ -n $DISTRO ]] ; then
        debug 1 "  Overriding distro: $DISTRO"
        DISTRIB_SOURCE+=" override"
        DISTRIB_ID=${DISTRO%%-*}
        DISTRIB_RELEASE=${DISTRO##*-}
        DISTRIB_CODENAME=Override
        DISTRIB_DESCRIPTION="$DISTRO (Override)"
    fi
    #-------------------------------------------------------------------------------
    shopt -s nocasematch
    if [[ $DISTRIB_ID == Centos ]] ; then
        DISTRIB_ID=CentOS
    elif [[ $DISTRIB_ID =~ Debian ]] ; then
        DISTRIB_RELEASE=${DEBREL[$DISTRIB_RELEASE]:-$DISTRIB_RELEASE}
    elif [[ $DISTRIB_ID == RedHat* || $DISTRIB_ID == Rhel ]] ; then
        DISTRIB_ID=RHEL
    elif [[ $DISTRIB_ID =~ Sles ]] ; then
        DISTRIB_ID=SLES
    elif [[ $DISTRIB_ID =~ Suse ]] ; then
        DISTRIB_ID=openSUSE
        version_greater_equal 20000000 "$DISTRIB_RELEASE" || DISTRIB_RELEASE=999
    elif [[ -z $DISTRIB_ID ]] ; then
        DISTRIB_ID=Unknown
    fi
    shopt -u nocasematch
    #-------------------------------------------------------------------------------
    DISTRIB_RELEASE=${DISTRIB_RELEASE:-0}
    #DISTRIB_CODENAME=${DISTRIB_CODENAME:-Unknown}
    [[ -n $DISTRIB_DESCRIPTION ]] || DISTRIB_DESCRIPTION="$DISTRIB_ID $DISTRIB_RELEASE"

    #===============================================================================
    # Determine Distro arch
    local DARCH
    if [[ -e /usr/bin/dpkg && $DISTRIB_ID =~ Debian|Kubuntu|LinuxMint|Mint|Ubuntu|Xubuntu ]] ; then
        DARCH=$(dpkg --print-architecture)
    elif [[ -e /bin/rpm || -e /usr/bin/rpm ]] && [[ $DISTRIB_ID =~ CentOS|Fedora|Rhel|RHEL|openSUSE|SLES ]] ; then
        DARCH=$(rpm --eval %_arch)
    elif [[ -e /usr/bin/file ]] ; then
        DARCH=$(/usr/bin/file /usr/bin/file | cut -d, -f2)
        DARCH=${DARCH## }
        DARCH=${DARCH/-64/_64}
    else
        DARCH=Unknown
    fi
    # Because Debian and derivatives use amd64 instead of x86_64...
    if [[ "$DARCH" == "amd64" ]] ; then
        DISTRIB_ARCH=x86_64
    else
        DISTRIB_ARCH=$(sed -re 's/IBM //' <<<$DARCH)
    fi

    #===============================================================================
    debug 1 "  DISTRIB_SOURCE=$DISTRIB_SOURCE"
    debug 1 "  DISTRIB_ID=$DISTRIB_ID"
    debug 1 "  DISTRIB_RELEASE=$DISTRIB_RELEASE"
    debug 1 "  DISTRIB_CODENAME=$DISTRIB_CODENAME"
    debug 1 "  DISTRIB_DESCRIPTION=$DISTRIB_DESCRIPTION"
    debug 1 "  DISTRIB_ARCH=$DISTRIB_ARCH"
    debug 1 "  DARCH=$DARCH"
    echo "$DISTRIB_ID,$DISTRIB_RELEASE,$DISTRIB_CODENAME,$DISTRIB_DESCRIPTION,$DISTRIB_ARCH,$DARCH"
}

#===============================================================================
which_distro() {
    local ID=$1 ARCH=$2 RELEASE=$3 CODENAME=$4
    debug 1 "which_distro: ID=$ID ARCH=$ARCH RELEASE=$RELEASE CODENAME=$CODENAME"
    echo "Linux Distro: $ID${ARCH:+:$ARCH}-$RELEASE ${CODENAME:+($CODENAME)}"
    exit 0
}

#===============================================================================
extract_arch () {
    local D=$1 DIST ARCH
    read -r DIST ARCH <<< "$(sed -re 's/^([a-zA-Z0-9]+):([a-zA-Z0-9]+)(-.*)$/\1\3 \2/' <<<$D)"
    if [[ -n $ARCH ]] ; then
        debug 2 "extract_arch: $DIST $ARCH"
        echo "$DIST $ARCH"
    else
        echo "$D"
    fi
}

#===============================================================================
include_arch () {
    local D DIST=$1 ARCH=$2
    D=$(sed -re 's/([a-zA-Z0-9]+)(-[^ ]+)?/\1'"${ARCH:+:$ARCH}"'\2/g' <<<$DIST)
    debug 2 "    include_arch: $DIST -> $D"
    echo "${D:-$DIST}"
}

#===============================================================================
fix_distro_alias() {
    local D
    for D in "$@" ; do
        local DIST ARCH ALIAS
        # shellcheck disable=SC2086
        read -r DIST ARCH <<<"$(extract_arch $D)"
        ALIAS="${DISTRO_ALIASES[${DIST}]}"
        if [[ -n $ALIAS ]] ; then
            debug 2 "  fix_distro_alias: $DIST -> $ALIAS"
            include_arch "$ALIAS" "$ARCH"
        else
            debug 2 "  fix_distro_alias: $D"
            echo "$D"
        fi
    done
}

#===============================================================================
# shellcheck disable=SC2086
IFS=, read -r ID RELEASE CODENAME DESCRIPTION ARCH DARCH <<<"$(guess_distro $DISTRO)"
debug 1 "main: guess_distro split: ID=$ID RELEASE=$RELEASE CODENAME=$CODENAME DESCRIPTION=$DESCRIPTION ARCH=$ARCH DARCH=$DARCH"
[[ -n $WHICH_DISTRO ]] && which_distro "$ID" "$ARCH" "$RELEASE" "$CODENAME"

#===============================================================================
# shellcheck disable=SC2086
[[ -z $DISTROS ]] || DISTROS=$(fix_distro_alias $DISTROS)
# shellcheck disable=SC2086
[[ -z ${DISTROS[LFD]} ]] || DISTROS[LFD]=$(fix_distro_alias ${DISTROS[LFD]})
# shellcheck disable=SC2086
[[ -z ${DISTROS[LFS]} ]] || DISTROS[LFS]=$(fix_distro_alias ${DISTROS[LFS]})



#===============================================================================
parse_distro() {
    local DIST DARCH DVER GT
    IFS='-' read -r DIST GT <<< "$1"
    DVER=${GT%+}
    GT=${GT/$DVER/}
    IFS=':' read -r DIST DARCH <<< "$DIST"
    debug 3 "parse_distro: $DIST,$DARCH,$DVER,$GT"
    echo "$DIST,$DARCH,$DVER,$GT"
}

#===============================================================================
# Is distro-B in filter-A?
cmp_dists() {
    local A=$1 B=$2
    debug 2 "cmp_dists: $A $B"

    [[ $A = "$B" || $A+ = "$B" || $A = $B+ ]] && return 0

    local AD AA AV AG
    local BD BA BV BG
    IFS=',' read -r AD AA AV AG <<< $(parse_distro "$A")
    # shellcheck disable=SC2034
    IFS=',' read -r BD BA BV BG <<< $(parse_distro "$B")

    if [[ $AD == "$BD" ]] ; then
        [[ -n $AA || -n $BA ]] && [[ $AA != "$BA" ]] && return 1
        [[ $AV == "$BV" ]] && return 0
        if [[ -n $AG ]] ; then
            version_greater_equal "$AV" "$BV" || return 0
        fi
    fi
    return 1
}

#===============================================================================
filter_dists() {
    local FILTER=$1
    local DISTS=$2
    local F D

    # shellcheck disable=SC2027,SC2086
    debug 1 "filter_dists FILTER="$FILTER" DISTS="$DISTS

    if [[ -z $FILTER ]] ; then
        echo "$DISTS"
        return 0
    fi

    for D in $DISTS; do
        for F in $FILTER; do
            if cmp_dists "$F" "$D" ; then
                debug 2 "  filter_dists $D is in $F"
                echo "$D"
            fi
        done
    done
}

#===============================================================================
fix_distro_names() {
    local D
    for D in "$@" ; do
        local ALIAS
        ALIAS="${DISTRO_NAMES[${D%+}]}"
        if [[ -n $ALIAS ]] ; then
            debug 1 "fix_distro_names: $D -> $ALIAS"
            echo "$ALIAS"
        else
            debug 1 "fix_distro_names: $D"
            echo "$D"
        fi
    done
}

#===============================================================================
# JSON support
json_entry() {
    local NAME=$1 VALUE="$2" P=${3:-.}
    progress "$P"
    [[ -z $VALUE ]] || echo "      \"$NAME\": \"$VALUE\","
}
#-------------------------------------------------------------------------------
json_array() {
    # shellcheck disable=SC2155,SC2116,SC2086
    local NAME=$1 LIST=$(echo $2) WS=$3 P=${4:-+}
    progress "$P"
    [[ -z $LIST ]] || echo "      $WS\"$NAME\": [\"${LIST// /\", \"}\"],"
}
#-------------------------------------------------------------------------------
json_flag() {
    local FLAG=$1 YES=$2 NO=$3
    shopt -s nocasematch
    case $FLAG in
        1|y*|on) echo "$YES";;
        0|n*|off) echo "$NO";;
    esac
    shopt -u nocasematch
}

#===============================================================================
# Distros, blacklists, and packages
json_distros() {
    local C=$1 DISTS="$2"
    # shellcheck disable=SC2086
    debug 1 "json_distros: C=$C DISTS="$DISTS

    #-------------------------------------------------------------------
    local DS
    # shellcheck disable=SC2086
    DS="$(value DISTROS $C)"
    # shellcheck disable=SC2086
    DS="$(fix_distro_alias $DS)"
    # shellcheck disable=SC2086
    debug 2 "list_json DISTROS="$DS
    json_array distros "$DS"

    #-------------------------------------------------------------------
    # shellcheck disable=SC2086
    json_entry distro_default "$(value DISTRO_DEFAULT $C)"

    #-------------------------------------------------------------------
    local BL
    if [[ ${DISTRO_BL[$C]} != delete ]] ; then
        # shellcheck disable=SC2086
        BL="$(value DISTRO_BL $C)"
        # shellcheck disable=SC2086
        json_array distro_bl "$BL"
    fi

    #-------------------------------------------------------------------
    # Packages per distro
    local DLIST
    # shellcheck disable=SC2086
    DLIST=$(filter_dists "$DS" "$DISTS")
    if [[ -n $DLIST ]] ; then
        echo '      "packages": {'
        local DIST
        # shellcheck disable=SC2013
        for DIST in $(sed 's/:[a-zA-Z0-9]*-/-/g; s/\+//g' <<< $DLIST); do
            [[ ! $BL =~ $DIST ]] || continue;
            local P
            # shellcheck disable=SC2086
            P=$(package_list ${DIST/-/ } $C)
            # shellcheck disable=SC2086
            json_array "$(fix_distro_names $DIST)" "$P" '  ' '*'
        done
        echo '      },'
    fi
}

#===============================================================================
# Calculate SUGGESTS from PREREQ
declare -A SUGGESTS
calculate_suggests() {
    debug 1 "calculate_suggests"
    local C
    # shellcheck disable=SC2086
    for C in $(list_sort ${!TITLE[*]}); do
        debug 2 "  calculate_suggests: $C"
        local K="${PREREQ[$C]}"
        if [[ -n $K ]] ; then
            debug 2 "    calculate_suggests SUGGESTS[$K]=$C"
            local S="${SUGGESTS[$K]}"
            SUGGESTS[$K]="${S:+$S }$C"
        fi
    done
}

#===============================================================================
# Calculate SUGGESTS from PREREQ
calculate_materials() {
    local C=$1
    local APPENDICES ERRATA RESOURCES SOLUTIONS VER VER2 VER3 VER4
    # shellcheck disable=SC2034
    read -r APPENDICES VER <<< $(get_activity_file "$C" APPENDICES)
    # shellcheck disable=SC2034
    read -r ERRATA VER2 <<< $(get_activity_file "$C" ERRATA)
    # shellcheck disable=SC2034
    read -r RESOURCES VER3 <<< $(get_activity_file "$C" RESOURCES)
    # shellcheck disable=SC2034
    read -r SOLUTIONS VER4 <<< $(get_activity_file "$C" SOLUTIONS)
    echo "$APPENDICES" "$ERRATA" "$RESOURCES" "$SOLUTIONS"
}

#===============================================================================
json_activities() {
    local DISTS="$1" C
    # shellcheck disable=SC2086
    debug 1 "json_activities: DISTS="$DISTS

    calculate_suggests

    # shellcheck disable=SC2086
    for C in $(list_sort ${!TITLE[*]}); do
        progress "$C: "
        echo "    \"$C\": {"
        json_entry title "${TITLE[$C]}"
        json_entry url "${WEBPAGE[$C]}"
        # shellcheck disable=SC2046
        local ATTR
        read -r -d '' ATTR <<-ENDATTR
		$(json_flag "${MOOC[$C]:-$MOOC}" "free-MOOC")
		$(json_flag "${SELFPACED[$C]:-$SELFPACED}" "Self-paced" "Instructor-led")
		$(json_flag "${INPERSON[$C]:-$INPERSON}" "On-site")
		$(json_flag "${VIRTUAL[$C]:-$VIRTUAL}" "Virtual")
		ENDATTR
        json_array attr "$ATTR"
        json_entry instr_led_class "${INSTR_LED_CLASS[$C]}"
        json_entry selfpaced_class "${SELFPACED_CLASS[$C]}"
        json_entry prereq "${PREREQ[$C]}"
        json_entry suggests "${SUGGESTS[$C]}"
        local O M
        O="$(value OS $C)"
        debug 2 "list_json: OS=$O (${OS[$C]}, $OS)"
        json_entry internet "$(value INTERNET $C)"
        M=$(calculate_materials "$C")
        [[ -z $M ]] || json_array materials "$M"
        json_entry os "$O"
        json_entry nativelinux "$(value NATIVELINUX $C)"
        json_entry vm_okay "$(value VMOKAY $C)"

        #-----------------------------------------------------------------------
        # Do more if the OS is Linux
        if [[ $O != "Linux" ]] ; then
            json_entry os_needs "$(value OS_NEEDS $C)"
        else
            json_entry arch "$(value ARCH $C)"
            local CP PCP
            CP="$(value CPUS $C)"
            PCP="$(value PREFER_CPUS $C)"
            json_entry cpus "${PCP:-$CP}${PCP:+ (minimum $CP)}"
            json_entry cpuflags "$(value CPUFLAGS $C)"
            json_entry bogomips "$(value BOGOMIPS $C)"
            json_entry ram "$(value RAM $C)"
            json_entry disk "$(value DISK $C)"
            json_entry boot "$(value BOOT $C)"
            json_entry configs "$(value CONFIGS $C)"
            json_entry distro_arch "$(value DISTRO_ARCH $C)"
            json_entry card_reader "$(value CARDREADER $C)"
            json_entry os_needs "$(value OS_NEEDS $C)"
            json_entry includes "$(value INCLUDES $C)"
            json_distros "$C" "$DISTS"
        fi
        echo '    },'
        progress "\n"
    done
}

#===============================================================================
json_password() {
    [[ -n $CMPASSWORD ]] || return 0

    cat <<ENDJSON
  "user": "$CMUSERNAME",
  "pass": "$CMPASSWORD",
ENDJSON
}

#===============================================================================
json_vms() {
    [[ -n $VMURL ]] || return 0

    if [[ -n $NONETWORK ]] ; then
        warn "json_vms: No network selected."
        return 0
    fi

    local FILES FILE
    FILES=$(get_file "$VMURL" \
        | awk -F '"' '/<tr><td.*[A-Z].*\.tar/ {print $8}' \
        | sort -i)
    # shellcheck disable=SC2086
    debug 1 "json_vms:"$FILES
    local URL="$LFCM/$VMURL"

    echo '  "vms": {'
    progress "VMs: "
    for FILE in $FILES; do
        local NAME
        NAME=${FILE%%.tar*}
        case "$FILE" in
            CentOS*) json_entry "fl-centos,$NAME" "$URL/$FILE" ;;
            Debian*) json_entry "fl-debian,$NAME" "$URL/$FILE" ;;
            FC*|Fedora*) json_entry "fl-fedora,${NAME/FC/Fedora}" "$URL/$FILE" ;;
            GENTOO*) json_entry "fl-gentoo,$NAME" "$URL/$FILE" ;;
            Linux-Mint*|LinuxMint*|Mint*) json_entry "fl-linuxmint,${NAME/*Mint/Linux-Mint}" "$URL/$FILE" ;;
            OpenSUSE*|openSUSE*) json_entry "fl-opensuse,${NAME/OpenSUSE/openSUSE}" "$URL/$FILE" ;;
            Ubuntu*) json_entry "fl-ubuntu,$NAME" "$URL/$FILE" ;;
            *) error "Unknown VM type in $URL" ;;
        esac
    done
    progress "\n"
    echo '  }'
}

#===============================================================================
# shellcheck disable=SC2120
print_json() {
    local DISTS
    DISTS=$(distrib_list)
    # shellcheck disable=SC2086
    debug 1 "print_json: DISTS="$DISTS

    cat <<ENDJSON | perl -e '$/=undef; $_=<>; s/,(\s+[}\]])/$1/gs; print;'
{
  "whatisthis": "Activity requirements",
  "version": "$VERSION",
  "tool": "$LFCM/prep/${CMDBASE/-full/}",
  "form": {
    "title": "Title",
    "attr": "Attributes",
    "instr_led_class": "Equivalent Instructor Led Course",
    "selfpaced_class": "Equivalent Online Self-Paced Course",
    "prereq": "Course Prerequisites",
    "suggests": "Suggested Follow-on Courses",
    "internet": "Internet Access",
    "materials": "Supplemental Materials",
    "os": "OS required for class",
    "vm_okay": "Virtual Machine",
    "nativelinux": "Native Linux",
    "os_needs": "Required SW for class",
    "arch": "Required CPU Architecture",
    "cpus": "Preferred Number of CPUs",
    "bogomips": "Minimum CPU Performance (bogomips)",
    "cpuflags": "Required CPU features",
    "ram": "Minimum Amount of RAM (GiB)",
    "disk": "Free Disk Space in \$HOME (GiB)",
    "boot": "Free Disk Space in /boot (MiB)",
    "configs": "Kernel Configuration Options",
    "distro_arch": "Distro Architecture",
    "distros": "Supported Linux Distros",
    "distro_bl": "Unsupported Linux Distros",
    "card_reader": "Is the use of a Card Reader Required?",
    "includes": "What is provided?",
    "packages": "Package List"
  },
  "help": {
    "prereq": "Course(s) which we suggest you take before this one",
    "internet": "Fast Internet access in the classroom is mandatory for this course",
    "os_needs": "These are the kinds of SW needed for the course",
    "cpus": "CPUs = Chips x Cores x Hyperthreads. Preferably in a computer which is less than 5yrs old",
    "bogomips": "This is a terrible measure of performance, but consistent across architectures",
    "cpuflags": "Your CPU must have these flags set which indicate CPU HW capabilities",
    "disk": "If not in \$HOME, then in some other attached drive",
    "boot": "We will be installing kernels, so there needs to be room available",
    "configs": "Your Linux kernel must be configured with these options",
    "distro_bl": "These versions of distros will cause problems in class",
    "card_reader": "A card reader will be provided to you in class",
    "includes": "There is a HW kit which is (optionally) included with this course",
  },
  "distros": [
$(for DIST in $DISTS ; do echo '    "'"$DIST"'+",'; done | sort)
  ],
  "distro_fallback": {
$(for FB in ${!FALLBACK[*]} ; do echo '    "'"$FB"'": "'"${FALLBACK[$FB]}"'",'; done | sort)
  },
  "activities": {
$(json_activities "$DISTS")
  },
$(json_password)
$(json_vms)
}
ENDJSON
    # Minification
    #| sed ':a;N;$!ba; s/\n//g; s/   *//g; s/\([:,]\) \([\[{"]\)/\1\2/g'

    verbose "JSON generated"
    exit 0
}

#===============================================================================
# shellcheck disable=SC2119
if [[ -n $JSON ]] ; then
    print_json
    exit 0
fi

#===============================================================================
# TEST: Right cpu architecture?
check_cpu() {
    local ARCH=$1
    local CPU_ARCH

    if [[ -n $ARCH ]] ; then
        CPU_ARCH=$(uname -m)
        verbose "check_cpu: ARCH='$ARCH' CPU_ARCH='$CPU_ARCH'"
        if [[ $ARCH = i386 && $CPU_ARCH = i686 ]] ; then
            pass "CPU architecture is $ARCH ($CPU_ARCH)"
        elif [[ $CPU_ARCH = "$ARCH" && -z $SIMULATE_FAILURE ]] ; then
            pass "CPU architecture is $CPU_ARCH"
        else
            fail "CPU architecture is not $ARCH (it is $CPU_ARCH)"
            FAILED=y
        fi
    fi
}

#===============================================================================
# TEST: Right cpu flags?
check_cpu_flags() {
    local CPUFLAGS=$1
    local NOTFOUND

    if [[ -n $CPUFLAGS ]] ; then
        verbose "check_cpu_flags: CPUFLAGS=$CPUFLAGS"
        for FLAG in $CPUFLAGS ; do
            grep -qc " $FLAG " /proc/cpuinfo || NOTFOUND+=" $FLAG"
        done
        if [[ -n $NOTFOUND ]] ; then
            fail "CPU doesn't have the following capabilities:$NOTFOUND"
            FAILED=y
        else
            pass "CPU has all needed capabilities: $CPUFLAGS"
        fi
    fi
}

#===============================================================================
get_number_of_cpus() {
    local NUM_CPU
    NUM_CPU=$(lscpu | awk '/^CPU\(s\):/ {print $2}')
    [[ -n $NUM_CPU ]] || NUM_CPU=$(grep -c ^processor /proc/cpuinfo)
    echo "${NUM_CPU:-0}"
}

#===============================================================================
# TEST: Enough CPUS?
check_number_of_cpus() {
    local CPUS=$1
    verbose "check_number_of_cpus: CPUS=$CPUS"
    local NUM_CPU

    NUM_CPU=$(get_number_of_cpus)
    if [[ -z $NUM_CPU || $NUM_CPU == 0 ]] ; then
        bug "I didn't find the number of cpus you have" "lscpu | awk '/^CPU\\(s\\):/ {print \$2}'"
    elif [[ $NUM_CPU -lt $CPUS || -n $SIMULATE_FAILURE ]] ; then
        fail "Single core CPU: not powerful enough (require at least $CPUS, though $PREFER_CPUS is preferred)"
        FAILED=y
        NOTENOUGH=y
    elif [[ $NUM_CPU -lt $PREFER_CPUS ]] ; then
        pass "$NUM_CPU core CPU (good enough but $PREFER_CPUS is preferred)"
    else
        pass "$NUM_CPU core CPU"
    fi
}

#===============================================================================
get_bogomips() {
    local NUM_CPU BMIPS
    NUM_CPU=$(get_number_of_cpus)
    BMIPS=$(lscpu | awk '/^BogoMIPS:/ {print $2}' | sed -re 's/\.[0-9]{2}$//')
    [[ -n $BMIPS ]] || BMIPS=$(awk '/^bogomips/ {mips+=$3} END {print int(mips + 0.5)}' /proc/cpuinfo)
    echo $(( ${NUM_CPU:-0} * ${BMIPS:-0} ))
}

#===============================================================================
# TEST: Enough BogoMIPS?
check_bogomips() {
    local BOGOMIPS=$1
    local BMIPS

    if [[ -n $BOGOMIPS ]] ; then
        verbose "check_bogomips: BOGOMIPS=$BOGOMIPS"
        BMIPS=$(get_bogomips)
        [[ -z $BMIPS ]]
        if [[ -z $BMIPS || $BMIPS == 0 ]] ; then
            bug "I didn't find the number of BogoMIPS your CPU(s) have" \
                "awk '/^bogomips/ {mips+=\$3} END {print int(mips + 0.5)}' /proc/cpuinfo"
        elif [[ $BMIPS -lt $BOGOMIPS || -n $SIMULATE_FAILURE ]] ; then
            fail "Your CPU isn't powerful enough (must be at least $BOGOMIPS BogoMIPS cumulatively)"
            FAILED=y
        else
            if [[ -n $NOTENOUGH ]] ; then
                notice "Despite not having enough CPUs, you may still have enough speed (currently at $BMIPS BogoMIPS)"
            else
                pass "Your CPU appears powerful enough (currently at $BMIPS BogoMIPS cumulatively)"
            fi
        fi
    fi
}

#===============================================================================
# TEST: Enough RAM?
check_ram() {
    local RAM=$1
    verbose "check_ram: RAM=$RAM"
    local RAM_GBYTES

    RAM_GBYTES=$(awk '/^MemTotal/ {print int($2/1024/1024+0.7)}' /proc/meminfo)
    if [[ -z $RAM_GBYTES ]] ; then
        bug "I didn't how much free RAM you have" \
            "awk '/^MemTotal/ {print int(\$2/1024/1024+0.7)}' /proc/meminfo"
    elif [[ $RAM_GBYTES -lt $RAM || -n $SIMULATE_FAILURE ]] ; then
        fail "Only $RAM_GBYTES GiB RAM (require at least $RAM GiB)"
        FAILED=y
    else
        pass "$RAM_GBYTES GiB RAM"
    fi
}

#===============================================================================
# df wrapper
get_df() {
    local DIR=$1
    local UNIT=$2
    [[ -n $DIR ]] || return
    local KBYTES

    KBYTES=$(df -k "$DIR" | awk '{if (NR == 2) print int($4)}')
    case $UNIT in
        MiB) echo $(( (KBYTES + 512) / 1024 ));;
        GiB) echo $(( (KBYTES + 512*1024) / 1024 / 1024));;
    esac
}

#===============================================================================
# find space on another attached drive
find_alternate_disk() {
    local MINSIZE=$1
    local UNIT=$2
    local STRING=$3
    local NOTFOUND=1 FS TOTAL USED AVAIL USE MP
    debug 1 "find_alternate_disk: Looking for disk ${STRING:+(${STRING%=})} bigger than $MINSIZE $UNIT"

    # shellcheck disable=SC2034
    while read -r FS TOTAL USED AVAIL USE MP; do
        [[ -n $MP ]] || continue
        AVAIL=$(get_df "$MP" "$UNIT")
        debug 2 "  Check MP=$MP AVAIL=$AVAIL UNIT=$UNIT"
        if [[ $AVAIL -ge $MINSIZE ]] ; then
           echo "$STRING$MP has $AVAIL $UNIT free"
           NOTFOUND=0
        fi
    done <<< "$(df | awk '{if (NR > 1) print}')"
    return $NOTFOUND
}

#===============================================================================
# TEST: Enough free disk space in $BUILDHOME? (defaults to $HOME)
check_free_disk() {
    local DISK=$1
    local BUILDHOME=$2
    [[ -n $BUILDHOME ]] || BUILDHOME=$(getent passwd "$USER" | cut -d: -f6)
    [[ -n $BUILDHOME ]] || return
    verbose "check_free_disk: DISK=$DISK BUILDHOME=$BUILDHOME"
    local DISK_GBYTES ALT

    DISK_GBYTES=$(get_df "$BUILDHOME" GiB)
    if [[ -z $DISK_GBYTES ]] ; then
        bug "I didn't find how much disk space is free in $BUILDHOME" \
            "df --output=avail $BUILDHOME | awk '{if (NR == 2) print int(($4+524288)/1048576)}'"
    elif [[ ${DISK_GBYTES:=1} -lt $DISK || -n $SIMULATE_FAILURE ]] ; then
        ALT=$(find_alternate_disk "$DISK" GiB "BUILDHOME=")
        if [[ -n $ALT ]] ; then
            warn "$BUILDHOME only has $DISK_GBYTES GiB free (need at least $DISK GiB)"
            pass "However, $ALT"
        else
            fail "only $DISK_GBYTES GiB free in $BUILDHOME (need at least $DISK GiB) Set BUILDHOME=/path/to/disk to override \$HOME"
            FAILED=y
        fi
    else
        pass "$DISK_GBYTES GiB free disk space in $HOME"
    fi
}

#===============================================================================
# TEST: Enough free disk space in /boot?
check_free_boot_disk() {
    local BOOT=$1
    local BOOTDIR=${2:-/boot}
    [[ -n $BOOTDIR ]] || return
    verbose "check_free_boot_disk: BOOT=$BOOT BOOTDIR=$BOOTDIR"
    local BOOT_MBYTES

    BOOT_MBYTES=$(get_df "$BOOTDIR" MiB)
    if [[ -z $BOOT_MBYTES ]] ; then
        bug "I didn't find how much disk space is free in $BOOTDIR" \
            "awk '/^MemTotal/ {print int(\$2/1024/1024+0.7)}' /proc/meminfo"
    elif [[ ${BOOT_MBYTES:=1} -le $BOOT || -n $SIMULATE_FAILURE ]] ; then
        fail "only $BOOT_MBYTES MiB free in /boot (need at least $BOOT MiB)"
        FAILED=y
    else
        pass "$BOOT_MBYTES MiB free disk space in /boot"
    fi
}

#===============================================================================
# TEST: Right Linux distribution architecture?
check_distro_arch() {
    local ARCH=$1
    local DISTRO_ARCH=$2

    if [[ -n $DISTRO_ARCH ]] ; then
        verbose "check_distro_arch: DISTRO_ARCH=$DISTRO_ARCH ARCH=$ARCH"
        if [[ -z $ARCH || -z $DISTRO_ARCH ]] ; then
            bug "Wasn't able to determine Linux distribution architecture" \
                "$0 --gather-info"
        elif [[ $ARCH != "$DISTRO_ARCH" || -n $SIMULATE_FAILURE ]] ; then
            fail "The distribution architecture must be $DISTRO_ARCH"
            FAILED=y
        else
            pass "Linux distribution architecture is $DISTRO_ARCH"
        fi
    fi
}

#===============================================================================
# Look for the current distro in a list of distros
found_distro() {
    local ID=$1 DARCH=$2 RELEASE=$3 DISTROS=$4
    local DISTRO
    debug 1 "found_distro: ID=$ID DARCH=$DARCH RELEASE=$RELEASE DISTROS=$DISTROS"

    for DISTRO in $DISTROS ; do
        debug 2 "  found_distro: $ID:$DARCH-$RELEASE compare $DISTRO"
        local G='' R='*' A='*'
        if [[ $DISTRO = *+ ]] ; then 
            G=y
            DISTRO=${DISTRO%\+}
            debug 2 "    distro_found: $DISTRO or greater"
        fi
        if [[ $DISTRO = *-* ]] ; then
            R=${DISTRO#*-}
            DISTRO=${DISTRO%-*}
        fi
        if [[ $DISTRO = *:* ]] ; then
            A=${DISTRO#*:}
            DISTRO=${DISTRO%:*}
        fi
        local MSG="    found_distro: Are we running DISTRO=$DISTRO ARCH=$A REL=$R ${G:+or-newer }?"
        # shellcheck disable=SC2053
        if [[ $ID = "$DISTRO" && $DARCH = $A ]] ; then
            debug 2 "    found_distro: RELEASE=$RELEASE G=$G R=$R"
            if [[ $G = y && $R != "*" ]] && version_greater_equal "$RELEASE" "$R" ; then
                debug 2 "    distro_found: $RELEASE >= $R"
                R='*'
            fi
            # shellcheck disable=SC2053
            if [[ $RELEASE = $R ]] ; then
                debug 2 "$MSG Yes"
                return 0
            fi
        fi
        debug 2 "$MSG No"
    done
    return 1
}

#===============================================================================
# TEST: Blacklisted Linux distribution?
check_distro_bl() {
    local ID=$1 DARCH=$2 RELEASE=$3 CODENAME=$4 DISTRO_BL=$5
    debug 1 "check_distro_bl: ID=$ID DARCH=$DARCH RELEASE=$RELEASE DISTRO_BL=$DISTRO_BL"

    if [[ -n $SIMULATE_FAILURE ]] ; then
        DISTRO_BL=$ID-$RELEASE
    fi
    if [[ -z $ID || -z $DARCH ]] ; then
        bug "Wasn't able to determine Linux distribution" \
            "$0 --gather-info"
    elif [[ -n $DISTRO_BL ]] ; then
        if found_distro "$ID" "$DARCH" "$RELEASE" "$DISTRO_BL" ; then
            fail "This Linux distribution can't be used for this activity: $ID:$DARCH-$RELEASE ${CODENAME:+($CODENAME)}"
            FAILED=y
            [[ -n $SIMULATE_FAILURE ]] || exit 1
        fi
    fi
}

#===============================================================================
# TEST: Right Linux distribution?
check_distro() {
    local ID=$1 DARCH=$2 RELEASE=$3 CODENAME=$4 DESCRIPTION=$5 DISTROS=$6
    debug 1 "check_distro: ID=$ID DARCH=$DARCH RELEASE=$RELEASE DISTROS=$DISTROS"

    if [[ -n $SIMULATE_FAILURE ]] ; then
        DISTROS=NotThisDistro-0
    fi
    if [[ -z $DISTROS ]] ; then
        notice "No required Linux distribution (Currently running $DESCRIPTION)"
    elif [[ -z $ID || -z $DARCH ]] ; then
        bug "Wasn't able to determine Linux distribution" \
            "$0 --gather-info"
    else
        if found_distro "$ID" "$DARCH" "$RELEASE" "$DISTROS" ; then
            pass "Linux distribution is $ID:$DARCH-$RELEASE ${CODENAME:+($CODENAME)}"
        else
            warn "Linux distribution is $ID:$DARCH-$RELEASE ${CODENAME:+($CODENAME)}"
            fail "The distribution must be: $DISTROS"
            FAILED=y
        fi
    fi
}

#===============================================================================
# TEST: Is the kernel configured properly?
check_kernel_config() {
    local CONFIGS=$1

    if [[ -n $CONFIGS ]] ; then
        verbose "check_kernel_config: CONFIGS=$CONFIGS"
        local MISSINGCONFIG KERNELCONFIG
        KERNELCONFIG=${KERNELCONFIG:-/boot/config-$(uname -r)}
        if [[ ! -f $KERNELCONFIG ]] ; then
            warn "Wasn't able to find kernel config. You can specify it by setting KERNELCONFIG=<filename>"
            return 1
        fi
        for CONFIG in $CONFIGS ; do
            grep -qc "CONFIG_$CONFIG" "$KERNELCONFIG" || MISSINGCONFIG+=" $CONFIG"
        done
        if [[ -z $MISSINGCONFIG ]] ; then
            pass "The Current kernel is properly configured: $CONFIGS"
        else
            fail "Current kernel is missing these options:$MISSINGCONFIG"
            FAILED=y
        fi
    fi
}

#===============================================================================
# TEST: Is there Internet?
#   You can set the PING_HOST environment variable in order to override the default
check_internet() {
    local INTERNET=$1
    local AVAILABLE=$2
    local PING_HOST=${3:-8.8.8.8}

    if [[ -n $INTERNET ]] ; then
        verbose "check_internet: INTERNET=$INTERNET AVAILABLE=${AVAILABLE:-n} PING_HOST=$PING_HOST"
        if [[ -n $NONETWORK ]] ; then
            warn "check_internet: No network selected."
        elif [[ -z $SIMULATE_FAILURE && -n $AVAILABLE ]] ; then
            pass "Internet is available (which is required in this case)"
        elif [[ -z $SIMULATE_FAILURE ]] && ping -q -c 1 "$PING_HOST" >/dev/null 2>&1 ; then
            verbose "check_internet with ping PING_HOST=$PING_HOST"
            pass "Internet is available (which is required in this case)"
        else
            fail "Internet doesn't appear to be available"
            FAILED=y
        fi
    else
        verbose "Not requiring Internet availability"
    fi
}

#===============================================================================
# We need this because lspci may not be installed
find_devices() {
    local DATA=$1
    local RETURN=$2
    debug 1 "find_devices: DATA=... RETURN=$RETURN"

    [[ -n $DATA ]] || return 1
    local DEV
    for DEV in /sys/bus/pci/devices/*; do
        local PCIID
        # shellcheck disable=SC2086
        PCIID="$(cat $DEV/vendor) $(cat $DEV/device)"
        debug 2 "  Check found device $DEV $PCIID"
        if grep -q "$PCIID" <<<"$DATA" ; then
            local RET
            RET=$(grep "$PCIID" <<<"$DATA" | cut -d' ' -f4-)
            # shellcheck disable=SC2086
            eval $RETURN="'$RET'"
            return 0
        fi
    done
    return 1
}

#===============================================================================
# Info about PCI devices for finding SD/MMC reader
# Generated by perl script on machine which has /usr/share/misc/pci.ids
# pcigrep 'MMC|MS-?PRO|SD|xD' '3PCIO|9060SD|ASDE|Broadcast|CXD|DASD|DeckLink|ESD|HSD|Frame|G200|ISDN|Kona|Magic|MSDDC|MVC101|Napatech|PSDMS|PXD1000|Quadro|SDC|SDF|SDK|SDM|SDR|SDRAM|SDS|SDT|SSD|TXD|Video|VisionSD|Xena'
SDDEV="
0x1022 0x7806 # Advanced Micro Devices, Inc. [AMD] - FCH SD Flash Controller
0x1022 0x7813 # Advanced Micro Devices, Inc. [AMD] - FCH SD Flash Controller
0x1022 0x7906 # Advanced Micro Devices, Inc. [AMD] - FCH SD Flash Controller
0x104c 0x803b # Texas Instruments - 5-in-1 Multimedia Card Reader (SD/MMC/MS/MS PRO/xD)
0x104c 0x803c # Texas Instruments - PCIxx12 SDA Standard Compliant SD Host Controller
0x104c 0xac4b # Texas Instruments - PCI7610 SD/MMC controller
0x104c 0xac8f # Texas Instruments - PCI7420/7620 SD/MS-Pro Controller
0x10b9 0x5473 # ULi Electronics Inc. - M5473 SD-MMC Controller
0x1106 0x95d0 # VIA Technologies, Inc. - SDIO Host Controller
0x1179 0x0803 # Toshiba America Info Systems - TC6371AF SD Host Controller
0x1179 0x0805 # Toshiba America Info Systems - SD TypA Controller
0x1180 0x0575 # Ricoh Co Ltd - R5C575 SD Bus Host Adapter
0x1180 0x0576 # Ricoh Co Ltd - R5C576 SD Bus Host Adapter
0x1180 0x0822 # Ricoh Co Ltd - R5C822 SD/SDIO/MMC/MS/MSPro Host Adapter
0x1180 0x0841 # Ricoh Co Ltd - R5C841 CardBus/SD/SDIO/MMC/MS/MSPro/xD/IEEE1394
0x1180 0x0843 # Ricoh Co Ltd - R5C843 MMC Host Controller
0x1180 0x0852 # Ricoh Co Ltd - xD-Picture Card Controller
0x1180 0xe822 # Ricoh Co Ltd - MMC/SD Host Controller
0x1180 0xe823 # Ricoh Co Ltd - PCIe SDXC/MMC Host Controller
0x1180 0xe852 # Ricoh Co Ltd - PCIe xD-Picture Card Controller
0x1217 0x7120 # O2 Micro, Inc. - Integrated MMC/SD Controller
0x1217 0x7130 # O2 Micro, Inc. - Integrated MS/xD Controller
0x1217 0x8120 # O2 Micro, Inc. - Integrated MMC/SD Controller
0x1217 0x8130 # O2 Micro, Inc. - Integrated MS/MSPRO/xD Controller
0x1217 0x8320 # O2 Micro, Inc. - OZ600 MMC/SD Controller
0x1217 0x8321 # O2 Micro, Inc. - Integrated MMC/SD controller
0x1217 0x8330 # O2 Micro, Inc. - OZ600 MS/xD Controller
0x1217 0x8520 # O2 Micro, Inc. - SD/MMC Card Reader Controller
0x14e4 0x16bc # Broadcom Corporation - BCM57765/57785 SDXC/MMC Card Reader
0x14e4 0x16bf # Broadcom Corporation - BCM57765/57785 xD-Picture Card Reader
0x1524 0x0551 # ENE Technology Inc - SD/MMC Card Reader Controller
0x1524 0x0750 # ENE Technology Inc - ENE PCI SmartMedia / xD Card Reader Controller
0x1524 0x0751 # ENE Technology Inc - ENE PCI Secure Digital / MMC Card Reader Controller
0x1679 0x3000 # Tokyo Electron Device Ltd. - SD Standard host controller [Ellen]
0x197b 0x2381 # JMicron Technology Corp. - Standard SD Host Controller
0x197b 0x2382 # JMicron Technology Corp. - SD/MMC Host Controller
0x197b 0x2384 # JMicron Technology Corp. - xD Host Controller
0x197b 0x2386 # JMicron Technology Corp. - Standard SD Host Controller
0x197b 0x2387 # JMicron Technology Corp. - SD/MMC Host Controller
0x197b 0x2389 # JMicron Technology Corp. - xD Host Controller
0x197b 0x2391 # JMicron Technology Corp. - Standard SD Host Controller
0x197b 0x2392 # JMicron Technology Corp. - SD/MMC Host Controller
0x197b 0x2394 # JMicron Technology Corp. - xD Host Controller
0x8086 0x0807 # Intel Corporation - Moorestown SD Host Ctrl 0
0x8086 0x0808 # Intel Corporation - Moorestown SD Host Ctrl 1
0x8086 0x0f14 # Intel Corporation - ValleyView SDIO Controller
0x8086 0x0f15 # Intel Corporation - ValleyView SDIO Controller
0x8086 0x0f16 # Intel Corporation - ValleyView SDIO Controller
0x8086 0x0f17 # Intel Corporation - ValleyView SDIO Controller
0x8086 0x811c # Intel Corporation - System Controller Hub (SCH Poulsbo) SDIO Controller #1
0x8086 0x811d # Intel Corporation - System Controller Hub (SCH Poulsbo) SDIO Controller #2
0x8086 0x811e # Intel Corporation - System Controller Hub (SCH Poulsbo) SDIO Controller #3
0x8086 0x8809 # Intel Corporation - Platform Controller Hub EG20T SDIO Controller #1
0x8086 0x880a # Intel Corporation - Platform Controller Hub EG20T SDIO Controller #2
0x8086 0x9c35 # Intel Corporation - Lynx Point-LP SDIO Controller
"

#===============================================================================
# TEST: Is there a card reader?
check_cardreader() {
    local CARDREADER=$1
    debug 1 "check_cardreader: CARDREADER=$CARDREADER"

    if [[ -n $CARDREADER ]] ; then
        verbose "check_cardreader: CARDREADER=$CARDREADER"
        local DEV CRFOUND
        for DEV in $(cd /dev; echo mmcblk? sd?); do
            [ -e "/dev/$DEV" ] || continue
            local META='ID_DRIVE_MEDIA_FLASH_SD=1|ID_USB_DRIVER=usb-storage|ID_VENDOR=Generic'
            if udevadm info --query=all --name "$DEV" | egrep -q $META ; then
                CRFOUND="Potential card Reader was found: /dev/$DEV (however might be USB thumbdrive)"
            elif find_devices "$SDDEV" CRFOUND; then
                CRFOUND="Built-in Card Reader was found: $CRFOUND"
            fi
        done
        if [[ -n $SIMULATE_FAILURE || -z $CRFOUND ]] ; then
            warn "Card Reader wasn't found, and you require one for this activity (Maybe it isn't plugged in?)"
            notice "A cardreader will be provided in class, so if one isn't found before class, that's okay."
            WARNINGS=y
        else
            pass "$CRFOUND"
        fi
    fi
}

#===============================================================================
# Info about PCI devices for determining if we are running in a VM
# Generated by perl script on machine which has /usr/share/misc/pci.ids
# ./pcigrep | grep -i Microsoft
# Detect Hyper-V (Azure and other MS hypervisors)
HYPERV="
0x1414 0x0001 # Microsoft Corporation - MN-120 (ADMtek Centaur-C based)
0x1414 0x0002 # Microsoft Corporation - MN-130 (ADMtek Centaur-P based)
0x1414 0x5353 # Microsoft Corporation - Hyper-V virtual VGA
0x1414 0x5801 # Microsoft Corporation - XMA Decoder (Xenon)
0x1414 0x5802 # Microsoft Corporation - SATA Controller - CdRom (Xenon)
0x1414 0x5803 # Microsoft Corporation - SATA Controller - Disk (Xenon)
0x1414 0x5804 # Microsoft Corporation - OHCI Controller 0 (Xenon)
0x1414 0x5805 # Microsoft Corporation - EHCI Controller 0 (Xenon)
0x1414 0x5806 # Microsoft Corporation - OHCI Controller 1 (Xenon)
0x1414 0x5807 # Microsoft Corporation - EHCI Controller 1 (Xenon)
0x1414 0x580a # Microsoft Corporation - Fast Ethernet Adapter (Xenon)
0x1414 0x580b # Microsoft Corporation - Secure Flash Controller (Xenon)
0x1414 0x580d # Microsoft Corporation - System Management Controller (Xenon)
0x1414 0x5811 # Microsoft Corporation - Xenos GPU (Xenon)
"
# ./pcigrep Virtio
KVM="
0x1af4 0x1000 # Red Hat, Inc - Virtio network device
0x1af4 0x1001 # Red Hat, Inc - Virtio block device
0x1af4 0x1002 # Red Hat, Inc - Virtio memory balloon
0x1af4 0x1003 # Red Hat, Inc - Virtio console
0x1af4 0x1004 # Red Hat, Inc - Virtio SCSI
0x1af4 0x1005 # Red Hat, Inc - Virtio RNG
0x1af4 0x1009 # Red Hat, Inc - Virtio filesystem
0x1af4 0x1110 # Red Hat, Inc - Virtio Inter-VM shared memory
"
# ./pcigrep QEMU
QEMU="
0x1013 0x1100 # Cirrus Logic - QEMU Virtual Machine
0x1022 0x1100 # Advanced Micro Devices, Inc. [AMD] - QEMU Virtual Machine
0x1033 0x1100 # NEC Corporation - QEMU Virtual Machine
0x106b 0x1100 # Apple Inc. - QEMU Virtual Machine
0x10ec 0x1100 # Realtek Semiconductor Co., Ltd. - QEMU Virtual Machine
0x10ec 0x1100 # Realtek Semiconductor Co., Ltd. - QEMU Virtual Machine
0x1106 0x1100 # VIA Technologies, Inc. - QEMU Virtual Machine
0x1af4 0x1100 # Red Hat, Inc - QEMU Virtual Machine
0x1b36 0x0001 # Red Hat, Inc. - QEMU PCI-PCI bridge
0x1b36 0x0002 # Red Hat, Inc. - QEMU PCI 16550A Adapter
0x1b36 0x1100 # Red Hat, Inc. - QEMU Virtual Machine
0x1b36 0x0003 # Red Hat, Inc. - QEMU PCI Dual-port 16550A Adapter
0x1b36 0x1100 # Red Hat, Inc. - QEMU Virtual Machine
0x1b36 0x0004 # Red Hat, Inc. - QEMU PCI Quad-port 16550A Adapter
0x1b36 0x1100 # Red Hat, Inc. - QEMU Virtual Machine
0x1b36 0x0005 # Red Hat, Inc. - QEMU PCI Test Device
0x1b36 0x1100 # Red Hat, Inc. - QEMU Virtual Machine
0x1b36 0x1100 # Red Hat, Inc. - QEMU Virtual Machine
0x8086 0x1100 # Intel Corporation - QEMU Virtual Machine
0x8086 0x1100 # Intel Corporation - QEMU Virtual Machine
0x8086 0x1100 # Intel Corporation - QEMU Virtual Machine
0x8086 0x1100 # Intel Corporation - Qemu virtual machine
0x8086 0x1100 # Intel Corporation - QEMU Virtual Machine
0x8086 0x1100 # Intel Corporation - QEMU Virtual Machine
0x8086 0x1100 # Intel Corporation - QEMU Virtual Machine
0x8086 0x1100 # Intel Corporation - QEMU Virtual Machine
0x8086 0x1100 # Intel Corporation - QEMU Virtual Machine
0x8086 0x1100 # Intel Corporation - QEMU Virtual Machine
0x8086 0x1100 # Intel Corporation - QEMU Virtual Machine
0x8086 0x1100 # Intel Corporation - QEMU Virtual Machine
0x8086 0x1100 # Intel Corporation - QEMU Virtual Machine
0x8086 0x1100 # Intel Corporation - QEMU Virtual Machine
0x8086 0x1100 # Intel Corporation - QEMU Virtual Machine
0x8086 0x1100 # Intel Corporation - QEMU Virtual Machine
0x8086 0x1100 # Intel Corporation - QEMU Virtual Machine
0x8086 0x1100 # Intel Corporation - QEMU Virtual Machine
0x8086 0x1100 # Intel Corporation - QEMU Virtual Machine
0x8086 0x1100 # Intel Corporation - QEMU Virtual Machine
0x8086 0x1100 # Intel Corporation - QEMU Virtual Machine
0x8086 0x1100 # Intel Corporation - QEMU Virtual Machine
0x8086 0x5845 # Intel Corporation - QEMU NVM Express Controller
0x8086 0x1100 # Intel Corporation - QEMU Virtual Machine
0x8086 0x1100 # Intel Corporation - Qemu virtual machine
0x8086 0x1100 # Intel Corporation - Qemu virtual machine
0x8086 0x1100 # Intel Corporation - QEMU Virtual Machine
0x8086 0x1100 # Intel Corporation - QEMU Virtual Machine
0x8086 0x1100 # Intel Corporation - Qemu virtual machine
"
# ./pcigrep | grep Parallels
PARALLELS="
0x1ab8 0x4000 # Parallels, Inc. - Virtual Machine Communication Interface
0x1ab8 0x4005 # Parallels, Inc. - Accelerated Virtual Video Adapter
0x1ab8 0x4006 # Parallels, Inc. - Memory Ballooning Controller
"
# ./pcigrep VirtualBox
VBOX="
0x80ee 0xbeef # InnoTek Systemberatung GmbH - VirtualBox Graphics Adapter
0x80ee 0xcafe # InnoTek Systemberatung GmbH - VirtualBox Guest Service
"
# ./pcigrep | grep -i VMware
VMWARE="
0x15ad 0x0405 # VMware - SVGA II Adapter
0x15ad 0x0710 # VMware - SVGA Adapter
0x15ad 0x0720 # VMware - VMXNET Ethernet Controller
0x15ad 0x0740 # VMware - Virtual Machine Communication Interface
0x15ad 0x0770 # VMware - USB2 EHCI Controller
0x15ad 0x0774 # VMware - USB1.1 UHCI Controller
0x15ad 0x0778 # VMware - USB3 xHCI Controller
0x15ad 0x0790 # VMware - PCI bridge
0x15ad 0x07a0 # VMware - PCI Express Root Port
0x15ad 0x07b0 # VMware - VMXNET3 Ethernet Controller
0x15ad 0x07c0 # VMware - PVSCSI SCSI Controller
0x15ad 0x07e0 # VMware - SATA AHCI controller
0x15ad 0x0801 # VMware - Virtual Machine Interface
0x15ad 0x0800 # VMware - Hypervisor ROM Interface
0x15ad 0x1977 # VMware - HD Audio Controller
0xfffe 0x0710 # VMWare Inc (temporary ID) - Virtual SVGA
"
# ./pcigrep | grep -i XenSource
XEN="
0x5853 0x0001 # XenSource, Inc. - Xen Platform Device
0x5853 0xc110 # XenSource, Inc. - Virtualized HID
0x5853 0xc147 # XenSource, Inc. - Virtualized Graphics Device
0xfffd 0x0101 # XenSource, Inc. - PCI Event Channel Controller
"

#===============================================================================
# TEST: Is this a VM?
check_for_vm() {
    local NATIVELINUX=$1
    local VMOKAY=$2
    debug 1 "check_for_vm: NATIVELINUX=$NATIVELINUX VMOKAY=$VMOKAY"

    shopt -s nocasematch
    if [[ -n $NATIVELINUX || $VMOKAY == n || $VMOKAY =~ discouraged ]] ; then
        local ACTION INVM VMREASON HV
        if [[ $VMOKAY =~ discouraged ]] ; then
            ACTION=warn
            VMREASON="which is $VMOKAY for this course"
        else
            ACTION=fail
            VMREASON="which is not possible for this course"
        fi
        HV=$(lscpu | grep "^Hypervisor vendor:" | sed 's/^.*: *//')
        if [[ -n $HV ]] ; then
            $ACTION "You're using a virtual machine ($HV) $VMREASON"
            INVM=y
        elif find_devices "$HYPERV" INVM ; then
            $ACTION "You're in Hyper-V (or Azure) $VMREASON (Found: $INVM)"
        elif find_devices "$KVM" INVM ; then
            $ACTION "You're in KVM $VMREASON (Found: $INVM)"
        elif find_devices "$QEMU" INVM ; then
            $ACTION "You're in QEMU $VMREASON (Found: $INVM)"
        elif find_devices "$PARALLELS" INVM ; then
            $ACTION "You're in Parallels $VMREASON (Found: $INVM)"
        elif find_devices "$VBOX" INVM ; then
            $ACTION "You're in VirtualBox $VMREASON (Found: $INVM)"
        elif find_devices "$VMWARE" INVM ; then
            $ACTION "You're in VMWare $VMREASON (Found: $INVM)"
        elif find_devices "$XEN" INVM ; then
            $ACTION "You're in Xen $VMREASON (Found: $INVM)"
        fi
        debug 1 "  check_for_vm: INVM=$INVM"
        if [[ -n $INVM ]] ; then
            [[ $ACTION == warn ]] && WARNINGS=y || FAILED=y
        else
            if [[ $NATIVELINUX =~ $RECOMMENDED || $NATIVELINUX =~ $REQUIRED ]] ; then
                NLREASON=" which is $NATIVELINUX for this course"
            fi
            pass "You are running Linux natively$NLREASON"
        fi
    fi
    if [[ $VMOKAY =~ nested ]] ; then
        local NESTED="/sys/module/kvm_intel/parameters/nested" CANNEST=N
        if [[ -v $NESTED ]] ; then
            CANNEST=$(cat "$NESTED")
        fi
        if [[ $CANNEST == Y ]] ; then
            pass "Your CPU can do nested virtualization"
        else
            fail "Your CPU isn't configured to do nested virtualization which is required for this course"
            notice "Try to enable it by booting with kvm-intel.nested=1 argument on the kernel command line and try again."
            warn "Your CPU may or may not be able to support nested virtualization. You'll have to try and see if it is"
            FAILED=y
        fi
    fi
}

#===============================================================================
if [[ -n $DETECT_VM ]] ; then
    check_for_vm 0 1
    exit 0
fi

#===============================================================================
# TEST: Are these symlink patterns satisfied?
check_symlinks() {
    local SYMLINKS=$1
    local ENTRY FILE PAT L
    debug 1 "check_symlinks: SYMLINKS=$SYMLINKS"

    for ENTRY in $SYMLINKS; do
        IFS=: read -r FILE PAT <<<$ENTRY
        if [[ ! -L $FILE ]] ; then
            verbose "$FILE isn't a symlink ($PAT)"
            continue
        fi
        L=$(readlink "$FILE")
        [[ -z $SIMULATE_FAILURE ]] || L+="ERROR"
        debug 2 "FILE=$FILE PAT=$PAT L=$L"
        case $PAT in
            !*) debug 2 "!* FILE=$FILE PAT=$PAT L=$L"
                if [[ ! $L =~ ${PAT#!} ]] ; then
                    verbose "Symlink $FILE isn't $PATH ($L)"
                else
                    fail "Symlink $FILE is $L (${PAT#!})"
                    FAILED=y
                fi ;;
            *) debug 2 "* FILE=$FILE PAT=$PAT L=$L"
                if [[ $L =~ $PAT ]] ; then
                    verbose "Symlink $FILE is $L ($PAT)"
                else
                    fail "Symlink $FILE isn't ${PAT#!}"
                    FAILED=y
                fi ;;
        esac
    done
}

#===============================================================================
# TEST: Check versions of tools.
check_versions() {
    local VERSIONS=$1
    local ENTRY CMD VER V
    debug 1 "check_versions: VERSIONS=$VERSIONS"

    for ENTRY in $VERSIONS ; do
        IFS=: read -r CMD VER <<<$ENTRY
        V=$($CMD --version 2>&1 | sed -re 's/[a-zA-Z ]+//g')
        [[ -z $SIMULATE_FAILURE ]] || V=999;
        case $VER in
            \<*) if ! version_greater_equal "$V" "${VER#<}" ; then
                    verbose "Version for $CMD: $V $VER"
                else
                    fail "Version for $CMD: $V !$VER"
                    FAILED=y
                fi ;;
            =*) if [[ $V = "${VER#=}" ]] ; then
                    verbose "Version for $CMD: $V $VER"
                else
                    fail "Version for $CMD: $V !$VER"
                    FAILED=y
                fi ;;
            \>*) if version_greater_equal "$V" "${VER#>}" ; then
                    verbose "Version for $CMD: $V $VER"
                else
                    fail "Version for $CMD: $V !$VER"
                    FAILED=y
                fi ;;
            *)  if [[ $V =~ $VER ]] ; then
                    verbose "Version for $CMD: $V =~ $VER"
                else
                    fail "Version for $CMD: $V !~ $VER"
                    FAILED=y
                fi ;;
        esac
    done
}

#===============================================================================
check_all() {
    check_cpu "$ARCH"
    check_cpu_flags "$CPUFLAGS"
    check_number_of_cpus "$CPUS"
    check_bogomips "$BOGOMIPS"
    check_ram "$RAM"
    check_free_disk "$DISK" "${BUILDHOME:-$HOME}"
    check_free_boot_disk "$BOOT" "$BOOTDIR"
    check_distro_arch "$ARCH" "$DISTRO_ARCH"
    check_distro_bl "$ID" "$DARCH" "$RELEASE" "$CODENAME" "$DISTRO_BL"
    check_distro "$ID" "$DARCH" "$RELEASE" "$CODENAME" "$DESCRIPTION" "$DISTROS"
    check_kernel_config "$CONFIGS"
    check_internet "$INTERNET" "$INTERNET_AVAILABLE" "$PING_HOST"
    check_cardreader "$CARDREADER"
    check_for_vm "$NATIVELINUX" "$VMOKAY"
    check_symlinks "$SYMLINKS"
    check_versions "$VERSIONS"
}


EPELURL="http://download.fedoraproject.org/pub/epel"

#===============================================================================
# See whether sudo is available
check_sudo() {
    local DID=$1 DREL=$2
    if ! sudo -V >/dev/null 2>&1 ; then
        [[ $USER == root ]] || warn "sudo isn't installed, so you will have to run these commands as root instead"
        # Provide sudo wrapper for try_packages
        sudo() {
             if [[ $USER == root ]] ; then
                 "$@"
             else
                 highlight "Please enter root password to run the following as root"
                 highlight "$*" >&2
                 su -c "$*" root
             fi
        }
        INSTALL=y NO_CHECK=y NO_PASS=y NO_WARN=y try_packages "$DID" "$DREL" ACTIVITY sudo
        unset sudo
        if [[ -f /etc/sudoers ]] ; then
            # Add $USER to sudoers
            highlight "Please enter root password to add yourself to sudoers"
            su -c "sed -ie 's/^root\(.*ALL$\)/root\1\n$USER\1/' /etc/sudoers" root
        fi
        highlight "From now on you will be asked for your user password"
    fi
}

#===============================================================================
check_repos() {
    local ID=$1
    local RELEASE=$2
    local CODENAME=$3
    local ARCH=$4
    local CHANGES REPOS SECTION
    debug 1 "check_repos: ID=$ID RELEASE=$RELEASE CODENAME=$CODENAME ARCH=$ARCH"
    verbose "Checking installed repos"

    #-------------------------------------------------------------------------------
    if [[ $ID == Debian ]] ; then
        debug 2 "  Check repos for Debian"
        REPOS="contrib non-free"
        local LISTFILE=/etc/apt/sources.list.d/debian.list
        # shellcheck disable=SC2046
        for SECTION in $REPOS ; do
            # shellcheck disable=SC2016
            while read LINE ; do
                [[ -n $LINE ]] || continue
                debug 2 "    Is '$LINE' enabled?"
                [[ -f $LISTFILE ]] || sudo touch $LISTFILE
                if ! grep -h -q "$LINE" $LISTFILE ; then
                    echo "$LINE" | sudo tee -a $LISTFILE
                    verbose "Adding '$LINE' to $LISTFILE"
                    CHANGES=y
                fi
            done <<< "$(grep -h "deb .*debian.* main" /etc/apt/sources.list \
                $([[ -f $LISTFILE ]] && echo "$LISTFILE") \
                | sed -e '/^#/d; /"$SECTION"/d; s/main.*/'"$SECTION"'/')"
        done
        if [[ -n $CHANGES ]] ; then
            notice "Enabling $REPOS in sources.list... updating"
            sudo apt-get -qq update
        fi

    #-------------------------------------------------------------------------------
    elif [[ $ID =~ CentOS|RHEL ]] ; then
        debug 2 "  Check repos for CentOS|RHEL"
        if rpm -q epel-release >/dev/null ; then
            verbose "epel is already installed"
        else
            case "$RELEASE" in
                6*) [[ $ARCH != i386 && $ARCH != x86_64 ]] \
                        || EPEL="$EPELURL/6/i386/epel-release-6-8.noarch.rpm" ;;
                7*) [[ $ARCH != x86_64 ]] \
                        || EPEL="$EPELURL/7/x86_64/e/epel-release-7-8.noarch.rpm" ;;
            esac
            if [[ -n $EPEL ]] ; then
                notice "Installing epel in ${ID}..."
                sudo rpm -Uvh $EPEL
            fi
        fi

    #-------------------------------------------------------------------------------
    elif [[ $ID == Ubuntu ]] ; then
        debug 2 "  Check repos for Ubuntu"
        REPOS="universe multiverse"
        for SECTION in $REPOS ; do
            local DEB URL DIST SECTIONS
            # shellcheck disable=SC2094
            while read DEB URL DIST SECTIONS ; do
                [[ $URL =~ http && $DIST =~ $CODENAME && $SECTIONS =~ main ]] || continue
                [[ $URL =~ archive.canonical.com || $URL =~ extras.ubuntu.com ]] && continue
                debug 2 "    $ID: is $SECTION enabled for $URL $DIST $SECTIONS"
                # shellcheck disable=2094
                if ! egrep -q "^$DEB $URL $DIST .*$SECTION" /etc/apt/sources.list ; then
                    verbose "Running: sudo add-apt-repository '$DEB $URL $DIST $SECTION'"
                    sudo add-apt-repository "$DEB $URL $DIST $SECTION"
                    CHANGES=y
                fi
            done </etc/apt/sources.list
        done
        if [[ -n $CHANGES ]] ; then
            notice "Enabling $REPOS in sources.list... updating"
            sudo apt-get -qq update
        fi
    fi
}

#===============================================================================
BUILDDEPSTR=build-dep_
no_build_dep() {
    sed 's/ /\n/g' <<< "$@" | grep -v $BUILDDEPSTR
}

#===============================================================================
only_build_dep() {
    sed 's/ /\n/g' <<< "$@" | grep $BUILDDEPSTR | sed "s/$BUILDDEPSTR//g"
}

#===============================================================================
RFCONFIG="$HOME/.config/${CMDBASE%.sh}"
clear_installed() {
    if [[ -n $ALL_ACTIVITIES ]] ; then
        $DRYRUN rm -f "$RFCONFIG"/*-installed-packages.list
    else
        local ACTIVITY FILE
        # shellcheck disable=SC2048
        for ACTIVITY in $* ; do
            FILE="$RFCONFIG/${ACTIVITY}-installed-packages.list"
            if [[ -f $FILE ]] ; then
                $DRYRUN rm "$FILE"
            fi
        done
    fi
}

#===============================================================================
read_installed() {
    if [[ -n $ALL_ACTIVITIES ]] ; then
        cat "$RFCONFIG"/*-installed-packages.list
    else
        local ACTIVITY FILE
        for ACTIVITY in "$@" ; do
            FILE="$RFCONFIG/${ACTIVITY}-installed-packages.list"
            if [[ -f $FILE ]] ; then
                cat "$FILE"
            fi
        done
    fi
}

#===============================================================================
save_installed() {
    local ACTIVITY FILE
    ACTIVITY=$(head -1 <<< $1); shift
    FILE="$RFCONFIG/${ACTIVITY%% *}-installed-packages.list"
    # shellcheck disable=SC2001
    echo "$*" | sed -e 's/ /\n/g' >>"$FILE"
}

#===============================================================================
deb_check() {
    verbose "Check dpkg is in a good state"
    while [[ $( (dpkg -C 2>/dev/null || sudo dpkg -C) | wc -l) -gt 0 ]] ; do
        local PKG FILE
        if sudo dpkg -C | grep -q "missing the md5sums" ; then
            for PKG in $(sudo dpkg -C | awk '/^ / {print $1}') ; do
                [[ ! -f /var/lib/dpkg/info/${PKG}.md5sums ]] || continue
                if warn_wait "The md5sums for $PKG need updating. Can I fix it?" ; then
                    for FILE in $(sudo dpkg -L "$PKG" | grep -v "^/etc" | sort) ; do
                        [[ -f $FILE && ! -L $FILE ]] && md5sum "$FILE"
                    done | sed 's|/||' | sudo tee "/var/lib/dpkg/info/${PKG}.md5sums" >/dev/null
                fi
            done
            verbose "Updated all missing MD5SUM files"
        else
            if warn_wait "dpkg reports some issues with the package system. I can't continue without these being fixed.\n    Is it okay if I try a \"dpkg --configure -a\"?" ; then
                sudo dpkg --configure -a
                verbose "Attempted to configure all unconfigured packages"
            fi
        fi
    done
}

#===============================================================================
# Install packages with apt-get
debinstall() {
    local PKGLIST BDLIST NEWPKG
    local ACTIVITY=$1; shift
    PKGLIST=$(no_build_dep "$@")
    BDLIST=$(only_build_dep "$@")
    [[ -z $PKGLIST && -z $BDLIST ]] && return
    # shellcheck disable=SC2086
    debug 1 "debinstall: "$*

    deb_check

    local APTGET="apt-get --no-install-recommends"
    # Check for packages which can't be found
    if [[ -n $PKGLIST ]] ; then
        local ERRPKG
        # shellcheck disable=SC2086
        ERRPKG=$($APTGET --dry-run install $PKGLIST 2>&1 \
            | awk '/^E: Unable/ {print $6}; /^E: Package/ {print $3}' | grep -v -- '-f' | sed -e "s/'//g")
        if [[ -n $ERRPKG ]] ; then
            warn "Can't find package(s) in index: $ERRPKG"
            echo "Looks like you may need to run 'sudo apt-get update' and try this again"
            MISSING_PACKAGES=y
            return
        fi
    fi

    # Find new packages which need installing
    # shellcheck disable=SC2046
    NEWPKG=$(list_sort $(
        # shellcheck disable=SC2086
        [[ -z $PKGLIST ]] || $APTGET --dry-run install $PKGLIST | awk '/^Inst / {print $2}';
        # shellcheck disable=SC2086
        [[ -z $BDLIST ]] || $APTGET --dry-run build-dep $BDLIST | awk '/^Inst / {print $2}'))
    [[ -n $SIMULATE_FAILURE ]] && NEWPKG=$PKGLIST
    if [[ -z $NEWPKG ]] ; then
        pass "All required packages are already installed"
        return 0
    else
        warn "Some packages are missing"
        WARNINGS=y
        MISSING_PACKAGES=y
        if [[ -z $INSTALL ]] ; then
            # shellcheck disable=SC2086
            notice "Need to install:" $NEWPKG
            fix_missing "You can install missing packages" \
                    "$0 --install $ACTIVITY" \
                    "sudo $APTGET install $NEWPKG"
        else
            if [[ -n $YES ]] ; then
                debug 1 "  debinstall: always --yes, so not asking; just continue."
                CONTINUE=y 
            else
                # shellcheck disable=SC2086
                ask "About to install:" $NEWPKG "\nIs that okay? [y/N]"
                read CONFIRM
                case $CONFIRM in
                    y*|Y*|1) CONTINUE=y;;
                esac
            fi
            if [[ -n $CONTINUE ]]  ; then
                # shellcheck disable=SC2086
                $DRYRUN sudo $APTGET install $NEWPKG
                if [[ -z $NO_CHECK ]] ; then
                    # shellcheck disable=SC2086
                    FAILPKG=$( (sudo $APTGET --dry-run install $PKGLIST | awk '/^Conf / {print $2}') 2>&1 )
                    if [[ -n $FAILPKG ]] ; then
                        warn "Some packages didn't install: $FAILPKG"
                        WARNINGS=y
                    else
                        save_installed "$ACTIVITY" "$NEWPKG"
                        pass "All required packages are now installed"
                        unset MISSING_PACKAGES
                        return 0
                    fi
                fi
            fi
        fi
    fi
    return 1
}

#===============================================================================
# Install packages with yum or zypper
rpminstall() {
    local ACTIVITY=$1; shift
    local TOOL=$1; shift
    local PKGLIST=$*
    [[ -z $PKGLIST ]] && return
    debug 1 "rpminstall: TOOL=$TOOL $PKGLIST"
    local NEWPKG

    # shellcheck disable=SC2046,SC2086
    NEWPKG=$(list_sort $(rpm -q $PKGLIST | awk '/is not installed$/ {print $2}'))
    [[ -n $SIMULATE_FAILURE ]] && NEWPKG=$PKGLIST
    if [[ -z $NEWPKG ]] ; then
        pass "All required packages are already installed"
        return 0
    else
        warn "Some packages are missing"
        # shellcheck disable=SC2086
        notice "Need to install:" $NEWPKG
        if [[ -z $INSTALL ]] ; then
            fix_missing "You can install missing packages" \
                    "$0 --install $ACTIVITY" \
                    "sudo $TOOL install $NEWPKG"
            MISSING_PACKAGES=y
        else
            # shellcheck disable=SC2086
            sudo $TOOL install $NEWPKG
            if [[ -z $NO_CHECK ]] ; then
                # shellcheck disable=SC2086
                FAILPKG=$(rpm -q $PKGLIST | awk '/is not installed$/ {print $2}')
                if [[ -n $FAILPKG ]] ; then
                    warn "Some packages didn't install: $FAILPKG"
                    WARNINGS=y
                else
                    save_installed "$ACTIVITY" "$NEWPKG"
                    pass "All required packages are now installed"
                    return 0
                fi
            fi
        fi
    fi
    return 1
}

#===============================================================================
# Run extra code based on distro, release, and activity
run_extra_code() {
    local DID=$1
    local DREL=$2
    local ACTIVITY=$3
    local CODE
    debug 1 "run_extra_code: DID=$DID DREL=$DREL ACTIVITY=$ACTIVITY"

    for KEY in $DID-${DREL}_$ACTIVITY ${DID}_$ACTIVITY $ACTIVITY $DID-$DREL $DID ; do
        CODE=${RUNCODE[${KEY:-no_code_key}]}
        if [[ -n $CODE ]] ; then
            debug 2 "  run exra setup code for $KEY -> eval $CODE"
            eval "$CODE $ACTIVITY"
            return 0
        fi
    done
}

#===============================================================================
# TEST: Are the correct packages installed?
try_packages() {
    local ID=$1; shift
    local RELEASE=$1; shift
    local ACTIVITY=$1; shift
    local PKGLIST
    PKGLIST=$(list_sort "$@")
    # shellcheck disable=SC2086,SC2116
    debug 1 "try_packages: ID=$ID RELEASE=$RELEASE ACTIVITY=$(echo $ACTIVITY) PKGLIST="$PKGLIST

    #-------------------------------------------------------------------------------
    if [[ $ID =~ Debian|Kubuntu|LinuxMint|Mint|Ubuntu|Xubuntu ]] ; then
        # shellcheck disable=SC2086
        debinstall "$ACTIVITY" $PKGLIST
        # shellcheck disable=SC2086
        for_each_activity "run_extra_code $ID $RELEASE" $ACTIVITY

    #-------------------------------------------------------------------------------
    elif [[ $ID =~ CentOS|Fedora|RHEL ]] ; then
        PKGMGR=yum
        [[ -e /bin/dnf || -e /usr/bin/dnf ]] && PKGMGR=dnf
        # shellcheck disable=SC2086
        rpminstall "$ACTIVITY" "$PKGMGR" $PKGLIST
        # shellcheck disable=SC2086
        for_each_activity "run_extra_code $ID $RELEASE" $ACTIVITY

    #-------------------------------------------------------------------------------
    elif [[ $ID =~ openSUSE|SLES ]] ; then
        # shellcheck disable=SC2086
        rpminstall "$ACTIVITY" zypper $PKGLIST
        # shellcheck disable=SC2086
        for_each_activity "run_extra_code $ID $RELEASE" $ACTIVITY

    #-------------------------------------------------------------------------------
    elif [[ $ID == "Arch" ]]  ; then
    # TODO: Add support for pacman here to provide similar functionality as apt-get code above
        warn "Currently there is no package support for Arch Linux"
        # shellcheck disable=SC2086
        for_each_activity "run_extra_code $ID $RELEASE" $ACTIVITY

    #-------------------------------------------------------------------------------
    elif [[ $ID == "Gentoo" ]]  ; then
    # TODO: Add support for emerge here to provide similar functionality as apt-get code above
        warn "Currently there is no package support for Gentoo"
        # shellcheck disable=SC2086
        for_each_activity "run_extra_code $ID $RELEASE" $ACTIVITY
    fi
}

#===============================================================================
# TEST: Are the correct packages installed?
rm_packages() {
    local ID=$1; shift
    local RELEASE=$1; shift
    local ACTIVITY=$1; shift
    local PKGLIST
    # shellcheck disable=2086
    PKGLIST=$(read_installed $ACTIVITY)
    # shellcheck disable=SC2116,SC2086
    debug 1 "rm_packages: ID=$ID RELEASE=$RELEASE ACTIVITY=$(echo $ACTIVITY) PKGLIST="$PKGLIST

    # shellcheck disable=SC2116,SC2086
    warn_wait "About to remove: $(echo $PKGLIST)\nShould I continue?" || return

    #-------------------------------------------------------------------------------
    if [[ $ID =~ Debian|Kubuntu|LinuxMint|Mint|Ubuntu|Xubuntu ]] ; then
        # shellcheck disable=SC2086
        $DRYRUN sudo dpkg --purge $PKGLIST

    #-------------------------------------------------------------------------------
    elif [[ $ID =~ CentOS|Fedora|RHEL ]] ; then
        PKGMGR=yum
        [[ -e /bin/dnf || -e /usr/bin/dnf ]] && PKGMGR=dnf
        # shellcheck disable=SC2086
        $DRYRUN sudo $PKGMGR remove $PKGLIST

    #-------------------------------------------------------------------------------
    elif [[ $ID =~ openSUSE|SLES ]] ; then
        # shellcheck disable=SC2086
        $DRYRUN sudo zypper remove $PKGLIST

    #-------------------------------------------------------------------------------
    elif [[ $ID == "Arch" ]]  ; then
    # TODO: Add support for pacman here to provide similar functionality as apt-get code above
        warn "Currently there is no package support for Arch Linux"

    #-------------------------------------------------------------------------------
    elif [[ $ID == "Gentoo" ]]  ; then
    # TODO: Add support for emerge here to provide similar functionality as apt-get code above
        warn "Currently there is no package support for Gentoo"
    fi

    clear_installed "$ACTIVITY"
}

#===============================================================================
if [[ -n $REMOVE ]] ; then
    rm_packages "$ID" "$RELEASE" "$COURSE"
    exit 0
fi


#===============================================================================
setup_meta() {
    local ACTIVITY=$1
    debug 1 "setup_meta: ACTIVITY=$ACTIVITY"

    local ATTR
    local ATTRS="ARCH BOGOMIPS CPUFLAGS CPUS PREFER_CPUS RAM DISK BOOT CONFIGS \
            INTERNET CARDREADER NATIVELINUX VMOKAY DISTROS DISTRO_BL DISTRO_ARCH \
            SYMLINKS VERSIONS EXTRAS VMS INPERSON VIRTUAL SELFPACED MOOC INCLUDES \
            INSTR_LED_CLASS SELFPACED_CLASS PREREQ OS OS_NEEDS"

    for ATTR in $ATTRS ; do
        eval "case \$$ATTR in
            [0-9]*) [[ \${$ATTR[$ACTIVITY]} -le \$$ATTR ]] || $ATTR=\"\${$ATTR[$ACTIVITY]}\" ;;
            *) [[ -z \${$ATTR[$ACTIVITY]} ]] || $ATTR=\"\${$ATTR[$ACTIVITY]}\" ;;
        esac
        debug 1 \"  $ATTR=\$$ATTR (\${$ATTR[$ACTIVITY]})\""
        if [[ $ATTR == DISTROS ]] ; then
            # shellcheck disable=SC2086
            DISTROS[$ACTIVITY]="$(fix_distro_alias ${DISTROS[$ACTIVITY]})"
        fi
    done
}

#===============================================================================
[[ -n $COURSE ]] || usage
debug 1 "main: Final classes: $COURSE"
# shellcheck disable=SC2086
for_each_activity setup_meta $COURSE

#===============================================================================
if [[ -n $CHECK_PKGS ]] ; then
    # shellcheck disable=SC2086
    debug 1 "Check Packages for "$COURSE
    PROGRESS=y
    # shellcheck disable=SC2086
    check_packages $COURSE
    exit 0
fi

#===============================================================================
if [[ -n $LIST_PKGS ]] ; then
    debug 1 "List Packages for $COURSE => $PKGS"
    # shellcheck disable=SC2086
    for_each_activity list_packages $COURSE | sort -k2
    exit 0
fi

#===============================================================================
# List information
list_entry() {
    local NAME=$1; shift
    [[ -z "$*" ]] || echo "    $NAME: $*"
}
list_array() {
    local NAME=$1; shift
    local WS=$1; shift
    local LIST=$*
    [[ -z $LIST ]] || echo "    $WS$NAME: $LIST"
}
#-------------------------------------------------------------------------------
# shellcheck disable=SC2086 
list_requirements() {
    local ACTIVITY=$*
    local A DISTS DIST
    [[ -n $ACTIVITY ]] && for_each_activity supported_activity "$ACTIVITY"
    # shellcheck disable=SC2086
    [[ -n $ACTIVITY ]] && ACTIVITIES="$ACTIVITY" || ACTIVITIES=$(list_sort ${!TITLE[*]})
    debug 1 "list_requirements: ACTIVITY=$ACTIVITY ACTIVITIES=$ACTIVITIES"
    echo 'Courses:'
    for A in $ACTIVITIES; do
        echo "  $C:"
        list_entry TITLE "${TITLE[$A]}"
        list_entry WEBPAGE "${WEBPAGE[$A]}"
        list_entry INPERSON "${INPERSON[$A]}"
        list_entry ONSITE "${ONSITE[$A]}"
        list_entry SELFPACED "${SELFPACED[$A]}"
        list_entry MOOC "${MOOC[$A]}"
        list_entry INSTR_LED_CLASS "${INSTR_LED_CLASS[$A]}"
        list_entry SELFPACED_CLASS "${SELFPACED_CLASS[$A]}"
        list_entry PREREQ "${PREREQ[$A]}"
        list_entry OS "$(value OS $A)"
        list_entry OS_NEEDS "$(value OS_NEEDS $A)"
        list_entry ARCH "$(value ARCH $A)"
        list_entry CPUFLAGS "$(value CPUFLAGS $A)"
        list_entry CPUS "$(value CPUS $A)"
        list_entry PREFER_CPUS "$(value PREFER_CPUS $A)"
        list_entry BOGOMIPS "$(value BOGOMIPS $A)"
        list_entry RAM "$(value RAM $A)"
        list_entry DISK "$(value DISK $A)"
        list_entry BOOT "$(value BOOT $A)"
        list_entry CONFIGS "$(value CONFIGS $A)"
        list_entry INTERNET "$(value INTERNET $A)"
        list_entry VMOKAY "$(value VMOKAY $A)"
        list_entry SYMLINKS "$(value SYMLINKS $A)"
        list_entry VERSIONS "$(value VERSIONS $A)"
        list_entry INCLUDES "$(value INCLUDES $A)"
        list_entry CARDREADER "$(value CARDREADER $A)"
        list_entry NATIVELINUX "$(value NATIVELINUX $A)"
        list_entry VMOKAY "$(value VMOKAY $A)"
        list_entry DISTRO_ARCH "$(value DISTRO_ARCH $A)"
        list_entry DISTRO_DEFAULT "$(value DISTRO_DEFAULT $A)"
        list_array DISTROS "" "$(value DISTROS $A)"
        # shellcheck disable=SC2086
        list_array DISTRO_BL "" "$(value DISTRO_BL $A)"
        if [[ -z $DIST_LIST ]] ; then
            DISTS=$(distrib_list)
        else
            DISTS=$DIST_LIST
        fi
        # shellcheck disable=SC2086
        debug 2 "list_requirements: DISTS="$DISTS
        if [[ -n $DISTS ]] ; then
            echo '    PACKAGES:'
            for DIST in $DISTS; do
                local P
                # shellcheck disable=SC2086
                P=$(package_list ${DIST/-/ } $A)
                debug 2 "$P"
                # shellcheck disable=SC2086
                list_array "$DIST" "  " $P
            done
        fi
    done
}

#===============================================================================
if [[ -n $LIST_REQS ]] ; then
    debug 1 "List Requirements for $COURSE"
    # shellcheck disable=SC2086
    list_requirements $COURSE
    exit 0
fi


#===============================================================================
# shellcheck disable=SC2086
for_each_activity check_activity $ORIG_COURSE

#===============================================================================
# Check all the things
divider
cache_output "$COURSE" check_all

#===============================================================================
# Check package list
divider
if [[ -n $INSTALL || -z $NOINSTALL ]] ; then
    check_sudo "$ID" "$RELEASE"
    check_repos "$ID" "$RELEASE" "$CODENAME" "$ARCH"
    # shellcheck disable=SC2086
    PKGLIST=$(for_each_activity "package_list $ID $RELEASE" $COURSE)
    # shellcheck disable=SC2086
    try_packages "$ID" "$RELEASE" "$COURSE" $PKGLIST
else
    notice "Not checking whether the appropriate packages are being installed"
fi


#===============================================================================
# Overall PASS/FAIL
divider
if [[ -n $FAILED ]] ; then
    warn "You will likely have troubles using this computer with this course. Ask your instructor."
elif [[ -n $WARNINGS ]] ; then
    warn "You may have troubles using this computer for this course unless you can fix the above warnings."
    if [[ -n $MISSING_PACKAGES ]] ; then
        warn "You also have some missing packages."
    fi
    warn "Ask your instructor on the day of the course."
else
    pass "You are ready for the course! W00t!"
fi


LFT="$HOME/LFT"

#===============================================================================
get_md5sum() {
    local ACTIVITY=$1 FILE=$2 TODIR=$3
    local DLOAD="$TODIR/$FILE"

    if [[ -f $DLOAD ]] ; then
        local DIR URL CACHED
	DIR=$(dirname "${FILE}")
	if [[ $DIR = '.' ]] ; then unset DIR ; fi
        URL="$ACTIVITY/${DIR+$DIR/}md5sums.txt"
        CACHED="$CMCACHE/$ACTIVITY-${DIR+$DIR-}md5sums.txt"

        get_file "$URL" > "$CACHED"
        if [[ -f $CACHED ]] ; then
            local MD5
            MD5=$(awk "/  $FILE$/ {print \$1}" "$CACHED")
	    if md5cmp "$DLOAD" "$MD5" ; then
                return 0
	    fi
	fi
    fi
    return 1
}

#===============================================================================
get_activity_tarball() {
    local ACTIVITY=$1
    local FILE=$2
    local TODIR=$3
    local PARTIAL=n
    debug 1 "get_activity_tarball: ACTIVITY=$ACTIVITY FILE=$FILE TODIR=$TODIR PARTIAL=$PARTIAL"

    if [[ -n $NONETWORK ]] ; then
        warn "get_activity_tarball: No network selected"
        return
    fi

    [[ -n $FILE ]] || return 0
    verbose "Get Activity File: $FILE"
    [[ -d $TODIR ]] || mkdir -p "$TODIR"
    get_md5sum 
    if [[ -f $TODIR/$FILE ]] ; then
        notice "Verifying $FILE..."
        if [[ -n $SIMULATE_FAILURE ]] || ! tar -t -f "$TODIR/$FILE" >/dev/null 2>&1 ; then
            warn_wait "Partial download of $TODIR/$FILE found." || return
            PARTIAL=y
        elif [[ -z $NOCACHE ]] && get_md5sum "$ACTIVITY" "$FILE" "$TODIR" ; then
            highlight "$FILE can be found in $TODIR (matches md5sum)"
            return 0
        fi
    else
        warn_wait "Download activity tarball? ($FILE)" || return
    fi
    highlight "Downloading $FILE to $TODIR"
    get_file "$ACTIVITY" "$FILE" "$TODIR" "$PARTIAL"
}

#===============================================================================
# Get extra files (in sub-directories called something like LFD460_V2.0.2)
get_activity_extras() {
    local ACTIVITY=$1
    local VER=$2
    local TODIR=$3
    debug 1 "get_activity_extras: ACTIVITY=$ACTIVITY VER=$VER TODIR=$TODIR"
    local EXTRA_FILES EXTRA_FILE

    if [[ -n $NONETWORK ]] ; then
        warn "get_activity_extras: No network selected"
        return
    fi

    EXTRA_FILES=$(sed -re "s/%COURSE_VERSION%/$VER/" <<<${EXTRAS[$ACTIVITY]})
    debug 2 "   get_activity_extras: EXTRA_FILES=$EXTRA_FILES"
    if [[ -n $EXTRA_FILES ]] ; then
        verbose "Extras Files: $EXTRA_FILES"
        #warn_wait "Download extra materials? ($EXTRA_FILES)" || return
        for EXTRA_FILE in $EXTRA_FILES ; do
            verbose "Consider extra $EXTRA_FILE"
            case $EXTRA_FILE in
                */) mkdir -p "$TODIR/$EXTRA_FILE"
                    local ALLFILES FILE FILES
                    ALLFILES=$(get_file "$ACTIVITY/$EXTRA_FILE" \
                            | awk -F\" '/<td>/ {print $8}')
                    debug 2 "  get_activity_extras: ALLFILES=$ALLFILES"
                    for FILE in $ALLFILES ; do
                        if try_file "$ACTIVITY/$EXTRA_FILE" "$FILE" "$TODIR/$EXTRA_FILE" ; then
                            debug 2 "  get_activity_extras: $EXTRA_FILE"
                            FILES+="$FILE "
                        fi
                    done
                    debug 2 "  Get files: $FILES"
                    if [[ -n $FILES ]] && warn_wait "Download extra materials? ($FILES)" ; then
                        for FILE in $FILES ; do
                            get_file "$ACTIVITY/$EXTRA_FILE" "$FILE" "$TODIR/$EXTRA_FILE"
                        done
                    fi
                    ;;
                *)  local DIR
                    DIR=$(dirname "$TODIR/$EXTRA_FILE")
                    mkdir -p "$DIR"
                    if try_file "$ACTIVITY" "$EXTRA_FILE" "$TODIR" ; then
                        if warn_wait "Download $EXTRA_FILE?" ; then
                            debug 2 "  get_activity_extras: $EXTRA_FILE"
                            get_file "$ACTIVITY" "$EXTRA_FILE" "$TODIR"
                        fi
                    fi ;;
            esac
        done
    fi
}

#===============================================================================
get_activity_files() {
    local ACTIVITY=$1
    local TODIR=${CMDIR:-$LFT}
    debug 1 "get_activity_files: ACTIVITY=$ACTIVITY TODIR=$TODIR"

    case "$ACTIVITY" in 
        LF[DS][12]*) return ;;
    esac

    if [[ -n $NONETWORK ]] ; then
        warn "get_activity_files: No network selected"
        return
    fi

    local FOUND SOLUTIONS VER RESOURCES VER2
    read -r SOLUTIONS VER <<< $(get_activity_file "$ACTIVITY" SOLUTIONS)
    read -r RESOURCES VER2 <<< $(get_activity_file "$ACTIVITY" RESOURCES)
    [[ -n $VER ]] || VER=$VER2
    [[ -n $VER ]] || VER=$(get_var VER "$ACTIVITY")
    debug 2 "   get_activity_files: VER=$VER SOLUTIONS=$SOLUTIONS RESOURCES=$RESOURCES"

    debug 2 "   get_activity_files: check SOLUTIONS=$SOLUTIONS"
    if [[ -n $SOLUTIONS ]] ; then
        FOUND=1
        verbose "Get solutions for $ACTIVITY"
        get_activity_tarball "$ACTIVITY" "$SOLUTIONS" "$TODIR"
        verbose "Check for $ACTIVITY errata..."
        get_file "$ACTIVITY" "${ACTIVITY}_${VER}_ERRATA.txt" "$TODIR"
    fi
    debug 2 "   get_activity_files: FOUND=$FOUND"
    debug 2 "   get_activity_files: check RESOURCES=$RESOURCES"
    if [[ -n $RESOURCES ]] ; then
        FOUND=1
        verbose "Get resources for $ACTIVITY"
        get_activity_tarball "$ACTIVITY" "$RESOURCES" "$TODIR"
    fi
    debug 2 "   get_activity_files: FOUND=$FOUND"
    if [[ -z $FOUND ]] ; then
        notice "No activity files for $ACTIVITY"
    fi
    [[ -n $NOEXTRAS ]] || get_activity_extras "$ACTIVITY" "$VER" "$TODIR"
}

#===============================================================================
get_all_activity_files() {
    debug 1 "get_all_activity_files: $*"

    if [[ -n $NONETWORK ]] ; then
        warn "get_all_activity_files: No network selected"
        return
    fi

    local ACTIVITY CMS CM ACTIVITIES
    for ACTIVITY in "$@"; do
        case "$ACTIVITY" in 
            LF[DS][12]*) continue ;;
        esac

        if CM=$(get_var CM "$ACTIVITY") && [[ -n $CM ]] ; then
            CMS+="$CM "
        elif ACTIVITIES=$(get_var COURSES "$ACTIVITY") && [[ -n $ACTIVITIES ]] ; then
            CMS+="$ACTIVITIES "
        else
            CMS+="$ACTIVITY "
        fi
    done
    debug 1 "Install activity files for: $* as $CMS"
    # shellcheck disable=SC2086
    for_each_activity get_activity_files $CMS
}

#===============================================================================
if [[ -z $NOCM ]] ; then
    divider
    # shellcheck disable=SC2086
    get_all_activity_files $ORIG_COURSE
fi


#===============================================================================
# Get Suggested VM for class
get_virtual_machine() {
    [[ -n $VMS ]] || return 
    debug 1 "get_virtual_machine: VMS=$VMS"
    declare LIST
    read -r -a LIST <<< "$VMS"

    ask "Which VM would you like to download? [None|$(sed -e 's/ /|/g' <<< $VMS)]"
    local VM
    read VM
    case $VM in
        0|n*|N*) return;;
        [1-9]*) VM=$((VM - 1)); VM="${LIST[$VM]}";;
        *) VM="${LIST[0]}";;
    esac
    local FILE="$VM.tar.gz"
    notice "Downloading: $FILE"
    get_file "$VMURL" "$FILE" "$LFT"
}

#===============================================================================
if [[ -z $NOVM ]] ; then
    divider
    # shellcheck disable=SC2086
    get_virtual_machine
fi

clean_cache

exit 0

