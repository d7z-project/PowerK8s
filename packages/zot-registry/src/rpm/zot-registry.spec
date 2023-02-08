Name:           zot-registry
Version:        1.4.3
Release:        1%{?dist}
Summary:         OCI-native container image registry, simplified

License:        Apache-2.0
URL:            https://github.com/project-zot/zot
Source0:        https://github.com/project-zot/zot/archive/refs/tags/v%{version}.tar.gz

BuildRequires:  golang

%if "%{_arch}" == "x86_64"
   %global  _arch amd64
%else
   %global  _arch arm64
%endif

%description
production-ready vendor-neutral OCI image registry -
 images stored in OCI image format, distribution specification on-the-wire, that's it!

%prep
%setup -q -n zot-%{version}


%build
make %{?_smp_mflags} binary


%install
%{__mkdir_p} %{buildroot}/%{_bindir} %{buildroot}%{_defaultlicensedir}/%{name}-%{version}
%{__install} -m 0755 bin/zot-linux-%{_arch} %{buildroot}/%{_bindir}/registry-zot
%{__install} -m0644 LICENSE %{buildroot}%{_defaultlicensedir}/%{name}-%{version}/COPYING


%files
/%{_bindir}/registry-zot
%license %{_defaultlicensedir}/%{name}-%{version}/COPYING

%changelog
* Wed Feb 8 2023 Dragon
- 初始化项目
