%global debug_package %{nil}

Name:           focuswave-desktop
Version:        1.0.0
Release:        1%{?dist}
Summary:        FocusWave: a sleek, simple and very customizable KDE Plasma desktop with Focus Mode
License:        GPL-3.0-or-later AND CC-BY-SA-4.0
URL:            https://github.com/focuswave/focuswave
Source0:        focuswave-%{version}.tar.gz

BuildRequires:  cmake
BuildRequires:  gcc-c++
BuildRequires:  qt6-qtbase-devel
BuildRequires:  kf6-kwindowsystem-devel
BuildRequires:  kf6-kconfig-devel
BuildRequires:  python3
BuildRequires:  systemd-rpm-macros

Requires:       plasma-workspace
Requires:       kwin
Requires:       kf6-kconfig
Requires:       kf6-kirigami
Requires:       kf6-qqc2-desktop-style
Requires:       python3
Requires:       python3-pyside6
Requires:       systemd
Recommends:     focuswave-decoration
Recommends:     papirus-icon-theme
Recommends:     rsms-inter-fonts
Recommends:     jetbrains-mono-fonts-all
Recommends:     thermald

%description
FocusWave turns Fedora KDE Plasma into a slick desktop that mixes the best of
Windows and macOS: a slim top bar, a floating dock, light/dark/automatic modes,
accent colors, wallpapers that follow dark mode, a Customize app with live
previews and saved themes, and Focus Mode, which blurs everything except the
window you're working in.

%prep
%autosetup -n focuswave-%{version}

%build
%set_build_flags
cmake -S src/focus-overlay -B build-overlay \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=%{_prefix} \
    -DCMAKE_INSTALL_LIBDIR=%{_lib}
cmake --build build-overlay %{?_smp_mflags}

%install
DESTDIR=%{buildroot} cmake --install build-overlay
bash tools/install-files.sh %{buildroot}

%files
%license LICENSE
%doc README.md
%{_bindir}/focuswave-customize
%{_bindir}/focuswave-theme
%{_bindir}/focuswave-focus-overlay
%{_datadir}/focuswave/
%{_datadir}/kwin/scripts/focuswave-focus/
%{_datadir}/plasma/plasmoids/org.focuswave.focustoggle/
%{_datadir}/plasma/look-and-feel/org.focuswave.desktop/
%{_datadir}/color-schemes/FocusWaveLight.colors
%{_datadir}/color-schemes/FocusWaveDark.colors
%{_datadir}/wallpapers/FocusWave-Wave/
%{_datadir}/wallpapers/FocusWave-Aurora/
%{_datadir}/wallpapers/FocusWave-Dune/
%{_datadir}/icons/hicolor/scalable/apps/focuswave-*.svg
%{_datadir}/applications/org.focuswave.Customize.desktop
%{_datadir}/dbus-1/services/org.focuswave.FocusMode.service
%{_userunitdir}/focuswave-auto-theme.service
%{_userunitdir}/focuswave-auto-theme.timer
%{_userunitdir}/timers.target.wants/focuswave-auto-theme.timer
%config(noreplace) %{_sysconfdir}/xdg/autostart/org.focuswave.Welcome.desktop
%config(noreplace) %{_sysconfdir}/xdg/autostart/org.focuswave.Session.desktop
%config(noreplace) %{_sysconfdir}/xdg/plasma-workspace/env/focuswave.sh

%changelog
* Mon Nov 16 2026 FocusWave <focuswave@localhost> - 1.0.0-1
- First release
