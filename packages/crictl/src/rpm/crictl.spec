Name:           crictl
Version:        1.26.0
Release:        1%{?dist}
Summary:        CLI and validation tools for Kubelet Container Runtime Interface (CRI) .

License:        Apache-2.0
URL:            https://github.com/kubernetes-sigs/cri-tools
Source0:        https://github.com/kubernetes-sigs/cri-tools/archive/refs/tags/v%{version}.tar.gz

BuildRequires:  golang make libseccomp-devel
Requires:       libseccomp
Requires:       oci-rumtime >= 1.0.0-1%{?dist}

%description
CLI and validation tools for Kubelet Container Runtime Interface (CRI) .

%prep
%setup -q -n cri-tools-%{version}


%build
make %{?_smp_mflags} VERSION=%{version}


%install
%{__mkdir_p} %{buildroot}%{_defaultlicensedir}/%{name}-%{version}
%make_install
%{__install} -m0644 LICENSE %{buildroot}%{_defaultlicensedir}/%{name}-%{version}/COPYING


%files
/usr/local/bin/crictl
/usr/local/bin/critest
%license %{_defaultlicensedir}/%{name}-%{version}/COPYING

%changelog
* Wed Feb 8 2023 Dragon
- 初始化项目
