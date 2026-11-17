%global debug_package %{nil}

Name:           focuswave-decoration
Version:        1.0.0
Release:        1%{?dist}
Summary:        FocusWave window decoration with macOS-style traffic light buttons
License:        GPL-3.0-or-later
URL:            https://github.com/focuswave/focuswave
Source0:        focuswave-%{version}.tar.gz

BuildRequires:  cmake
BuildRequires:  gcc-c++
BuildRequires:  extra-cmake-modules
BuildRequires:  qt6-qtbase-devel
BuildRequires:  kdecoration-devel
BuildRequires:  kf6-kcoreaddons-devel

Requires:       kwin

%description
A light window decoration for KDE Plasma: rounded corners, a soft shadow and
red/yellow/green buttons that show their symbols when you hover them.

%prep
%autosetup -n focuswave-%{version}

%build
%set_build_flags
cmake -S src/decoration -B build-decoration \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=%{_prefix}
cmake --build build-decoration %{?_smp_mflags}

%install
DESTDIR=%{buildroot} cmake --install build-decoration

%files
%{_libdir}/qt6/plugins/org.kde.kdecoration3/org.focuswave.decoration.so

%changelog
* Mon Nov 16 2026 FocusWave <focuswave@localhost> - 1.0.0-1
- First release
