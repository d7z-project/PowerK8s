Name:           nerdctl
Version:        1.2.0
Release:        1%{?dist}
Summary:        Docker-compatible CLI for containerd

License:        Apache-2.0
URL:            https://github.com/containerd/nerdctl
Source0:        https://github.com/containerd/nerdctl/archive/5aee2f754a2f46d4c8ccbae25d56b43668ac4b62.tar.gz

BuildRequires:  golang make libseccomp-devel
Requires:       containerd

%description
nerdctl is a Docker-compatible CLI for containerd.


%prep
%setup -q -n nerdctl-5aee2f754a2f46d4c8ccbae25d56b43668ac4b62

%build
make %{?_smp_mflags}


%install
%{__mkdir_p} %{buildroot}%{_defaultlicensedir}/%{name}-%{version}
%make_install
%{__install} -m0644 LICENSE %{buildroot}%{_defaultlicensedir}/%{name}-%{version}/COPYING


%files
/usr/local/bin/nerdctl
/usr/local/bin/containerd-rootless.sh
/usr/local/bin/containerd-rootless-setuptool.sh
%license %{_defaultlicensedir}/%{name}-%{version}/COPYING

%changelog
* Wed Feb 8 2023 Dragon
- 初始化项目
