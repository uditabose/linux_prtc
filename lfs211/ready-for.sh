#!/bin/bash
#
# Setup development system for Linux Foundation courses
#
# Copyright (c) 2013 Chris Simmonds
#               2013-2016 Behan Webster
#               2014-2016 Jan-Simon Möller
#
# Licensed under GPL
#
# Originally conceived by Chris Simmonds for LF315
# Massive rewrite and updates by Behan Webster (Maintainer)
# Further updates by Jan-Simon Möller
#
# Version 6.8: 2016-10-12
#     - Update requirements for LFD415
#===============================================================================
VERSION=6.8

#===============================================================================
#
# You can define requirements for a particular course by defining the following
# variables where LFXXXX is your course number:
#
#   DESCRIPTION[LFXXXX]=""      # Name of the course
#   WEBPAGE[LFXXXX]="http://..."# LF URL for course
#   ARCH[LFXXXX]=x86_64         # Required CPU arch (optional)
#   CPUFLAGS[LFXXXX]="vmx aes"  # Required CPU flags (optional)
#   CPUS[LFXXXX]=2              # How many CPUS/cores are required
#   PREFER_CPUS[LFXXXX]=4       # How many CPUS would be preferred
#   BOGOMIPS[LFXXXX]=4000       # How many cululative BogoMIPS you need
#   RAM[LFXXXX]=2               # How many GiB of RAM you need
#   DISK[LFXXXX]=30             # How many GiB of Disk you need free in $HOME
#   BOOT[LFXXXX]=30             # How many MiB of Disk you need free in /boot
#   CONFIGS[LFXXXX]="KSM"       # Which CONFIG_* kernel variables are required (optional)
#   DISTRO_ARCH[LFXXXX]=x86_64  # Required Linux distro arch (optional)
#   INTERNET[LFXXXX]=y          # Is internet access required? (optional)
#   CARDREADER[LFXXXX]=Required # Is a card reader or USB mass storage device required? (optional)
#   NATIVELINUX[LFXXXX]=Required# Is Native Liunux required for this course? (optional)
#   VMOKAY[LFXXXX]=Okay         # Can this course be done on a VM? (optional)
#   SYMLINKS[LFXXXX]="/bin/sh:!dash /usr/bin/python:!^/opt/"
#                               # Symlink patterns you want to satisfy
#   VERSIONS[LFXXXX]="bash:>4 gcc:=5 python:<3"
#                               # --versions you want to check
#   EXTRAS[LFXXXX]="LFD460_%COURSE_VERSION%/"
#                               # Download extra things from course materials
#   RUNCODE[LFXXXX]=lfXXX_func  # Run this bash function after install (optional)
#   DISTROS[LFXXXX]="Fedora-21+ CentOS-6+ Ubuntu-12.04+"
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
#   PACKAGES[Ubuntu-LFS550]="build-dep_wireshark"
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
# If you want to see extra debug output, set DEBUG=1
#
#    DEBUG=1 ./ready-for.sh LFD450
# or
#    ./ready-for.sh --debug LFD450
#

#===============================================================================
RED="\e[0;31m"
GREEN="\e[0;32m"
YELLOW="\e[0;33m"
CYAN="\e[0;36m"
BLUE="\e[0;34m"
BACK="\e[0m"
#-------------------------------------------------------------------------------
pass() {
    [[ -n $NO_PASS ]] || echo -e "${GREEN}PASS${BACK}: $*"
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
warn_wait() {
    warn -n "$*\n    Continue? [Yn] " >&2
    read ANS
    case $ANS in
        Y*|y*|1*) return 0 ;;
        *) [[ -z $ANS ]] || return 1 ;;
    esac
    return 0
}
ask() {
    echo -ne "${YELLOW}WARN${BACK}: $* " >&2
}
#-------------------------------------------------------------------------------
verbose() {
    [[ -z "$VERBOSE" ]] || echo -e "INFO:" "$@" >&2
}
#-------------------------------------------------------------------------------
progress() {
    [[ -z $PROGRESS ]] || echo -en "$1" >&2
}
#-------------------------------------------------------------------------------
fail() {
    echo -e "${RED}FAIL${BACK}:" "$@" >&2
}
#-------------------------------------------------------------------------------
highlight() {
    echo -e "${YELLOW}$*${BACK}" >&2
}
#-------------------------------------------------------------------------------
dothis() {
    echo -e "${BLUE}$*${BACK}"
}
#-------------------------------------------------------------------------------
bare_debug() {
    [[ -z "$DEBUG" ]] || echo "$@" >&2
}
debug() {
    local OPT
    if [[ $1 == -* ]] ; then
        OPT=$1; shift
    fi
    # shellcheck disable=SC2086
    bare_debug $OPT "D:" "$@"
}
#-------------------------------------------------------------------------------
bug() {
    local MSG=$1 CODE=$2
    warn "Hmm... That's not right...\n    $MSG\n    Probably a bug. Please send the output of the following to behanw@converseincode.com\n      $CODE"
}
#-------------------------------------------------------------------------------
export MYPID=$$
error() {
    echo E: "$@" >&2
    set -e
    kill -TERM $MYPID 2>/dev/null
}

#===============================================================================
# Check that we're running on Linux
if [[ $(uname -s) != Linux || -n "$SIMULATE_FAILURE" ]] ; then
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
# Allow info to be gathered in order to fix distro detection problems
gather() {
    local FILE
    FILE=$(which "$1" 2>/dev/null || echo "$1")
    shift
    if [[ -n "$FILE" ]] && [[ -e "$FILE" ]] ; then
        echo "--- $FILE ---------------------------------------------"
        if [[ -x $FILE ]] ; then
            "$FILE" "$@"
        else
            cat "$FILE"
        fi
    fi
}
gather_info() {
    echo "----------------------------------------------------------------------"
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
    echo "----------------------------------------------------------------------"
    exit 0
}

#===============================================================================
CMDNAME=${CMDNAME:-$0}
CMDBASE=$(basename "$CMDNAME")
usage() {
    COURSE=${COURSE# }
    echo "Usage: $CMDBASE <course>"
    echo "       $CMDBASE [options]"
    echo "    --distro               List current Linux distro"
    echo "    --install              Install missing packages for the course"
    echo "    --list                 List all supported courses"
    echo "    --no-course-materials  Don't install course materials"
    echo "    --no-extras            Don't download extra materials"
    echo "    --no-install           Don't check installed packages"
    echo "    --no-recommends        Don't install recommended packages"
    echo "    --update               Update to latest version of this script"
    echo "    --verify               Verify script MD5sum"
    echo "    --version              List script version"
    echo "    --verbose              Turn on extra messages"
    echo
    echo "Example: $CMDBASE --install ${COURSE:-LFD450}"
    exit 0
}

#===============================================================================
# Command option parsing
CMDOPTS="$*"
while [[ $# -gt 0 ]] ; do
    case "$1" in
        -AD|-ALFD|--all-lfd) ALL_LFD=y ;;
        -AS|-ALFS|--all-lfs) ALL_LFS=y ;;
        -A|--all|--all-courses) ALL_COURSES=y ;;
        --check-packages) CHECK_PKGS=y; PROGRESS=y ;;
        --curl) USECURL=y ;;
        --debug) DEBUG=y; VERBOSE=y ;;
        --distro) LIST_DISTRO=y ;;
        --detect-vm) DETECT_VM=y ;;
        -i|--install) INSTALL=y ;;
        --force-update) FORCEUPDATE=y ;;
        --gather-info) gather_info ;;
        --json) JSON=y ;;
        -l|--list) LIST_COURSES=y; break ;;
        -P|--list-packages) LIST_PKGS=y ;;
        -L|--list-requirements) LIST_REQS=y ;;
        -C|--no-course-materials) NOCM=y ;;
        -E|--no-extras) NOEXTRAS=y ;;
        -I|--no-install) NOINSTALL=y ;;
        -R|--no-recommends) NORECOMMENDS=y ;;
        -D|--override-distro) DISTRO=$2; shift ;;
        -p|--packages) LIST_PKGS=y; PKGS="${PKGS# } $2"; shift ;;
        --progress) PROGRESS=y ;;
        --simulate-failure) SIMULATE_FAILURE=y ;;
        --test) TEST=y ;;
        --trace) set -x ;;
        --try-all-courses) TRY_ALL_COURSES=y ;;
        --update-beta) UPDATE=beta; VERBOSE=y ;;
        --update) UPDATE=y; VERBOSE=y ;;
        --verify) VERIFY=y ;;
        -v|--verbose) VERBOSE=y ;;
        -V|--version) echo $VERSION; exit 0 ;;
        LFD*|LFS*) COURSE="${COURSE# } $1" ;;
        [0-9][0-9][0-9]) COURSE="${COURSE# } LFD$1" ;;
        -h*|--help*|*) usage ;;
    esac
    shift
done
PKGS="${PKGS# }"
debug "main: Command Line Parameters: CMD=$CMDNAME => $CMDOPTS ($PKGS)"

#===============================================================================
# URLS
LFURL="https://training.linuxfoundation.org"
LFCM="$LFURL/cm"
LFDTRAINING="$LFURL/linux-courses/development-training"
LFSTRAINING="$LFURL/linux-courses/system-administration-training"

EPELURL="http://download.fedoraproject.org/pub/epel"

#===============================================================================
# Just in case we're behind a proxy server (the system will add settings to /etc/environment)
[[ -f /etc/environment ]] && . /etc/environment
export all_proxy http_proxy https_proxy ftp_proxy

#===============================================================================
# Download file (try wget, then curl, then perl)
get() {
    local URL=$1 WGET_OPTS=$2 CURL_OPTS=$3
    if [[ -z $USECURL ]] && which wget >/dev/null ; then
        debug "  wget $URL"
        # shellcheck disable=SC2086
        wget --quiet --no-cache --timeout=8 $WGET_OPTS "$URL" -O- 2>/dev/null || return 1
    elif which curl >/dev/null ; then
        debug "  curl $URL"
        # shellcheck disable=SC2086
        curl --connect-timeout 8 --location $CURL_OPTS "$URL" 2>/dev/null || return 1
    elif which perl >/dev/null ; then
        debug "  perl LWP::Simple $URL"
        perl -MLWP::Simple -e "getprint '$URL'" 2>/dev/null || return 1
    else
        warn "No download tool found." >&2
        return 1
    fi
    return 0
}

#===============================================================================
# See if version is less than the other
version_greater_equal() {
    local i LEN VER1 VER2
    IFS=. read -r -a VER1 <<< "$1"
    IFS=. read -r -a VER2 <<< "$2"
    # shellcheck disable=SC2145
    debug "version_greater_equal: $1(${#VER1[*]})[${VER1[@]}] $2(${#VER2[*]})[${VER2[@]}]"
    LEN=$( (( ${#VER1[*]} > ${#VER2[*]} )) && echo ${#VER1[*]} || echo ${#VER2[*]})
    for ((i=0; i<LEN; i++)) ; do
        VER1[i]=${VER1[i]#0}; VER1[i]=${VER1[i]:-0}
        VER2[i]=${VER2[i]#0}; VER2[i]=${VER2[i]:-0}
        debug "  version_greater_equal: Compare ${VER1[i]} and ${VER2[i]}"
        (( ${VER1[i]:-0} > ${VER2[i]:-0} )) && return 0
        (( ${VER1[i]:-0} < ${VER2[i]:-0} )) && return 1
    done
    return 0
}
version_ge_test() {
    version_greater_equal "$1" "$2"
    local RET=$?
    debug "version_ge_test: $RET $3"
    if [[ $RET == "$3" ]] ; then
        pass "$1 >= $2 => $3"
    else
        fail "$1 >= $2 != $3"
    fi
}
testcases() {
    version_ge_test 0 1 1
    version_ge_test 1.0 2 1
    version_ge_test 1 2.0 1
    version_ge_test 1.9 2.8 1
    version_ge_test 2.8 2.9 1
    version_ge_test 2.9 2.8 0
    version_ge_test 2.8 2.8 0
    version_ge_test 2 1 0
    version_ge_test 6 16.04 1
    version_ge_test 16.04 6 0
    version_ge_test 16.04 16.04 0
    version_ge_test 16.04 15.10 0
    version_ge_test 14.04 15.10 1
    version_ge_test 1 1.2.3 1
    version_ge_test 2 1.2.3 0
    version_ge_test 1 1.2.3.4 1
    version_ge_test 2 1.2.3.4 0
    version_ge_test 1.2.3 1 0
    version_ge_test 1.2.3 2 1
    version_ge_test 1.2.3.4 1 0
    version_ge_test 1.2.3.4 2 1
    version_ge_test 1.2.3 1.2.3.4 1
    version_ge_test 1.2.3.4 1.2.3 0

    exit 0
}
[[ -z $TEST ]] || testcases

#===============================================================================
# See if version is less than the other
md5cmp() {
    local FILE=$1 MD5=$2
    debug "md5cmp FILE=$FILE MD5=$MD5"
    [[ $MD5 = $(md5sum "$FILE" | awk '{print $1}') ]] || return 1
    return 0
}

#===============================================================================
# Check for updates
check_version() {
    local URL="$LFCM/prep/$CMDBASE"
    local META="$LFCM/prep/ready-for.meta"
    local NEW="${TMPDIR:-/tmp}/ready-for.$$"

    verbose "Checking for updated script"
    [[ -z $DONTUPDATE ]] || return

    #---------------------------------------------------------------------------
    # Beta update
    if [[ $UPDATE == "beta" ]] ; then
        if get "$URL-beta" >"$NEW" ; then
            mv "$NEW" "$0"
            chmod 755 "$0"
            warn "Now running beta version of this script"
        else
            rm -f "$NEW"
            warn "No beta version of this script found"
        fi
        exit 0
    fi

    #---------------------------------------------------------------------------
    # Verify meta data
    local VER MD5 OTHER
    read -r VER MD5 OTHER <<< $(get "$META")
    if [[ -n $VERIFY && -n $MD5 ]] ; then
        if md5cmp "$CMDNAME" "$MD5" ; then
            pass "md5sum matches"
        elif md5cmp "$CMDNAME" "$OTHER" ; then
            MD5=$OTHER
            pass "md5sum matches"
        else
            fail "md5sum failed (you might want to run a --force-update to re-download)"
        fi
        exit 0
    elif [[ -z $VER ]] ; then
        return
    fi

    #---------------------------------------------------------------------------
    # Get update for script
    INTERNET_AVAILABLE=y
    debug "  check_version: ver:$VERSION VER:$VER MD5:$MD5"
    [[ -n $FORCEUPDATE ]] && UPDATE=y
    if [[ -n $FORCEUPDATE ]] || ( ! md5cmp "$CMDNAME" "$MD5" && ! version_greater_equal "$VERSION" "$VER" ) ; then
        if [[ -n $UPDATE ]] ; then
            get "$URL" >"$NEW" || (rm -f "$NEW"; return)
            notice "A new version of this script was found. Upgrading..."
            mv "$NEW" "$CMDNAME"
            chmod 755 "$CMDNAME"
            # shellcheck disable=SC2086
            [[ -n $COURSE ]] && DONTUPDATE=1 eval bash "$CMDNAME" $CMDOPTS
        else
            notice "A new version of this script was found. (use \"$CMDNAME --update\" to download)"
        fi
    else
        verbose "No update found"
    fi
    [[ -n $UPDATE && -z $COURSE ]] && exit 0
}
check_version

#===============================================================================
# Make associative arrays
declare -A ARCH BOGOMIPS BOOT CONFIGS CPUFLAGS CPUS COURSE_ALIASES DEBREL \
    DESCRIPTION WEBPAGE DISK DISTROS DISTS DISTRO_ARCH DISTRO_BL FALLBACK \
    INTERNET CARDREADER NATIVELINUX PACKAGES PREFER_CPUS SYMLINKS RAM \
    COPYPACKAGES RECOMMENDS RUNCODE VERSIONS VMOKAY EXTRAS

#===============================================================================
#=== Start of Course Definitions ===============================================
#===============================================================================

#===============================================================================
# If we can't find settings/packages for a distro fallback to the next one
FALLBACK=(
    [CentOS]="RHEL"
    [CentOS-6]="RHEL-6"
    [CentOS-7]="RHEL-7"
    [Debian]="Ubuntu"
    [Debian-7]="Ubuntu-12.04"
    [Debian-8]="Debian-7 Ubuntu-14.04"
    [Debian-9]="Debian-8 Ubuntu-16.04"
    [Debian-999]="Debian-9 Debian-8 Ubuntu-16.04"
    [Fedora]="RHEL CentOS"
    [Fedora-19]="Fedora"
    [Fedora-20]="Fedora Fedora-19"
    [Fedora-21]="Fedora Fedora-20"
    [Fedora-22]="Fedora Fedora-21"
    [Fedora-23]="Fedora Fedora-22"
    [Fedora-24]="Fedora Fedora-23"
    [LinuxMint]="Ubuntu"
    [LinuxMint-17]="Ubuntu-14.04 Debian-8"
    [LinuxMint-17.1]="LinuxMint-17 Ubuntu-14.04 Debian-8"
    [LinuxMint-17.2]="LinuxMint-17.1 LinuxMint-17 Ubuntu-14.04 Debian-8"
    [LinuxMint-18]="Ubuntu-16.04 Ubuntu-14.04 Debian-8"
    [Mint]="LinuxMint Ubuntu"
    [RHEL]="CentOS"
    [RHEL-6]="CentOS-6"
    [RHEL-7]="CentOS-7"
    [openSUSE-13.2]="openSuse-13.1"
    [openSUSE-999]="openSuse-13.2"
    [SLES]="openSUSE"
    [SUSE]="openSUSE"
    [Suse]="openSUSE"
    [Ubuntu]="Debian"
    [Ubuntu-12.04]="Debian-7"
    [Ubuntu-14.04]="Debian-8"
    [Ubuntu-15.10]="Ubuntu-14.04"
    [Ubuntu-16.04]="Ubuntu-15.10 Ubuntu-14.04"
    [Kubuntu]="Ubuntu"
    [XUbuntu]="Ubuntu"
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
    [stable]=8
    [testing]=9
    [sid]=999
    [unstable]=999
)

#===============================================================================
# Some classes have the same requirements as other classes
COURSE_ALIASES=(
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
    [LFS102]=LFS300
    [LFS220]=LFS301
    [LFS230]=LFS311
    [LFS520]=LFS452
    [LFS540]=LFS462
    [LFS541]=LFS462
    [LFS550]=LFS465
    [LFS551]=LFS465
)

#===============================================================================
# Default Requirements for all courses
#===============================================================================
#ARCH=x86_64
#CPUFLAGS=
CPUS=1
PREFER_CPUS=2
BOGOMIPS=2000
RAM=1
DISK=5
#BOOT=128
#CONFIGS=
#DISTRO_ARCH=x86_64
#INTERNET=y
#CARDREADER=y
#NATIVELINUX=y
VMOKAY=Acceptable
#DISTROS="Arch-2012+ Gentoo-2+"
DISTROS="CentOS-6+ Debian-7+ Fedora-21+ LinuxMint-17+ openSUSE-13.1+ RHEL-6+ Ubuntu-14.04 Ubuntu-15.10+"
DISTRO_BL="Ubuntu-12.10 Ubuntu-13.04 Ubuntu-13.10 Ubuntu-14.10 Ubuntu-15.04"
PACKAGES=
COPYPACKAGES=
RECOMMENDS=
#===============================================================================
# Create empty Package lists for all distros above
#===============================================================================
PACKAGES[CentOS]=
PACKAGES[CentOS-6]=
PACKAGES[CentOS-7]=
#-------------------------------------------------------------------------------
PACKAGES[Debian]=
PACKAGES[Debian-7]=
PACKAGES[Debian-8]=
#-------------------------------------------------------------------------------
PACKAGES[Fedora]=
PACKAGES[Fedora-21]=
PACKAGES[Fedora-22]=
PACKAGES[Fedora-23]=
PACKAGES[Fedora-24]=
#-------------------------------------------------------------------------------
PACKAGES[LinuxMint]=
PACKAGES[LinuxMint-17]=
PACKAGES[LinuxMint-17.1]=
PACKAGES[LinuxMint-17.2]=
PACKAGES[LinuxMint-18]=
#-------------------------------------------------------------------------------
PACKAGES[openSUSE]=
PACKAGES[openSUSE-13.1]=
PACKAGES[openSUSE-13.2]=
#-------------------------------------------------------------------------------
PACKAGES[RHEL]=
PACKAGES[RHEL-6]=
PACKAGES[RHEL-7]=
#-------------------------------------------------------------------------------
PACKAGES[Ubuntu]=
PACKAGES[Ubuntu-12.04]=
PACKAGES[Ubuntu-14.04]=
PACKAGES[Ubuntu-15.10]=
PACKAGES[Ubuntu-16.04]=
#-------------------------------------------------------------------------------
# Add more default package lists here for other distros
#===============================================================================

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
PACKAGES[Ubuntu-15.10_@build]="[Debian-8_@build]"
#-------------------------------------------------------------------------------
PACKAGES[RHEL_@build]="gcc gcc-c++ glibc-devel"
#-------------------------------------------------------------------------------
PACKAGES[openSUSE_@build]="[RHEL_@build] -texinfo"

#===============================================================================
# Common packages used in various courses
#===============================================================================
PACKAGES[@common]="curl dos2unix gawk git screen sudo tree unzip wget"
RECOMMENDS[@common]="emacs gnome-tweak-tool gparted mc zip"
#-------------------------------------------------------------------------------
PACKAGES[Ubuntu_@common]="diffuse gnupg gnupg2 htop tofrodos unp vim"
#-------------------------------------------------------------------------------
PACKAGES[openSUSE_@common]="gpg2 vim"
RECOMMENDS[openSUSE_@common]="mlocate gnome-tweak-tool"
RECOMMENDS[openSUSE-999_@common]="net-tools-deprecated"
#-------------------------------------------------------------------------------
PACKAGES[RHEL_@common]="gnupg2 vim-enhanced"
RECOMMENDS[RHEL-6_@common]="-gnome-tweak-tool"
PACKAGES[RHEL-7_@common]="NetworkManager-tui"
PACKAGES[Fedora_@common]="[RHEL-7_@common]"
RECOMMENDS[Fedora_@common]="[RHEL_@common] diffuse"

#===============================================================================
# Embedded packages
#===============================================================================
PACKAGES[@embedded]="lzop screen"
RECOMMENDS[@embedded]="minicom"
#-------------------------------------------------------------------------------
PACKAGES[CentOS_@embedded]="dnsmasq dtc glibc-static nfs-utils"
RECOMMENDS[CentOS_@embedded]="uboot-tools"
PACKAGES[CentOS-7_@embedded]="-dtc"
RECOMMENDS[CentOS-7_@embedded]="-uboot-tools"
#-------------------------------------------------------------------------------
PACKAGES[openSUSE_@embedded]="dtc nfs-kernel-server"
RECOMMENDS[openSUSE_@embedded]="u-boot-tools"
#-------------------------------------------------------------------------------
PACKAGES[Ubuntu_@embedded]="device-tree-compiler dnsmasq-base dosfstools eject
	gperf mtd-utils nfs-kernel-server parted"
RECOMMENDS[Ubuntu_@embedded]="u-boot-tools"

#===============================================================================
# Kernel related packages
#===============================================================================
PACKAGES[@kernel]="crash cscope gitk kexec-tools sysfsutils indent"
#-------------------------------------------------------------------------------
PACKAGES[Debian_@kernel]="exuberant-ctags kdump-tools libfuse-dev libssl-dev
	manpages-dev nfs-common"
RECOMMENDS[Debian_@kernel]="libglade2-dev libgtk2.0-dev qt4-default sparse
	stress symlinks"
PACKAGES[Ubuntu_@kernel]="[Debian_@kernel] hugepages libhugetlbfs-dev linux-crashdump"
PACKAGES[Ubuntu-12.04_@kernel]="libncurses5-dev -qt4-default"
PACKAGES[Ubuntu-14.04_@kernel]="liblzo2-dev"
PACKAGES[Ubuntu-15.10_@kernel]="[Ubuntu-14.04_@kernel]"
RECOMMENDS[Ubuntu-15.10_@kernel]="qt4-dev-tools"
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
PACKAGES[openSUSE_@kernel]="ctags fuse-devel kdump kernel-devel lzo-devel
	libhugetlbfs ncurses-devel yast2-kdump"
RECOMMENDS[openSUSE_@kernel]="gtk2-devel libglade2-devel slang-devel sparse"
PACKAGES[openSUSE-999_@kernel]="libhugetlbfs-devel"

#===============================================================================
# Sysadm related packages
#===============================================================================
PACKAGES[@sysadm]="bonnie++ collectl dstat gnuplot libtool mdadm m4 memtest86+ sysstat"
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
PACKAGES[openSUSE_@trace]="kernelshark"

#===============================================================================
# Virt related packages
#===============================================================================
PACKAGES[@virt]="qemu-kvm virt-manager"
PACKAGES[Debian_@virt]="libvirt-daemon-system libvirt-clients"
PACKAGES[Ubuntu_@virt]="libvirt-bin"
PACKAGES[RHEL_@virt]="libvirt"
PACKAGES[openSUSE_@virt]="[RHEL_@virt] libvirt-client libvirt-daemon"
PACKAGES[openSUSE-13.1_@virt]="-qemu-kvm"

#===============================================================================
# Extra requirements for LFD301
#===============================================================================
DESCRIPTION[LFD301]="Introduction to Linux for Developers and GIT"
WEBPAGE[LFD301]="$LFDTRAINING/introduction-to-linux-for-developers"
INTERNET[LFD301]=y
#-------------------------------------------------------------------------------
PACKAGES[LFD301]="@build @common @trace cvs gparted lvm2 subversion sysstat tcpdump wireshark"
RECOMMENDS[LFD301]="iptraf-ng gnome-system-monitor ksysguard yelp"
PACKAGES[Debian_LFD301]="git-cvs git-daemon-sysvinit git-gui git-svn gitk gitweb
	libcurl4-openssl-dev libexpat1-dev libssl-dev"
RECOMMENDS[Debian_LFD301]="default-jdk stress"
RECOMMENDS[Ubuntu-12.04_LFD301]="-iptraf-ng iptraf"
PACKAGES[RHEL_LFD301]="git-all expat-devel openssl-devel"
RECOMMENDS[RHEL-6_LFD301]="-iptraf-ng iptraf kdebase -ksysguard ksysguardd"
PACKAGES[Fedora_LFD301]="[RHEL_LFD301]"
RECOMMENDS[Fedora_LFD301]="[RHEL_LFD301] stress"
RECOMMENDS[openSUSE_LFD301]="kdebase4-workspace -ksysguard"

#===============================================================================
# Extra requirements for LFD401
#===============================================================================
DESCRIPTION[LFD401]="Developing Applications for Linux"
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
DESCRIPTION[LFD415]="Inside Android: An Intro to Android Internals"
WEBPAGE[LFD415]="$LFDTRAINING/inside-android-an-intro-to-android-internals"
ARCH[LFD415]=x86_64
CPUS[LFD415]=4
PREFER_CPUS[LFD415]=8
BOGOMIPS[LFD415]=10000
RAM[LFD415]=8
DISK[LFD415]=150
DISTRO_ARCH[LFD415]=x86_64
INTERNET[LFD415]=Required
CARDREADER[LFD415]=Required
NATIVELINUX[LFD415]="highly recommended"
VMOKAY[LFD415]="highly discouraged"
DISTROS[LFD415]="Ubuntu:amd64-14.04 Ubuntu:amd64-16.04"
RUNCODE[LFD415-12.04]=lfd415_1204_extra
#===============================================================================
PACKAGES[LFD415]="@build @common @embedded vinagre"
#-------------------------------------------------------------------------------
PACKAGES[Ubuntu_LFD415]="gcc-multilib g++-multilib lib32ncurses5-dev lib32z1-dev
	libc6-dev-i386 libgl1-mesa-dev libx11-dev libxml2-utils python-markdown
	x11proto-core-dev xsltproc zlib1g-dev"
PACKAGES[Ubuntu-12.04_LFD415]="libgl1-mesa-glx:i386 libncurses5-dev:i386
	libreadline6-dev:i386 libx11-dev:i386 mingw32 zlib1g-dev:i386"
PACKAGES[Ubuntu-14.04_LFD415]="mingw32"
PACKAGES[Ubuntu-15.10_LFD415]="openjdk-8-jdk"
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
    local CLASS=$1

    verbose "Running ldf415_extra for $CLASS"
    GLSO=/usr/lib/i386-linux-gnu/libGL.so
    GLSOVER=/usr/lib/i386-linux-gnu/mesa/libGL.so.1
    if [[ -e $GLSOVER && ! -e $GLSO || -n "$SIMULATE_FAILURE" ]] ; then
        if [[ -z "$INSTALL" ]] ; then
            warn "Need to add missing symlink for libGL.so"
            fix_missing "You can do so" \
                "$0 --install $CLASS" \
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
DESCRIPTION[LFD420]="Linux Kernel Internals and Debugging"
WEBPAGE[LFD420]="$LFDTRAINING/linux-kernel-internals-and-debugging"
BOOT[LFD420]=128	# Room for 2 more kernels
#-------------------------------------------------------------------------------
PACKAGES[LFD420]="@build @common @kernel @trace"
DISK[LFD420]=10

#===============================================================================
# Extra requirements for LFD430
#===============================================================================
DESCRIPTION[LFD430]="Developing Linux Device Drivers"
WEBPAGE[LFD430]="$LFDTRAINING/developing-linux-device-drivers"
BOOT[LFD430]=128	# Room for 2 more kernels
DISK[LFD430]=10
#-------------------------------------------------------------------------------
COPYPACKAGES[LFD430]="LFD420"

#===============================================================================
# Extra requirements for LFD432
#===============================================================================
DESCRIPTION[LFD432]="Optimizing Device Drivers for Power Efficiency"
WEBPAGE[LFD432]="$LFDTRAINING/optimizing-linux-device-drivers-for-power-efficiency"
#-------------------------------------------------------------------------------
PACKAGES[LFD432]="@build @common @kernel @trace gkrellm"
PACKAGES[Ubuntu_LFD432]="lm-sensors xsensors"
PACKAGES[Debian_LFD432]="[Ubuntu_LFD432]"
PACKAGES[LinuxMint_LFD432]="[Ubuntu_LFD432]"
PACKAGES[openSUSE_LFD432]="sensors"
PACKAGES[RHEL_LFD432]="xsensors"
PACKAGES[Fedora_LFD432]="[RHEL_LFD432]"

#===============================================================================
# Extra requirements for LFD435
#===============================================================================
DESCRIPTION[LFD435]="Embedded Linux Device Drivers"
WEBPAGE[LFD435]="$LFDTRAINING/developing-linux-device-drivers"
BOOT[LFD435]=128	# Room for 2 more kernels
DISK[LFD435]=40
#-------------------------------------------------------------------------------
PACKAGES[LFD435]="[LFD420] @embedded"

#===============================================================================
# Extra requirements for LFD440
#===============================================================================
DESCRIPTION[LFD440]="Linux Kernel Debugging and Security"
#WEBPAGE[LFD440]="$LFDTRAINING/developing-linux-device-drivers"
BOOT[LFD440]=128	# Room for 2 more kernels
DISK[LFD440]=10
#-------------------------------------------------------------------------------
COPYPACKAGES[LFD440]="LFD420"

#===============================================================================
# Extra requirements for LFD450
#===============================================================================
DESCRIPTION[LFD450]="Embedded Linux Development"
WEBPAGE[LFD450]="$LFDTRAINING/embedded-linux-development"
CPUS[LFD450]=2
PREFER_CPUS[LFD450]=4
BOGOMIPS[LFD450]=3000
RAM[LFD450]=2
DISK[LFD450]=30
INTERNET[LFD450]=Required
CARDREADER[LFD450]=Required
NATIVELINUX[LFD450]="highly recommended"
VMOKAY[LFD450]="highly discouraged"
#-------------------------------------------------------------------------------
PACKAGES[LFD450]="@build @common @embedded @kernel @trace help2man"
PACKAGES[Ubuntu_LFD450]="libtool squashfs-tools"
RECOMMENDS[Ubuntu_LFD450]="libpython-dev"
PACKAGES[Ubuntu-12.04_LFD450]="-libpython-dev"
PACKAGES[Ubuntu-14.04_LFD450]="libtool"
PACKAGES[Ubuntu-15.10_LFD450]="libtool-bin"
PACKAGES[Ubuntu-16.04_LFD450]="libtool-bin"
RECOMMENDS[RHEL_LFD450]="python-devel"

#===============================================================================
# Extra requirements for LFD455
#===============================================================================
DESCRIPTION[LFD455]="Advanced Embedded Linux Development"
#WEBPAGE[LFD455]="$LFDTRAINING/embedded-linux-development"
CPUS[LFD455]=2
PREFER_CPUS[LFD455]=4
BOGOMIPS[LFD455]=3000
RAM[LFD455]=2
DISK[LFD455]=30
INTERNET[LFD455]=Required
CARDREADER[LFD455]=Required
NATIVELINUX[LFD455]="highly recommended"
VMOKAY[LFD455]="highly discouraged"
#-------------------------------------------------------------------------------
PACKAGES[LFD455]="@build @common @embedded @kernel @trace help2man"
PACKAGES[Ubuntu_LFD455]="libtool squashfs-tools"
RECOMMENDS[Ubuntu_LFD455]="libpython-dev"
PACKAGES[Ubuntu-12.04_LFD455]="-libpython-dev"
PACKAGES[Ubuntu-14.04_LFD455]="libtool"
PACKAGES[Ubuntu-15.10_LFD455]="libtool-bin"
PACKAGES[Ubuntu-16.04_LFD455]="libtool-bin"
RECOMMENDS[RHEL_LFD455]="python-devel"

#===============================================================================
# Extra requirements for LFD460
#===============================================================================
DESCRIPTION[LFD460]="Building Embedded Linux with the Yocto Project"
WEBPAGE[LFD460]="$LFDTRAINING/embedded-linux-development-with-yocto-project"
CPUS[LFD460]=4
PREFER_CPUS[LFD460]=8
BOGOMIPS[LFD460]=20000
RAM[LFD460]=4
DISK[LFD460]=100
INTERNET[LFD460]=Required
CARDREADER[LFD460]="highly recommended"
NATIVELINUX[LFD460]="highly recommended"
VMOKAY[LFD460]="highly discouraged"
SYMLINKS[LFD460]="/usr/bin/python:!^/opt/"
VERSIONS[LFD460]="python:<3"
EXTRAS[LFD460]="LFD460_%COURSE_VERSION%/"
#-------------------------------------------------------------------------------
PACKAGES[LFD460]="@build @common @embedded chrpath diffstat python-pip
	python-ply python-progressbar socat xterm"
#-------------------------------------------------------------------------------
PACKAGES[Ubuntu_LFD460]="daemon libarchive-dev libglib2.0-dev libsdl1.2-dev
	libxml2-utils texinfo xsltproc"
RECOMMENDS[Ubuntu_LFD460]="default-jre"
PACKAGES[Ubuntu-14.04_LFD460]="libnfs1"
PACKAGES[Ubuntu-15.10_LFD460]="libnfs8"
PACKAGES[Ubuntu-16.04_LFD460]="libnfs8 -libsdl1.2-dev libsdl2-dev"
PACKAGES[Debian-7_LFD460]="libnfs1"
PACKAGES[Debian-8_LFD460]="libnfs4"
PACKAGES[Debian-999_LFD460]="libnfs8"
PACKAGES[RHEL_LFD460]="bzip2 cpp daemonize diffutils gzip libarchive-devel python
	perl tar SDL-devel"
PACKAGES[Fedora_LFD460]="cpp daemonize diffutils libarchive-devel perl
	perl-Data-Dumper perl-Text-ParseWords perl-Thread-Queue python SDL-devel"
PACKAGES[Fedora-24_LFD460]="-python-ply"
PACKAGES[openSUSE_LFD460]="libarchive-devel libSDL-devel python python-curses
	python-xml"

#===============================================================================
# Extra requirements for LFD461
#===============================================================================
DESCRIPTION[LFD461]="KVM for Developers"
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
# Extra requirements for LFS101
#===============================================================================
DESCRIPTION[LFS101]="Introduction to Linux"
WEBPAGE[LFS101]="$LFSTRAINING/introduction-to-linux"
#-------------------------------------------------------------------------------
PACKAGES[LFS101]="@common"

#===============================================================================
# Extra requirements for LFS201
#===============================================================================
DESCRIPTION[LFS201]="Essentials of System Administration"
WEBPAGE[LFS201]="$LFSTRAINING/essentials-of-system-administration"
#-------------------------------------------------------------------------------
PACKAGES[LFS201]="@build @common @sysadm @trace cryptsetup quota xfsprogs"
PACKAGES[Debian_LFS201]="btrfs-tools"
PACKAGES[Debian-999_LFS201]="-btrfs-tools btrfs-progs"
PACKAGES[RHEL_LFS201]="btrfs-progs"
PACKAGES[RHEL-6_LFS201]="-cryptsetup"

#===============================================================================
# Extra requirements for LFS211
#===============================================================================
DESCRIPTION[LFS211]="Linux Networking and Administration"
WEBPAGE[LFS211]="$LFSTRAINING/linux-network-and-administration"
#-------------------------------------------------------------------------------
PACKAGES[LFS211]="@build @common @sysadm @trace ftp mutt nmap postfix vsftpd"
PACKAGES[Ubuntu_LFS211]="bsd-mailx dovecot-imapd dovecot-lmtpd dovecot-pop3d
	openssh-server"
RECOMMENDS[Ubuntu_LFS211]="zenmap"
PACKAGES[RHEL_LFS211]="dovecot mailx openssh-server"
PACKAGES[openSUSE_LFS211]="dovecot22 mailx openssh"
RECOMMENDS[openSUSE_LFS211]="zenmap"
PACKAGES[openSUSE-13.1_LFS211]="-dovecot22"

#===============================================================================
# Extra requirements for LFS265
#===============================================================================
DESCRIPTION[LFS265]="Software Defined Networking Fundamentals"
WEBPAGE[LFS265]="$LFSTRAINING/software-defined-networking-fundamentals"
CPUS[LFS265]=2
PREFER_CPUS[LFS265]=4
BOGOMIPS[LFS265]=10000
RAM[LFS265]=4
DISK[LFS265]=20
CONFIGS[LFS265]=OPENVSWITCH
DISTROS[LFS265]=Ubuntu:amd64-16.04
#-------------------------------------------------------------------------------
PACKAGES[LFS265]="@build @common"
#-------------------------------------------------------------------------------
PACKAGES[Ubuntu_LFS265]="default-jre libxml2-dev libxslt1-dev maven mininet
	openvswitch-switch openvswitch-test openvswitch-testcontroller
	python-openvswitch tshark wireshark wireshark-doc"
RECOMMENDS[Ubuntu_LFS265]="build-dep_wireshark"
PACKAGES[Ubuntu-12.04_LFS265]="-mininet -openvswitch-testcontroller"
PACKAGES[Ubuntu-14.04_LFS265]="-openvswitch-testcontroller"
PACKAGES[Debian_LFS265]="-" # Forcing empty list so it doesn't fallback to Ubuntu
PACKAGES[Debian-999_LFS265]="[Ubuntu_LFS265]"
PACKAGES[LinuxMint_LFS265]="-"

#===============================================================================
# Extra requirements for LFS300
#===============================================================================
DESCRIPTION[LFS300]="Fundamentals of Linux"
WEBPAGE[LFS300]="$LFSTRAINING/fundamentals-of-linux"
#-------------------------------------------------------------------------------
PACKAGES[LFS300]="@common"

#===============================================================================
# Extra requirements for LFS301
#===============================================================================
DESCRIPTION[LFS301]="Linux System Administration"
WEBPAGE[LFS301]="$LFSTRAINING/linux-system-administration"
#-------------------------------------------------------------------------------
COPYPACKAGES[LFS301]="LFS201"

#===============================================================================
# Extra requirements for LFS311
#===============================================================================
DESCRIPTION[LFS311]="Advanced Linux System Administration and Networking"
WEBPAGE[LFS311]="$LFSTRAINING/advanced-linux-system-administration-and-networking"
#-------------------------------------------------------------------------------
COPYPACKAGES[LFS311]="LFS211"

#===============================================================================
# Extra requirements for LFS416
#===============================================================================
DESCRIPTION[LFS416]="Linux Security"
WEBPAGE[LFS416]="$LFSTRAINING/linux-security"
ARCH[LFS416]=x86_64
CPUS[LFS416]=4
BOGOMIPS[LFS416]=20000
RAM[LFS416]=8
DISK[LFS416]=20
INTERNET[LFS416]=y
CPUFLAGS[LFS416]=vmx
CONFIGS[LFS416]="HAVE_KVM KSM"
#-------------------------------------------------------------------------------
PACKAGES[LFS416]="@build @common @virt"
#-------------------------------------------------------------------------------
PACKAGES[Ubuntu_LFS416]="apache2-utils"
PACKAGES[RHEL_LFS416]="kernel-devel"
PACKAGES[openSUSE_LFS416]="[RHEL_LFS416]"

#===============================================================================
# Extra requirements for LFS422
#===============================================================================
DESCRIPTION[LFS422]="High Availability Linux Architecture"
WEBPAGE[LFS422]="$LFSTRAINING/high-availability-linux-architecture"
ARCH[LFS422]=x86_64
CPUS[LFS422]=2
RAM[LFS422]=4
DISK[LFS422]=40
DISTRO_ARCH[LFS422]=x86_64
INTERNET[LFS422]=y
CPUFLAGS[LFS422]=vmx
DISTROS[LFS422]="Ubuntu:amd64-12.04 Ubuntu:amd64-14.04 Ubuntu:amd64-16.04+"
#-------------------------------------------------------------------------------
PACKAGES[LFS422]="@common @sysadm @trace @virt"

#===============================================================================
# Extra requirements for LFS426
#===============================================================================
DESCRIPTION[LFS426]="Linux Performance Tuning"
WEBPAGE[LFS426]="$LFSTRAINING/linux-performance-tuning"
ARCH[LFS426]=x86_64
CPUS[LFS426]=2
PREFER_CPUS[LFS426]=4
BOGOMIPS[LFS426]=20000
RAM[LFS426]=2
DISK[LFS426]=5
DISTRO_ARCH[LFS426]=x86_64
INTERNET[LFS426]=y
#-------------------------------------------------------------------------------
PACKAGES[LFS426]="@build @common @sysadm @trace @virt blktrace blktrace crash
	fio hdparm lynx mdadm sysstat systemtap valgrind"
PACKAGES[Debian_LFS426]="cpufrequtils iozone3 libaio-dev libblas-dev libncurses5-dev
	nfs-kernel-server zlib1g-dev"
PACKAGES[Debian-999_LFS426]="lmbench"
PACKAGES[Ubuntu_LFS426]="[Debian_LFS426] hugepages lmbench nfs-kernel-server oprofile"
RECOMMENDS[Ubuntu_LFS426]="stress"
PACKAGES[Ubuntu-12.04_LFS426]="-oprofile"
PACKAGES[RHEL_LFS426]="blas-devel kernel-devel libaio-devel libhugetlbfs-utils
	ncurses-devel oprofile perl-Time-HiRes zlib-devel"
PACKAGES[RHEL-6_LFS426]="cpufrequtils"
RECOMMENDS[RHEL-6_LFS426]="stress"
PACKAGES[RHEL-7_LFS426]="-"
RECOMMENDS[Fedora_LFS426]="stress"
PACKAGES[openSUSE_LFS426]="blas-devel kernel-devel libaio-devel ncurses-devel
	nfs-kernel-server oprofile zlib-devel zlib-devel-static"
PACKAGES[openSUSE-13.1_LFS426]="cpufrequtils"
PACKAGES[openSUSE-999_LFS426]="iozone"

#===============================================================================
# Extra requirements for LFS430
#===============================================================================
DESCRIPTION[LFS430]="Linux Enterprise Automation"
WEBPAGE[LFS430]="$LFSTRAINING/linux-enterprise-automation"
#-------------------------------------------------------------------------------
PACKAGES[LFS430]="@build @common @sysadm @trace"

#===============================================================================
# Extra requirements for LFS452
#===============================================================================
DESCRIPTION[LFS452]="Essentials of OpenStack Administration"
WEBPAGE[LFS452]="$LFSTRAINING/essentials-of-openstack-administration"
#-------------------------------------------------------------------------------
PACKAGES[LFS452]="@common @sysadm"

#===============================================================================
# Extra requirements for LFS462
#===============================================================================
DESCRIPTION[LFS462]="Introduction to Linux KVM Virtualization"
WEBPAGE[LFS462]="$LFSTRAINING/linux-kvm-virtualization"
CPUS[LFS462]=2
PREFER_CPUS[LFS462]=4
BOGOMIPS[LFS462]=10000
RAM[LFS462]=3
CPUFLAGS[LFS462]=vmx
CONFIGS[LFS462]="HAVE_KVM KSM"
NATIVELINUX[LFS462]="Required"
VMOKAY[LFS462]="This course can't be run on a VM"
#-------------------------------------------------------------------------------
PACKAGES[LFS462]="@build @common @virt"
#-------------------------------------------------------------------------------
PACKAGES[Ubuntu_LFS462]="g++"
PACKAGES[RHEL_LFS462]="kernel-devel"
PACKAGES[openSUSE_LFS462]="[RHEL_LFS462]"

#===============================================================================
# Extra requirements for LFS465
#===============================================================================
DESCRIPTION[LFS465]="Software Defined Networking with OpenDaylight"
WEBPAGE[LFS465]="$LFSTRAINING/software-defined-networking-with-opendaylight"
CPUS[LFS465]=2
PREFER_CPUS[LFS465]=4
BOGOMIPS[LFS465]=10000
RAM[LFS465]=4
DISK[LFS465]=20
CONFIGS[LFS465]=OPENVSWITCH
DISTROS[LFS465]=Ubuntu:amd64-15.10+
#-------------------------------------------------------------------------------
COPYPACKAGES[LFS465]="LFS265"

#===============================================================================
#=== End of Course Definitions =================================================
#===============================================================================

#===============================================================================
check_root() {
    if [[ $USER == root || $HOME == /root ]] ; then
        fail "Please don't run as root"
        notice "Sudo will be used internally by this script as required."
        exit 1
    fi
}

#===============================================================================
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

#===============================================================================
# List available courses
list_courses() {
    echo "Available courses:"
    for D in ${!DESCRIPTION[*]}; do
        echo "  $D - ${DESCRIPTION[$D]}"
    done | sort
    exit 0
}

#===============================================================================
for_each_course() {
    local CODE=$1; shift
    local COURSES CLASS
    COURSES=$(list_sort "$@")
    debug "for_each_course: $COURSES"
    for CLASS in $COURSES ; do
        debug "  for_each_course: eval $CODE $CLASS"
        eval "$CODE $CLASS"
    done
}

#===============================================================================
supported_course() {
    local CLASS=$1
    [[ -n ${DESCRIPTION[$CLASS]} ]] || warn "Unsupported course: $CLASS"
}

#===============================================================================
check_course() {
    local CLASS=$1
    local DESC=${DESCRIPTION[$CLASS]}
    debug "check_course: CLASS=$CLASS"

    if [[ -z $DESC ]] ; then
        if DESC=$(get_cm_var DESCRIPTION "$CLASS") && [[ -n $DESC ]] ; then
            debug "  check_course: Custom $CLASS -> $COURSES"
        elif [[ -n ${COURSE_ALIASES[$CLASS]} ]] ; then
            debug "  check_course: Alias $CLASS"
            CLASS=${COURSE_ALIASES[$CLASS]}
            DESC=${DESCRIPTION[$CLASS]}
        fi
        debug "  check_course: CLASS=$CLASS DESC=$DESC"
    fi

    if [[ -n $DESC ]] ; then
        highlight "Checking that this computer is suitable for $CLASS: $DESC"
    else
        warn "Unknown course \"$CLASS\", checking defaults requirements instead"
    fi
}

#===============================================================================
try_course() {
    local CLASS=$1 NEWCLASS=$2
    [[ -n ${DESCRIPTION[$NEWCLASS]} ]] || return 1
    if warn_wait "I think you meant $NEWCLASS (not $CLASS)" ; then
        echo "$NEWCLASS"
    else
        echo "$CLASS"
    fi
}

#===============================================================================
spellcheck_course() {
    local CLASS=$1
    local COURSES
    [[ -n $CLASS ]] || return 0
    if [[ -n ${DESCRIPTION[$CLASS]} ]] ; then
        echo "$CLASS"
    elif COURSES=$(get_cm_var COURSES "$CLASS") && [[ -n $COURSES ]] ; then
        echo "$COURSES"
    else
        try_course "$CLASS" "${CLASS/LFD/LFS}" \
            || try_course "$CLASS" "${CLASS/LFS/LFD}" \
            || echo "$CLASS"
    fi
}

#===============================================================================
# Determine Course
find_course() {
    local COURSE=$1

    if [[ -n $COURSE && -n ${COURSE_ALIASES[$COURSE]} ]] ; then
        notice "$COURSE is an alias for ${COURSE_ALIASES[$COURSE]}"
        COURSE=${COURSE_ALIASES[$COURSE]}
    fi
    spellcheck_course "$COURSE"
}

#===============================================================================
# Try package list for all courses
try_all_courses() {
    # shellcheck disable=SC2086
    for D in $(list_sort ${!DESCRIPTION[*]}); do
        echo "==============================================================================="
        NO_PASS=1 $CMDNAME \
                ${NOCM:+--no-course-materials} \
                ${NOEXTRAS:+--no-extras} \
                ${NOINSTALL:+--no-install} \
                ${NORECOMMENDS:+--no-recommends} \
                "$D"
    done
    exit 0
}

#===============================================================================
distrib_list() {
    local RETURN=$1
    local L
    L=$(for D in ${!PACKAGES[*]}; do
        echo "$D"
    done | sed -e 's/_.*$//' | grep -- - | sort -u)
    # shellcheck disable=SC2086
    eval $RETURN="'$L'"
}

#===============================================================================
distrib_ver() {
    local DID=$1 DREL=$2
    local AVAIL_INDEXES AVAIL_RELS DVER
    debug "distrib_ver: DID=$DID DREL=$DREL"
    AVAIL_INDEXES=$(for D in ${!PACKAGES[*]}; do
        echo "$D"
    done | grep "$DID" | sort -ru)
    # shellcheck disable=SC2086
    debug "  distrib_ver: Available package indexes for $DID:" $AVAIL_INDEXES
    AVAIL_RELS=$(for R in $AVAIL_INDEXES; do
        R=${R#*-}
        echo "${R%_*}"
    done | grep -v "^$DID" | sort -ru)
    # shellcheck disable=SC2086
    debug "  distrib_ver: Available distro releases for $DID:" $AVAIL_RELS
    DVER=1
    for R in $AVAIL_RELS ; do
        if version_greater_equal "$DREL" "$R" ; then
            DVER="$R"
            break
        fi
    done
    debug "  distrib_ver: We're going to use $DID-$DVER"
    echo "$DVER"
}

#===============================================================================
# Do a lookup in DB of KEY
lookup() {
    local DB=$1
    local KEY=$2
    debug "  lookup: DB=$DB KEY=$KEY"
    [[ -n $KEY ]] || return
    local DATA
    DATA=$(eval "echo \${$DB[$KEY]}")
    if [[ -n $DATA ]] ; then
        debug "    lookup: $DB[$KEY] -> $DATA"
        echo "$DATA"
        return 0
    fi
    return 1
}

#===============================================================================
# Do a lookup in DB for DIST[-RELEASE] and if unfound consult FALLBACK distros
lookup_fallback() {
    local DB=$1
    local NAME=$2
    local DIST=$3
    local RELEASE=$4
    debug "  lookup_fallback: DB=$DB NAME=$NAME DIST=$DIST RELEASE=$RELEASE"
    DIST+=${RELEASE:+-$RELEASE}
    local KEY
    debug "    lookup_fallback: $DIST => ${FALLBACK[${DIST:-no_distro}]}"
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
    debug "get_db: DB=$DB NAME=$NAME DIST=$DIST RELEASE=$RELEASE"

    RESULT="$(lookup "$DB" "$NAME")"
    RESULT+=" $(lookup_fallback "$DB" "$NAME" "$DIST" '')"
    RESULT+=" $(lookup_fallback "$DB" "$NAME" "$DIST" "$RELEASE")"
    # shellcheck disable=SC2086
    debug "  get_db: RESULT="$RESULT
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
    debug "  pkg_list_expand: DB=$DB DID=$DID DREL=$DREL PLIST="$*

    for KEY in "$@" ; do
        case $KEY in
            @*) PKGS=$(get_db "$DB" "$KEY" "$DID" "$DREL")
                # shellcheck disable=SC2086
                pkg_list_expand "$DB" "$DID" "$DREL" $PKGS ;;
            [*) PKGS=$(eval "echo \${$DB$KEY}") #]
                debug "    pkg_list_expand: lookup macro $DB$KEY -> $PKGS"
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
    debug "  pkg_list_contract BEFORE="$BEFORE
    for PKG in $BEFORE; do
        if [[ $PKG == -* ]] ; then
            AFTER=$(for P in $AFTER; do
                echo "$P"
            done | egrep -v "^-?${PKG#-}$")
        fi
    done
    # shellcheck disable=SC2086
    debug "  pkg_list_contract: AFTER="$AFTER
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
    local CLASS=$3
    local DVER PLIST LIST RLIST
    debug "package_list: DID=$DID DREL=$DREL CLASS=$CLASS"

    pkg_list_check

    if [[ -n ${COPYPACKAGES[$CLASS]} ]] ; then
        debug "package_list: COPYPACKAGES $CLASS -> ${COPYPACKAGES[$CLASS]}"
        CLASS=${COPYPACKAGES[$CLASS]}
    fi

    DVER=$(distrib_ver "$DID" "$DREL")

    #---------------------------------------------------------------------------
    PLIST=$(get_db PACKAGES "" "$DID" "$DVER"; get_db PACKAGES "$CLASS" "$DID" "$DVER")
    # shellcheck disable=SC2086
    debug "package_list: PLIST="$PLIST
    # shellcheck disable=SC2046,SC2086
    LIST=$(list_sort $(pkg_list_expand PACKAGES "$DID" "$DVER" $PLIST))
    # shellcheck disable=SC2086
    debug "package_list: PACKAGES LIST="$LIST

    if [[ -z $NORECOMMENDS ]] ; then
        RLIST=$(get_db RECOMMENDS "" "$DID" "$DVER"; get_db RECOMMENDS "$CLASS" "$DID" "$DVER")
        # shellcheck disable=SC2086
        debug "package_list: RLIST="$RLIST
        # shellcheck disable=SC2046,SC2086
        LIST=$(list_sort $LIST $(pkg_list_expand RECOMMENDS "$DID" "$DVER" $PLIST $RLIST))
        # shellcheck disable=SC2086
        debug "package_list: +RECOMMENDS LIST="$LIST
    fi

    # shellcheck disable=SC2086
    LIST=$(pkg_list_contract $LIST)
    # shellcheck disable=SC2086
    debug "package_list: Final packages for $DID-${DVER}_$CLASS:" $LIST
    echo "$LIST"
}

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
    [[ -z "$LIST" ]] || echo "    $WS$NAME: $LIST"
}
list_grep() {
    local REGEX
    REGEX=$(sed -e 's/\+/\\+/g' <<<$1); shift
    # shellcheck disable=SC2086
    debug "list_grep REGEX=$REGEX => "$*
    sed 's/ /\n/g' <<< "$@" | egrep "$REGEX" | sort -u
}
list_sort() {
    sed 's/ /\n/g' <<< "$@" | sort -u
}
#-------------------------------------------------------------------------------
list_requirements() {
    local COURSE=$1
    local DISTS D DIST
    [[ -n $COURSE ]] && supported_course "$COURSE"
    # shellcheck disable=SC2086
    [[ -n $COURSE ]] && COURSES="$COURSE" || COURSES=$(list_sort ${!DESCRIPTION[*]})
    echo 'Courses:'
    for D in $COURSES; do
        echo "  $D:"
        list_entry DESCRIPTION "${DESCRIPTION[$D]}"
        list_entry WEBPAGE "${WEBPAGE[$D]}"
        list_entry ARCH "${ARCH[$D]:-$ARCH}"
        list_entry CPUFLAGS "${CPUFLAGS[$D]:-$CPUFLAGS}"
        list_entry CPUS "${CPUS[$D]:-$CPUS}"
        list_entry PREFER_CPUS "${PREFER_CPUS[$D]:-$PREFER_CPUS}"
        list_entry BOGOMIPS "${BOGOMIPS[$D]:-$BOGOMIPS}"
        list_entry RAM "${RAM[$D]:-$RAM}"
        list_entry DISK "${DISK[$D]:-$DISK}"
        list_entry BOOT "${BOOT[$D]:-$BOOT}"
        list_entry CONFIGS "${CONFIGS[$D]:-$CONFIGS}"
        list_entry DISTRO_ARCH "${DISTRO_ARCH[$D]:-$DISTRO_ARCH}"
        list_entry INTERNET "${INTERNET[$D]:-$INTERNET}"
        list_entry CARDREADER "${CARDREADER[$D]:-$CARDREADER}"
        list_entry NATIVELINUX "${NATIVELINUX[$D]:-$NATIVELINUX}"
        list_entry VMOKAY "${VMOKAY[$D]:-$VMOKAY}"
        list_array DISTROS "" ${DISTROS[$D]:-$DISTROS}
        # shellcheck disable=SC2086
        list_array DISTRO_BL "" ${DISTRO_BL[$D]:-$DISTRO_BL}
        [[ -z $DIST_LIST ]] && distrib_list DISTS || DISTS=$DIST_LIST
        # shellcheck disable=SC2086
        debug "list_requirements: DISTS="$DISTS
        if [[ -n "$DISTS" ]] ; then
            echo '    PACKAGES:'
            for DIST in $DISTS; do
                local P
                # shellcheck disable=SC2086
                P=$(package_list ${DIST/-/ } $D)
                debug "$P"
                # shellcheck disable=SC2086
                list_array "$DIST" "  " $P
            done
        fi
    done
}

#===============================================================================
# Check Packages
check_packages() {
    local COURSES=$1
    local DISTS D DIST P
    local SEARCH="./pkgsearch"
    if [[ ! -x $SEARCH ]] ; then
        error "$SEARCH not found"
    fi

    distrib_list DISTS
    # shellcheck disable=SC2086
    debug "check_packages: DISTS="$DISTS
    if [[ -n $COURSES ]] ; then
        supported_course "$COURSES"
    else
        # shellcheck disable=SC2086
        COURSES=$(list_sort ${!DESCRIPTION[*]})
    fi
    for D in $COURSES; do
        [[ -n $VERBOSE ]] || progress "$D "
        for DIST in $DISTS; do
            [[ -n $VERBOSE ]] || progress '.'
            # shellcheck disable=SC2086
            P=$(package_list ${DIST/-/ } $D)
            # shellcheck disable=SC2086
            debug "check_packages: P="$P
            local OPTS OUTPUT
            [[ -n $VERBOSE ]] || OPTS="-q"
            # shellcheck disable=SC2086
            debug "check_packages: $SEARCH $OPTS -df $DIST "$P
            # shellcheck disable=SC2086
            OUTPUT=$($SEARCH $OPTS -df "$DIST" $P)
            if [[ -n $OUTPUT ]] ; then
                [[ -n $VERBOSE ]] || echo
                notice "Checking $DIST for $D..."
                echo "$OUTPUT"
            fi
        done
    done
    [[ -n $VERBOSE ]] || echo
}

#===============================================================================
# List Packages
list_packages() {
    local COURSES=$1
    local DISTS D DIST PL P
    debug "list_packages: COURSES=$COURSES PKGS=$PKGS"

    distrib_list DISTS
    # shellcheck disable=SC2086
    debug "list_packages: DISTS="$DISTS
    if [[ -n $COURSES ]] ; then
        supported_course "$COURSES"
    else
        # shellcheck disable=SC2086
        COURSES=$(list_sort ${!DESCRIPTION[*]})
    fi
    for D in $COURSES; do
        notice "Listing packages for $D..."
        for DIST in $DISTS; do
            # shellcheck disable=SC2086
            PL=$(package_list ${DIST/-/ } $D)
            # shellcheck disable=SC2086
            debug PL1=$PL
            # shellcheck disable=SC2086
            [[ -z $PKGS ]] || PL=$(list_grep "^$PKGS$" $PL)
            # shellcheck disable=SC2086
            debug PL2=$PL
            for P in $PL ; do
                echo -e "$DIST\t$P"
            done
        done
    done
}

#===============================================================================
parse_distro() {
    local DIST DARCH DVER GT
    IFS='-' read -r DIST GT <<< "$1"
    DVER=${GT%+}
    GT=${GT/$DVER/}
    IFS=':' read -r DIST DARCH <<< "$DIST"
    debug "parse_distro: $DIST,$DARCH,$DVER,$GT"
    echo "$DIST,$DARCH,$DVER,$GT"
}

#===============================================================================
# Is distro-B in filter-A?
cmp_dists() {
    local A=$1 B=$2
    debug "cmp_dists: $A $B"

    [[ $A = "$B" || $A+ = "$B" || $A = $B+ ]] && return 0

    local AD AA AV AG
    local BD BA BV BG
    IFS=',' read -r AD AA AV AG <<< $(parse_distro "$A")
    # shellcheck disable=SC2034
    IFS=',' read -r BD BA BV BG <<< $(parse_distro "$B")

    if [[ $AD == "$BD" ]] ; then
        [[ -n $AA || -n $BA ]] && [[ $AV == "$BV" ]] && return 0
        [[ $AV == "$BV" ]] && return 0
        if [[ -n $AG ]] ; then
            version_greater_equal "$AV" "$BV" || return 0
        fi
    fi
    return 1
}

#===============================================================================
filter_dists() {
    local FILTER=$1; shift;
    local DISTS=$*
    local F D

    debug "filter_dists <$FILTER> <$DISTS>"

    if [[ -z $FILTER ]] ; then
        echo "$DISTS"
        return 0
    fi

    for D in $DISTS; do
        for F in $FILTER; do
            if cmp_dists "$F" "$D" ; then
                debug "filter_dists $D is in $F"
                echo "$D"
            fi
        done
    done
}

#===============================================================================
# JSON support
json_entry() {
    local NAME=$1; shift
    progress '.'
    [[ -z "$*" ]] || echo "      \"$NAME\": \"$*\","
}
json_array() {
    local NAME=$1; shift
    local WS=$1; shift
    local LIST=$*
    progress '+'
    [[ -z "$LIST" ]] || echo "      $WS\"$NAME\": [\"${LIST// /\", \"}\"],"
}
#-------------------------------------------------------------------------------
list_json() {
    distrib_list DISTS
    ( cat <<END
{
  "whatisthis": "Description of Linux Foundation course requirements",
  "form": {
    "description": "Course Description",
    "arch": "Required CPU Architecture",
    "cpuflags": "Required CPU features",
    "cpus": "Required Number of CPU cores",
    "prefer_cpus": "Preferred Number of CPU cores",
    "bogomips": "Minimum CPU Performance (bogomips)",
    "ram": "Minimum Amount of RAM (GiB)",
    "disk": "Free Disk Space in \$HOME (GiB)",
    "boot": "Free Disk Space in /boot (MiB)",
    "configs": "Kernel Configuration Options",
    "distro_arch": "Distro Architecture",
    "internet": "Is Internet Required?",
    "card_reader": "Is the use of a Card Reader Required?",
    "native_linux": "Native Linux",
    "vm_okay": "Virtual Machine",
    "distros": "Supported Linux Distros",
    "distro_bl": "Unsupported Linux Distros",
    "packages": "Package List"
  },
  "distros": [
$(for DIST in $DISTS ; do echo '    "'"$DIST"'+",'; done | sort)
  ],
  "distro_fallback": {
$(for FB in ${!FALLBACK[*]} ; do echo '    "'"$FB"'": "'"${FALLBACK[$FB]}"'",'; done | sort)
  },
  "courses": {
END
    local D DLIST DIST P
    # shellcheck disable=SC2086
    for D in $(list_sort ${!DESCRIPTION[*]}); do
        progress "$D: "
        echo "    \"$D\": {"
        json_entry description "${DESCRIPTION[$D]}"
        json_entry url "${WEBPAGE[$D]}"
        json_entry arch "${ARCH[$D]:-$ARCH}"
        json_entry cpuflags "${CPUFLAGS[$D]:-$CPUFLAGS}"
        json_entry cpus "${CPUS[$D]:-$CPUS}"
        json_entry prefer_cpus "${PREFER_CPUS[$D]:-$PREFER_CPUS}"
        json_entry bogomips "${BOGOMIPS[$D]:-$BOGOMIPS}"
        json_entry ram "${RAM[$D]:-$RAM}"
        json_entry disk "${DISK[$D]:-$DISK}"
        json_entry boot "${BOOT[$D]:-$BOOT}"
        json_entry configs "${CONFIGS[$D]:-$CONFIGS}"
        json_entry distro_arch "${DISTRO_ARCH[$D]:-$DISTRO_ARCH}"
        json_entry internet "${INTERNET[$D]:-$INTERNET}"
        json_entry card_reader "${CARDREADER[$D]:-$CARDREADER}"
        json_entry native_linux "${NATIVELINUX[$D]:-$NATIVELINUX}"
        json_entry vm_okay "${VMOKAY[$D]:-$VMOKAY}"
        json_array distros "" ${DISTROS[$D]:-$DISTROS}
        # shellcheck disable=SC2086
        [[ ${DISTRO_BL[$D]} != delete ]] && json_array distro_bl "" ${DISTRO_BL[$D]:-$DISTRO_BL}
        # shellcheck disable=SC2086
        DLIST=$(filter_dists "${DISTROS[$D]}" $DISTS)
        if [[ -n "$DLIST" ]] ; then
            echo '      "packages": {'
            # shellcheck disable=SC2013
            for DIST in $(sed 's/:[a-zA-Z0-9]*-/-/g; s/\+//g' <<< $DLIST); do
                # shellcheck disable=SC2086
                P=$(package_list ${DIST/-/ } $D)
                # shellcheck disable=SC2086
                json_array "$DIST" "  " $P
            done
            echo '      },'
        fi
        echo '    },'
        progress "\n"
    done
    echo '  }'
    echo '}') | perl -e '$/=undef; $_=<>; s/,(\s+[}\]])/$1/gs; print;'
    # Minification
    #| sed ':a;N;$!ba; s/\n//g; s/   *//g; s/\([:,]\) \([\[{"]\)/\1\2/g'
    exit 0
}

#===============================================================================
# Determine Distro and release
guess_distro() {
    local DISTRO=$1
    debug "guess_distro: DISTRO=$DISTRO"
    local DISTRIB_SOURCE DISTRIB_ID DISTRIB_RELEASE DISTRIB_CODENAME DISTRIB_DESCRIPTION DISTRIB_ARCH
    #-------------------------------------------------------------------------------
    if [[ -f /etc/lsb-release ]] ; then
        DISTRIB_SOURCE+="/etc/lsb-release"
        . /etc/lsb-release
    fi
    #-------------------------------------------------------------------------------
    if [[ -z "$DISTRIB_ID" ]] ; then
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
        debug "  Overriding distro: $DISTRO"
        DISTRIB_SOURCE+=" override"
        DISTRIB_ID=${DISTRO%%-*}
        DISTRIB_RELEASE=${DISTRO##*-}
        DISTRIB_CODENAME=Override
        DISTRIB_DESCRIPTION="$DISTRO (Override)"
    fi
    #-------------------------------------------------------------------------------
    shopt -s nocasematch
    if [[ $DISTRIB_ID =~ Debian ]] ; then
        DISTRIB_RELEASE=${DEBREL[$DISTRIB_RELEASE]:-$DISTRIB_RELEASE}
    elif [[ $DISTRIB_ID =~ SUSE ]] ; then
        DISTRIB_ID=$(echo "$DISTRIB_DESCRIPTION" | sed 's/"//g; s/ .*//')
        version_greater_equal 20000000 "$DISTRIB_RELEASE" || DISTRIB_RELEASE=999
    elif [[ $DISTRIB_ID == Centos ]] ; then
        DISTRIB_ID=CentOS
    elif [[ $DISTRIB_ID == RedHat* || $DISTRIB_ID == Rhel ]] ; then
        DISTRIB_ID=RHEL
    fi
    shopt -u nocasematch
    #-------------------------------------------------------------------------------
    DISTRIB_ID=${DISTRIB_ID:-Unknown}
    DISTRIB_RELEASE=${DISTRIB_RELEASE:-0}
    #DISTRIB_CODENAME=${DISTRIB_CODENAME:-Unknown}
    [[ -n "$DISTRIB_DESCRIPTION" ]] || DISTRIB_DESCRIPTION="$DISTRIB_ID $DISTRIB_RELEASE"

    #===============================================================================
    # Determine Distro arch
    local DARCH
    if [[ -e /usr/bin/dpkg && $DISTRIB_ID =~ Debian|Kubuntu|LinuxMint|Mint|Ubuntu|Xubuntu ]] ; then
        DARCH=$(dpkg --print-architecture)
    elif [[ -e /bin/rpm || -e /usr/bin/rpm ]] && [[ $DISTRIB_ID =~ CentOS|Fedora|Rhel|RHEL|openSUSE|Suse|SUSE ]] ; then
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
    debug "  DISTRIB_SOURCE=$DISTRIB_SOURCE"
    debug "  DISTRIB_ID=$DISTRIB_ID"
    debug "  DISTRIB_RELEASE=$DISTRIB_RELEASE"
    debug "  DISTRIB_CODENAME=$DISTRIB_CODENAME"
    debug "  DISTRIB_DESCRIPTION=$DISTRIB_DESCRIPTION"
    debug "  DISTRIB_ARCH=$DISTRIB_ARCH"
    debug "  DARCH=$DARCH"
    echo "$DISTRIB_ID,$DISTRIB_RELEASE,$DISTRIB_CODENAME,$DISTRIB_DESCRIPTION,$DISTRIB_ARCH,$DARCH"
}

#===============================================================================
list_distro() {
    local ID=$1 ARCH=$2 RELEASE=$3 CODENAME=$4
    debug "list_distro: ID=$ID ARCH=$ARCH RELEASE=$RELEASE CODENAME=$CODENAME"
    echo "Linux Distro: $ID${ARCH:+:$ARCH}-$RELEASE ${CODENAME:+($CODENAME)}"
    exit 0
}

#===============================================================================
setup_meta() {
    local CLASS=$1
    debug "setup_meta: CLASS=$CLASS"

    local ATTR
    local ATTRS="ARCH CPUFLAGS CPUS PREFER_CPUS RAM DISK BOOT CONFIGS INTERNET \
            CARDREADER NATIVELINUX VMOKAY DISTROS DISTRO_BL DISTRO_ARCH \
            SYMLINKS VERSIONS EXTRAS"

    for ATTR in $ATTRS ; do
        eval "case \$$ATTR in
            [0-9]*) [[ \${$ATTR[$CLASS]} -gt \$$ATTR ]] && $ATTR=\"\${$ATTR[$CLASS]}\" ;;
            [a-zA-Z]*) [[ \${$ATTR[$CLASS]} > \$$ATTR ]] && $ATTR=\"\${$ATTR[$CLASS]}\" ;;
            *) $ATTR=\"\${$ATTR[$CLASS]}\" ;;
        esac
        debug \"  $ATTR=\$$ATTR\""
    done
}

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
        INSTALL=y NO_CHECK=y NO_PASS=y NO_WARN=y try_packages "$DID" "$DREL" COURSE sudo
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
    debug "check_repos: ID=$ID RELEASE=$RELEASE CODENAME=$CODENAME ARCH=$ARCH"
    verbose "Checking installed repos"

    #-------------------------------------------------------------------------------
    if [[ $ID == Debian ]] ; then
        debug "  Check repos for Debian"
        REPOS="contrib non-free"
        local LISTFILE=/etc/apt/sources.list.d/debian.list
        for SECTION in $REPOS ; do
            while read LINE ; do
                [[ -n $LINE ]] || continue
                debug "    Is '$LINE' enabled?"
                [[ -f $LISTFILE ]] || sudo touch $LISTFILE
                if ! grep -q "$LINE" $LISTFILE ; then
                    echo "$LINE" | sudo tee -a $LISTFILE
                    verbose "Adding '$LINE' to $LISTFILE"
                    CHANGES=y
                fi
            done <<< "$(grep "deb .*debian.* main" /etc/apt/sources.list "$([[ -f $LISTFILE ]] \
                && echo $LISTFILE)" | grep -v '#' | grep -v "$SECTION" | sed -e 's/main.*/'"$SECTION"'/')"
        done
        if [[ -n "$CHANGES" ]] ; then
            notice "Enabling $REPOS in sources.list... updating"
            sudo apt-get -qq update
        fi

    #-------------------------------------------------------------------------------
    elif [[ $ID =~ CentOS|RHEL ]] ; then
        debug "  Check repos for CentOS|RHEL"
        if rpm -q epel-release >/dev/null ; then
            verbose "epel is already installed"
        else
            case "$RELEASE" in
                6*) [[ $ARCH != i386 && $ARCH != x86_64 ]] \
                        || EPEL="$EPELURL/6/i386/epel-release-6-8.noarch.rpm" ;;
                7*) [[ $ARCH != x86_64 ]] \
                        || EPEL="$EPELURL/7/x86_64/e/epel-release-7-5.noarch.rpm" ;;
            esac
            if [[ -n $EPEL ]] ; then
                notice "Installing epel in ${ID}..."
                sudo rpm -Uvh $EPEL
            fi
        fi

    #-------------------------------------------------------------------------------
    elif [[ $ID == Ubuntu ]] ; then
        debug "  Check repos for Ubuntu"
        REPOS="universe multiverse"
        for SECTION in $REPOS ; do
            local DEB URL DIST SECTIONS
            # shellcheck disable=SC2094
            while read DEB URL DIST SECTIONS ; do
                [[ $URL =~ http && $DIST =~ $CODENAME && $SECTIONS =~ main ]] || continue
                [[ $URL =~ archive.canonical.com || $URL =~ extras.ubuntu.com ]] && continue
                debug "    $ID: is $SECTION enabled for $URL $DIST $SECTIONS"
                # shellcheck disable=2094
                if ! egrep -q "^$DEB $URL $DIST .*$SECTION" /etc/apt/sources.list ; then
                    verbose "Running: sudo add-apt-repository '$DEB $URL $DIST $SECTION'"
                    sudo add-apt-repository "$DEB $URL $DIST $SECTION"
                    CHANGES=y
                fi
            done </etc/apt/sources.list
        done
        if [[ -n "$CHANGES" ]] ; then
            notice "Enabling $REPOS in sources.list... updating"
            sudo apt-get -qq update
        fi
    fi
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
BUILDDEPSTR=build-dep_
no_build_dep() {
    sed 's/ /\n/g' <<< "$@" | grep -v $BUILDDEPSTR
}

#===============================================================================
only_build_dep() {
    sed 's/ /\n/g' <<< "$@" | grep $BUILDDEPSTR | sed "s/$BUILDDEPSTR//g"
}

#===============================================================================
# Install packages with apt-get
debinstall() {
    local PKGLIST BDLIST NEWPKG
    PKGLIST=$(no_build_dep "$@")
    BDLIST=$(only_build_dep "$@")
    [[ -z "$PKGLIST" && -z "$BDLIST" ]] && return
    # shellcheck disable=SC2086
    debug "debinstall: "$*

    deb_check

    local APTGET="apt-get --no-install-recommends"
    # Check for packages which can't be found
    if [[ -n "$PKGLIST" ]] ; then
        local ERRPKG
        # shellcheck disable=SC2086
        ERRPKG=$($APTGET --dry-run install $PKGLIST 2>&1 \
            | awk '/^E: Unable/ {print $6}; /^E: Package/ {print $3}' | grep -v -- '-f' | sed -e "s/'//g")
        if [[ -n "$ERRPKG" ]] ; then
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
        [[ -z "$PKGLIST" ]] || $APTGET --dry-run install $PKGLIST | awk '/^Inst / {print $2}';
        # shellcheck disable=SC2086
        [[ -z "$BDLIST" ]] || $APTGET --dry-run build-dep $BDLIST | awk '/^Inst / {print $2}'))
    [[ -n "$SIMULATE_FAILURE" ]] && NEWPKG=$PKGLIST
    if [[ -z "$NEWPKG" ]] ; then
        pass "All required packages are already installed"
    else
        warn "Some packages are missing"
        # shellcheck disable=SC2086
        notice "Need to install:" $NEWPKG
        if [[ -z "$INSTALL" ]] ; then
            fix_missing "You can install missing packages" \
                    "$0 --install $COURSE" \
                    "sudo $APTGET install $NEWPKG"
            MISSING_PACKAGES=y
        else
            # shellcheck disable=SC2086
            ask "About to install:" $NEWPKG "\nIs that okay? [y/N]"
            read CONFIRM
            case $CONFIRM in
            y*|Y*|1)
                # shellcheck disable=SC2086
                sudo $APTGET install $NEWPKG
                if [[ -z $NO_CHECK ]] ; then
                    # shellcheck disable=SC2086
                    FAILPKG=$(sudo $APTGET --dry-run install $PKGLIST | awk '/^Conf / {print $2}')
                    if [[ -n "$FAILPKG" ]] ; then
                        warn "Some packages didn't install: $FAILPKG"
                        WARNINGS=y
                    else
                        pass "All required packages are now installed"
                    fi
                fi ;;
            esac
        fi
    fi
}

#===============================================================================
# Install packages with yum or zypper
rpminstall() {
    local TOOL=$1; shift
    local PKGLIST=$*
    [[ -z "$PKGLIST" ]] && return
    debug "rpminstall: TOOL=$TOOL $PKGLIST"
    local NEWPKG

    # shellcheck disable=SC2046,SC2086
    NEWPKG=$(list_sort $(rpm -q $PKGLIST | awk '/is not installed$/ {print $2}'))
    [[ -n "$SIMULATE_FAILURE" ]] && NEWPKG=$PKGLIST
    if [[ -z "$NEWPKG" ]] ; then
        pass "All required packages are already installed"
    else
        warn "Some packages are missing"
        # shellcheck disable=SC2086
        notice "Need to install:" $NEWPKG
        if [[ -z "$INSTALL" ]] ; then
            fix_missing "You can install missing packages" \
                    "$0 --install $COURSE" \
                    "sudo $TOOL install $NEWPKG"
            MISSING_PACKAGES=y
        else
            # shellcheck disable=SC2086
            sudo $TOOL install $NEWPKG
            if [[ -z $NO_CHECK ]] ; then
                # shellcheck disable=SC2086
                FAILPKG=$(rpm -q $PKGLIST | awk '/is not installed$/ {print $2}')
                if [[ -n "$FAILPKG" ]] ; then
                    warn "Some packages didn't install: $FAILPKG"
                    WARNINGS=y
                else
                    pass "All required packages are now installed"
                fi
            fi
        fi
    fi
}

#===============================================================================
# Run extra code based on distro, release, and course
run_extra_code() {
    local DID=$1
    local DREL=$2
    local COURSE=$3
    local CODE
    debug "run_extra_code: DID=$DID DREL=$DREL COURSE=$COURSE"

    for KEY in $DID-${DREL}_$COURSE ${DID}_$COURSE $COURSE $DID-$DREL $DID ; do
        CODE=${RUNCODE[${KEY:-no_code_key}]}
        if [[ -n $CODE ]] ; then
            debug "  run exra setup code for $KEY -> eval $CODE"
            eval "$CODE $COURSE"
            return 0
        fi
    done
}

#===============================================================================
# TEST: Are the correct packages installed?
try_packages() {
    local ID=$1; shift
    local RELEASE=$1; shift
    local COURSE=$1; shift
    local PKGLIST
    PKGLIST=$(list_sort "$@")
    # shellcheck disable=SC2086
    debug "try_packages: ID=$ID RELEASE=$RELEASE COURSE=$COURSE PKGLIST="$PKGLIST

    #-------------------------------------------------------------------------------
    if [[ $ID =~ Debian|Kubuntu|LinuxMint|Mint|Ubuntu|Xubuntu ]] ; then
        # shellcheck disable=SC2086
        debinstall $PKGLIST
        # shellcheck disable=SC2086
        for_each_course "run_extra_code $ID $RELEASE" $COURSE

    #-------------------------------------------------------------------------------
    elif [[ $ID =~ CentOS|Fedora|RHEL ]] ; then
        PKGMGR=yum
        [[ -e /bin/dnf || -e /usr/bin/dnf ]] && PKGMGR=dnf
        # shellcheck disable=SC2086
        rpminstall $PKGMGR $PKGLIST
        # shellcheck disable=SC2086
        for_each_course "run_extra_code $ID $RELEASE" $COURSE

    #-------------------------------------------------------------------------------
    elif [[ $ID =~ openSUSE|Suse|SUSE ]] ; then
        # shellcheck disable=SC2086
        rpminstall zypper $PKGLIST
        # shellcheck disable=SC2086
        for_each_course "run_extra_code $ID $RELEASE" $COURSE

    #-------------------------------------------------------------------------------
    elif [[ $ID == "Arch" ]]  ; then
    # TODO: Add support for pacman here to provide similar functionality as apt-get code above
        warn "Currently there is no package support for Arch Linux"
        # shellcheck disable=SC2086
        for_each_course "run_extra_code $ID $RELEASE" $COURSE

    #-------------------------------------------------------------------------------
    elif [[ $ID == "Gentoo" ]]  ; then
    # TODO: Add support for emerge here to provide similar functionality as apt-get code above
        warn "Currently there is no package support for Gentoo"
        # shellcheck disable=SC2086
        for_each_course "run_extra_code $ID $RELEASE" $COURSE
    fi
}

#===============================================================================
# TEST: Right cpu architecture?
check_cpu() {
    local ARCH=$1
    local CPU_ARCH

    if [[ -n "$ARCH" ]] ; then
        verbose "check_cpu: ARCH=$ARCH"
        CPU_ARCH=$(uname -m)
        if [[ -n "$ARCH" && $CPU_ARCH != "$ARCH" || -n "$SIMULATE_FAILURE" ]] ; then
            fail "CPU architecture is $CPU_ARCH (Must be $ARCH)"
            FAILED=y
        else
            pass "CPU architecture is $CPU_ARCH"
        fi
    fi
}

#===============================================================================
# TEST: Right cpu flags?
check_cpu_flags() {
    local CPUFLAGS=$1
    local NOTFOUND

    if [[ -n "$CPUFLAGS" ]] ; then
        verbose "check_cpu_flags: CPUFLAGS=$CPUFLAGS"
        for FLAG in $CPUFLAGS ; do
            grep -qc " $FLAG " /proc/cpuinfo || NOTFOUND+=" $FLAG"
        done
        if [[ -n "$NOTFOUND" ]] ; then
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
    elif [[ $NUM_CPU -lt $CPUS || -n "$SIMULATE_FAILURE" ]] ; then
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

    if [[ -n "$BOGOMIPS" ]] ; then
        verbose "check_bogomips: BOGOMIPS=$BOGOMIPS"
        BMIPS=$(get_bogomips)
        [[ -z $BMIPS ]]
        if [[ -z $BMIPS || $BMIPS == 0 ]] ; then
            bug "I didn't find the number of BogoMIPS your CPU(s) have" \
                "awk '/^bogomips/ {mips+=\$3} END {print int(mips + 0.5)}' /proc/cpuinfo"
        elif [[ $BMIPS -lt $BOGOMIPS || -n "$SIMULATE_FAILURE" ]] ; then
            fail "Your CPU isn't powerful enough (must be at least $BOGOMIPS BogoMIPS cumulatively)"
            FAILED=y
        else
            if [[ -n "$NOTENOUGH" ]] ; then
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
    elif [[ $RAM_GBYTES -lt $RAM || -n "$SIMULATE_FAILURE" ]] ; then
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
    debug "find_alternate_disk: Looking for disk ${STRING:+(${STRING%=})} bigger than $MINSIZE $UNIT"

    # shellcheck disable=SC2034
    while read -r FS TOTAL USED AVAIL USE MP; do
        [[ -n $MP ]] || continue
        AVAIL=$(get_df "$MP" "$UNIT")
        debug "  Check MP=$MP AVAIL=$AVAIL UNIT=$UNIT"
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
    elif [[ ${DISK_GBYTES:=1} -lt $DISK || -n "$SIMULATE_FAILURE" ]] ; then
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
    elif [[ ${BOOT_MBYTES:=1} -le $BOOT || -n "$SIMULATE_FAILURE" ]] ; then
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

    if [[ -n "$DISTRO_ARCH" ]] ; then
        verbose "check_distro_arch: DISTRO_ARCH=$DISTRO_ARCH ARCH=$ARCH"
        if [[ -z $ARCH || -z $DISTRO_ARCH ]] ; then
            bug "Wasn't able to determine Linux distribution architecture" \
                "$0 --gather-info"
        elif [[ "$ARCH" != "$DISTRO_ARCH" || -n "$SIMULATE_FAILURE" ]] ; then
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
    debug "found_distro: ID=$ID DARCH=$DARCH RELEASE=$RELEASE DISTROS=$DISTROS"

    for DISTRO in $DISTROS ; do
        debug "  found_distro: $ID:$DARCH-$RELEASE compare $DISTRO"
        local G='' R='*' A='*'
        if [[ $DISTRO = *+ ]] ; then 
            G=y
            DISTRO=${DISTRO%\+}
            debug "    distro_found: $DISTRO or greater"
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
            debug "    found_distro: RELEASE=$RELEASE G=$G R=$R"
            if [[ $G = y && $R != "*" ]] && version_greater_equal "$RELEASE" "$R" ; then
                debug "    distro_found: $RELEASE >= $R"
                R='*'
            fi
            # shellcheck disable=SC2053
            if [[ $RELEASE = $R ]] ; then
                debug "$MSG Yes"
                return 0
            fi
        fi
        debug "$MSG No"
    done
    return 1
}

#===============================================================================
# TEST: Blacklisted Linux distribution?
check_distro_bl() {
    local ID=$1 DARCH=$2 RELEASE=$3 CODENAME=$4 DISTRO_BL=$5
    debug "check_distro_bl: ID=$ID DARCH=$DARCH RELEASE=$RELEASE DISTRO_BL=$DISTRO_BL"

    if [[ -n "$SIMULATE_FAILURE" ]] ; then
        DISTRO_BL=$ID-$RELEASE
    fi
    if [[ -z $ID || -z $DARCH ]] ; then
        bug "Wasn't able to determine Linux distribution" \
            "$0 --gather-info"
    elif [[ -n "$DISTRO_BL" ]] ; then
        if found_distro "$ID" "$DARCH" "$RELEASE" "$DISTRO_BL" ; then
            fail "This Linux distribution can't be used for this course: $ID:$DARCH-$RELEASE ${CODENAME:+($CODENAME)}"
            FAILED=y
            [[ -n "$SIMULATE_FAILURE" ]] || exit 1
        fi
    fi
}

#===============================================================================
# TEST: Right Linux distribution?
check_distro() {
    local ID=$1 DARCH=$2 RELEASE=$3 CODENAME=$4 DESCRIPTION=$5 DISTROS=$6
    debug "check_distros: ID=$ID DARCH=$DARCH RELEASE=$RELEASE DISTROS=$DISTROS"

    if [[ -n "$SIMULATE_FAILURE" ]] ; then
        DISTROS=NotThisDistro-0
    fi
    if [[ -z "$DISTROS" ]] ; then
        notice "No required Linux distribution (Currently running $DESCRIPTION)"
    elif [[ -z $ID || -z $DARCH ]] ; then
        bug "Wasn't able to determine Linux distribution" \
            "$0 --gather-info"
    else
        if found_distro "$ID" "$DARCH" "$RELEASE" "$DISTROS" ; then
            pass "Linux distribution is $ID:$DARCH-$RELEASE ${CODENAME:+($CODENAME)}"
        else
            fail "The distribution must be: $DISTROS"
            FAILED=y
        fi
    fi
}

#===============================================================================
# TEST: Is the kernel configured properly?
check_kernel_config() {
    local CONFIGS=$1

    if [[ -n "$CONFIGS" ]] ; then
        verbose "check_kernel_config: CONFIGS=$CONFIGS"
        local MISSINGCONFIG KERNELCONFIG
        KERNELCONFIG=${KERNELCONFIG:-/boot/config-$(uname -r)}
        if [[ ! -f $KERNELCONFIG ]] ; then
            warn "Wasn't able to find kernel config. You can specify it by settting KERNELCONFIG=<filename>"
            return 1
        fi
        for CONFIG in $CONFIGS ; do
            grep -qc "CONFIG_$CONFIG" "$KERNELCONFIG" || MISSINGCONFIG+=" $CONFIG"
        done
        if [[ -z "$MISSINGCONFIG" ]] ; then
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
        if [[ -z $SIMULATE_FAILURE && -n $AVAILABLE ]] ; then
            pass "Internet is available (which is required for this course)"
        elif [[ -z $SIMULATE_FAILURE ]] && ping -q -c 1 "$PING_HOST" >/dev/null 2>&1 ; then
            verbose "check_internet with ping PING_HOST=$PING_HOST"
            pass "Internet is available (which is required for this course)"
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
    debug "find_devices: DATA=... RETURN=$RETURN"

    [[ -n "$DATA" ]] || return 1
    local DEV
    for DEV in /sys/bus/pci/devices/*; do
        local PCIID
        # shellcheck disable=SC2086
        PCIID="$(cat $DEV/vendor) $(cat $DEV/device)"
        debug "  Check found device $DEV $PCIID"
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
    debug "check_cardreader: CARDREADER=$CARDREADER"

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
            warn "Card Reader wasn't found, and you require one for this course (Maybe it isn't plugged in?)"
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
    debug "check_for_vm: NATIVELINUX=$NATIVELINUX VMOKAY=$VMOKAY"

    shopt -s nocasematch
    if [[ -n "$NATIVELINUX" || $VMOKAY == n || $VMOKAY =~ discouraged ]] ; then
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
        debug "  check_for_vm: INVM=$INVM"
        if [[ -n "$INVM" ]] ; then
            [[ $ACTION == warn ]] && WARNINGS=y || FAILED=y
        else
            if [[ $NATIVELINUX =~ recommended || $NATIVELINUX =~ Required ]] ; then
                NLREASON=" which is $NATIVELINUX for this course"
            fi
            pass "You are running Linux natively$NLREASON"
        fi
    fi
}

#===============================================================================
# TEST: Are these symlink patterns satisfied?
check_symlinks() {
    local SYMLINKS=$1
    local ENTRY FILE PAT L
    debug "check_symlinks: SYMLINKS=$SYMLINKS"

    for ENTRY in $SYMLINKS; do
        IFS=: read -r FILE PAT <<<$ENTRY
        if [[ ! -L $FILE ]] ; then
            verbose "$FILE isn't a symlink ($PAT)"
            continue
        fi
        L=$(readlink "$FILE")
        [[ -z $SIMULATE_FAILURE ]] || L+="ERROR"
        debug "FILE=$FILE PAT=$PAT L=$L"
        case $PAT in
            !*) debug "!* FILE=$FILE PAT=$PAT L=$L"
                if [[ ! $L =~ ${PAT#!} ]] ; then
                    verbose "Symlink $FILE isn't $PATH ($L)"
                else
                    fail "Symlink $FILE is $L (${PAT#!})"
                    FAILED=y
                fi ;;
            *) debug "* FILE=$FILE PAT=$PAT L=$L"
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
    debug "check_versions: VERSIONS=$VERSIONS"

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
# Get File from course material site
get_cm_file() {
    local CLASS=${1%/}
    local FILE=$2
    local CMDIR=$3
    local PARTIAL=$4
    debug "get_cm_file CLASS=$CLASS FILE=$FILE CMDIR=$CMDIR PARTIAL=$PARTIAL"

    local URL=$LFCM/$CLASS${FILE:+/$FILE}
    local USERNAME=LFtraining PASSWORD=Penguin2014

    [[ -z $CMDIR ]] || pushd "$CMDIR" >/dev/null
    if [[ -z $USECURL ]] && which wget >/dev/null ; then
        debug "  wget $URL"
        local OPTS
        if [[ -n $FILE ]] ; then
            OPTS="--continue --progress=bar"
        else
            OPTS="--quiet -O -"
        fi
        # shellcheck disable=SC2086
        wget $OPTS "--user=$USERNAME" "--password=$PASSWORD" --timeout=10 "$URL"
    elif which curl >/dev/null ; then
        debug "  curl $URL"
        local OPTS="-s"
        [[ -z $FILE ]] || OPTS="-# -O"
        if [[ $PARTIAL = y ]] ; then
            rm -f "$FILE"
        elif [[ -z $PARTIAL && -f $FILE ]] ; then
            notice "Verifying $FILE... (for curl)"
            tar tf "$FILE" >/dev/null 2>&1 || rm -f "$FILE"
        fi
        # shellcheck disable=SC2086
        [[ -f $FILE ]] || curl --connect-timeout 10 --location --user "$USERNAME:$PASSWORD" $OPTS "$URL"
    else
        warn "No download tool found." >&2
        return 1
    fi
    [[ -z $CMDIR ]] || popd >/dev/null
    return 0
}

#===============================================================================
# Clean course meta variable cache
CMCACHE="$HOME/.cache/${CMDBASE%.sh}"
clean_cm_cache(){
    debug "clean_cm_cache: $CMCACHE"
    rm -rf "$CMCACHE"
}

#===============================================================================
# Get course meta variable (cache lookups)
get_cm_var(){
    local KEY=$1
    local CLASS=${2# }
    debug "get_cm_var: KEY=$KEY CLASS=$CLASS"

    mkdir -p "$CMCACHE"
    local CONF="${CMDBASE%.sh}.conf"
    local FILE="$CMCACHE/$CLASS-$CONF"
    debug "get_cm_var: CONF=$CONF FILE=$FILE"
    if [[ ! -e $FILE ]] ; then
        (get_cm_file "$CLASS/.$CONF" && get_cm_file ".$CLASS-$CONF") >"$FILE"
    fi
    awk -F= '/'"$KEY"'=/ {print $2}' "$FILE" | sed -e 's/^"\(.*\)"$/\1/'
}

#===============================================================================
# Get Course Extras
get_course_file() {
    local COURSE=$1
    debug "get_course_file: COURSE=$COURSE"
    local FILE VER

    # Find newest SOLUTIONS file
    FILE=$(get_cm_file "$COURSE" \
        | awk -F\" '/SOLUTIONS/ {print $8}' \
        | sed -Ee 's/^(.*V)([0-9.]+)(_.*)$/\2.0.0 \1\2\3/' \
        | sort -t. -n -k1,1 -k2,2 -k3,3 \
        | awk 'END {print $2}')
    if [[ -z $FILE ]] ; then
        FILE=$(get_cm_file "$COURSE" \
        | awk -F\" '/SOLUTIONS/ {print $8}' \
        | sort | tail -1)
    fi

    if [[ -n $FILE ]] ; then
        VER=$(sed -re 's/^.*(V[0-9.]+).*$/\1/' <<<$FILE)
        debug "get_course_file: COURSE=$COURSE FILE=$FILE VER=$VER"
        echo "$FILE" "$VER"
    else
        debug "get_course_file: No course materials found for $COURSE"
    fi
}

#===============================================================================
# Get Course Materials
get_course_tarball() {
    local COURSE=$1
    local FILE=$2
    local TODIR=$3
    local PARTIAL=n
    debug "get_course_tarball: COURSE=$COURSE FILE=$FILE TODIR=$TODIR PARTIAL=$PARTIAL"

    [[ -n $FILE ]] || return 0
    verbose "Course Materials: $FILE"
    [[ -d $TODIR ]] || mkdir -p "$TODIR"
    if [[ -f $TODIR/$FILE ]] ; then
        notice "Verifying $FILE..."
        if [[ -n $SIMULATE_FAILURE ]] || ! tar -t -f "$TODIR/$FILE" >/dev/null 2>&1 ; then
            warn_wait "Partial download of $TODIR/$FILE found." || return
            PARTIAL=y
        else
            highlight "$FILE can be found in $TODIR"
            return 0
        fi
    else
        warn_wait "Download course material? ($FILE)" || return
    fi
    highlight "Downloading $FILE to $TODIR"
    get_cm_file "$COURSE" "$FILE" "$TODIR" "$PARTIAL"
}

#===============================================================================
# Get Course Extras (in sub-directories called something like LFD460_V2.0.2)
get_course_extras() {
    local COURSE=$1
    local VER=$2
    local TODIR=$3
    debug "get_course_extras: COURSE=$COURSE VER=$VER TODIR=$TODIR"
    local EXTRA_FILES EXTRA_FILE

    EXTRA_FILES=$(sed -re "s/%COURSE_VERSION%/$VER/" <<<${EXTRAS[$COURSE]})
    if [[ -n $EXTRA_FILES ]] ; then
        verbose "Course Extras: $EXTRA_FILES"
        warn_wait "Download extra materials? ($EXTRA_FILES)" || return
        for EXTRA_FILE in $EXTRA_FILES ; do
            verbose "Consider extra $EXTRA_FILE"
            case $EXTRA_FILE in
                */) mkdir -p "$TODIR/$EXTRA_FILE"
                    local FILES FILE
                    FILES=$(get_cm_file "$COURSE/$EXTRA_FILE" \
                            | awk -F\" '/<td>/ {print $8}')
                    debug "Get files: $FILES"
                    for FILE in $FILES ; do
                        get_cm_file "$COURSE/$EXTRA_FILE" "$FILE" "$TODIR/$EXTRA_FILE"
                    done
                    ;;
                *)  local DIR
                    DIR=$(dirname "$TODIR/$EXTRA_FILE")
                    mkdir -p "$DIR"
                    get_cm_file "$COURSE" "$EXTRA_FILE" "$TODIR" ;;
            esac
        done
    fi
}

#===============================================================================
# Get course materials
get_course_materials() {
    local COURSE=$1
    local TODIR=${CMDIR:-$HOME/LFT}
    debug "get_course_materials: COURSE=$COURSE TODIR=$TODIR"

    local FILE VER
    read -r FILE VER <<< $(get_course_file "$COURSE")
    if [[ -n $FILE ]] ; then
        verbose "Get course materials for $COURSE"
        get_course_tarball "$COURSE" "$FILE" "$TODIR"
        [[ -n $NOEXTRAS ]] || get_course_extras "$COURSE" "$VER" "$TODIR"
    else
        notice "No course materials for $COURSE"
    fi
}


#===============================================================================
# Get all course materials requested
get_all_course_materials() {
    debug "get_all_course_file: $*"
    local CLASS CMS CM COURSES
    for CLASS in "$@"; do
        if CM=$(get_cm_var CM "$CLASS") && [[ -n $CM ]] ; then
            CMS+="$CM "
        elif COURSES=$(get_cm_var COURSES "$CLASS") && [[ -n $COURSES ]] ; then
            CMS+="$COURSES "
        else
            CMS+="$CLASS "
        fi
    done
    debug "Install course materials for: $* as $CMS"
    # shellcheck disable=SC2086
    for_each_course get_course_materials $CMS
}

#===============================================================================
if [[ -n $DETECT_VM ]] ; then
    check_for_vm 0 1
    exit 0
fi

#===============================================================================
# shellcheck disable=SC2005,SC2046,SC2086
[[ -n $ALL_LFD ]] && COURSE=$(echo $(list_grep LFD ${!DESCRIPTION[*]}))
# shellcheck disable=SC2005,SC2046,SC2086
[[ -n $ALL_LFS ]] && COURSE=$(echo $(list_grep LFS ${!DESCRIPTION[*]}))
# shellcheck disable=SC2005,SC2046,SC2086
[[ -n $ALL_COURSES ]] && COURSE=$(echo $(list_sort ${!DESCRIPTION[*]}))
[[ -n $JSON ]] && list_json
[[ -n $LIST_COURSES ]] && list_courses
[[ -n $TRY_ALL_COURSES ]] && try_all_courses

clean_cm_cache

#===============================================================================
ORIG_COURSE=$COURSE
# shellcheck disable=SC2046,SC2086
COURSE=$(list_sort $(for_each_course find_course $COURSE))
debug "main: Initial classes=$COURSE"
if [[ -n $CHECK_PKGS ]] ; then
    debug "Check Packages for $COURSE"
    # shellcheck disable=SC2086
    for_each_course check_packages $COURSE
    exit 0
elif [[ -n $LIST_PKGS ]] ; then
    debug "List Packages for $COURSE => $PKGS"
    # shellcheck disable=SC2086
    for_each_course list_packages $COURSE | sort -k2
    exit 0
elif [[ -n $LIST_REQS ]] ; then
    debug "List Requirements for $COURSE"
    # shellcheck disable=SC2086
    for_each_course list_requirements $COURSE
    exit 0
fi

#===============================================================================
# shellcheck disable=SC2086
IFS=, read -r ID RELEASE CODENAME DESCRIPTION ARCH DARCH <<<"$(guess_distro $DISTRO)"
debug "main: guess_distro split: ID=$ID RELEASE=$RELEASE CODENAME=$CODENAME DESCRIPTION=$DESCRIPTION ARCH=$ARCH DARCH=$DARCH"
[[ -n $LIST_DISTRO ]] && list_distro "$ID" "$ARCH" "$RELEASE" "$CODENAME"
check_root

#===============================================================================
[[ -n $COURSE ]] || usage
debug "main: Final classes: $COURSE"
# shellcheck disable=SC2086
for_each_course setup_meta $COURSE
# shellcheck disable=SC2086
for_each_course check_course $ORIG_COURSE

#===============================================================================
# Check all the things
if [[ -z "$INSTALL" ]] ; then
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
fi

#===============================================================================
# Check package list
if [[ -n $INSTALL || -z $NOINSTALL ]] ; then
    check_sudo "$ID" "$RELEASE"
    check_repos "$ID" "$RELEASE" "$CODENAME" "$ARCH"
    # shellcheck disable=SC2086
    PKGLIST=$(for_each_course "package_list $ID $RELEASE" $COURSE)
    # shellcheck disable=SC2086
    try_packages "$ID" "$RELEASE" "$COURSE" $PKGLIST
else
    notice "Not checking whether the appropriate packages are being installed"
fi

#===============================================================================
# Overall PASS/FAIL
echo
if [[ -n "$FAILED" ]] ; then
    warn "You will likely have troubles using this computer with this course. Ask your instructor."
elif [[ -n "$WARNINGS" ]] ; then
    warn "You may have troubles using this computer for this course unless you can fix the above warnings."
    warn "Ask your instructor."
elif [[ -n "$MISSING_PACKAGES" ]] ; then
    warn "You have some missing packages. Instructions to install them are just above this."
    warn "If not, ask your instructor about this on the day of the course."
else
    pass "You are ready for the course! W00t!"
fi

#===============================================================================
if [[ -z $INSTALL && -z $NOCM ]] ; then
    echo
    # shellcheck disable=SC2086
    get_all_course_materials $ORIG_COURSE
fi

clean_cm_cache

exit 0
