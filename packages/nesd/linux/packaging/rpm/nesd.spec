Name: nesd
Version: 0.13.0
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
mkdir -p %{buildroot}%{_datadir}/applications
mkdir -p %{buildroot}%{_datadir}/metainfo
mkdir -p %{buildroot}%{_datadir}/pixmaps
cp -r %{name}/* %{buildroot}%{_datadir}/%{name}
ln -s ../share/%{name}/%{name} %{buildroot}%{_bindir}/%{name}
cp -r %{name}.desktop %{buildroot}%{_datadir}/applications
cp -r dev.jpj.NESd.svg %{buildroot}%{_datadir}/pixmaps
cp -r %{name}.metainfo.xml %{buildroot}%{_datadir}/metainfo || :
update-mime-database %{_datadir}/mime &> /dev/null || :

%postun
update-mime-database %{_datadir}/mime &> /dev/null || :

%files
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications
%{_datadir}/metainfo


%defattr(-,root,root)
%attr(4755, root, root) %{_datadir}/pixmaps/dev.jpj.NESd.svg
