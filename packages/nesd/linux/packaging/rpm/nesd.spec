Name: %{name_}
Version: %{version_}
Release: 1%{?dist}
Summary: NES emulator
Group: Games/Emulators
Vendor: John Paul Jonte
Packager: John Paul Jonte <nesd@jpj.dev>
License: MIT
URL: https://github.com/jpjonte/NESd
ExclusiveArch: %{arch_}

%description
%{summary}

%prep

%build

%install
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_datadir}/%{name}
cp -r bundle/* %{buildroot}%{_datadir}/%{name}
ln -s ../share/%{name}/nesd %{buildroot}%{_bindir}/%{name}
cp -r share/* %{buildroot}%{_datadir}

%files
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/*.desktop
%{_datadir}/metainfo/*.metainfo.xml
%{_datadir}/icons/hicolor/scalable/apps/*.svg
