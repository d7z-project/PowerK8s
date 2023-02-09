Name:           runc
Version:        1.1.4
Release:        1%{?dist}
Summary:        a CLI tool for spawning and running containers on Linux according to the OCI specification.

License:        Apache-2.0
URL:            https://github.com/opencontainers/runc
Source0:        https://github.com/opencontainers/runc/archive/refs/tags/v%{version}.tar.gz

BuildRequires:  golang make libseccomp-devel
Requires:       libseccomp

%description
runc is a CLI tool for spawning and running containers on Linux according to the OCI specification.

%prep
%setup -q


%build
make %{?_smp_mflags} VERSION=%{version}


%install
%{__mkdir_p} %{buildroot}%{_defaultlicensedir}/%{name}-%{version}
%make_install
%{__install} -m0644 LICENSE %{buildroot}%{_defaultlicensedir}/%{name}-%{version}/COPYING


%files
/usr/local/sbin/runc
%license %{_defaultlicensedir}/%{name}-%{version}/COPYING

%changelog
* Wed Feb 8 2023 Dragon
- 初始化项目
