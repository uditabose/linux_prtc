Summary: A program that does something
Name: myapprpm
Version: 1.0.0
Release: 1
License: GPLv2
Group: Applications/System
Source: myapprpm-1.0.0.tar.gz
#Patch: myapprpm-1.0.0.patch
#BuildRoot: 
BuildRoot: /var/tmp/myapprpm-buildroot

%description
This program does something
very cool.

%prep
%setup -q
%autosetup
#%patch -p1
%build
make RPM_OPT_FLAGS="$RPM_OPT_FLAGS"

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/local/bin
#mkdir -p $RPM_BUILD_ROOT/usr/local/man/man1

install -s -m 755 myhello $RPM_BUILD_ROOT/usr/local/bin/myhello
#install -m 644 myhello.1 $RPM_BUILD_ROOT/usr/local/man/man1/myhello.1

%clean
rm -rf $RPM_BUILD_ROOT
%files
%defattr(-,root,root)
%doc README

/usr/local/bin/myhello
#/usr/local/man/man1/myhello.1

%changelog
* Fri Jul 02 2010 There were some changes two
* Tue Feb 08 2011 There were some changes one
