Name:           calico-operator
Version:        1.28.5
Release:        1%{?dist}
Summary:        Calico Operator

License:         Apache-2.0
URL:             https://github.com/tigera/operator
Source0:         https://github.com/tigera/operator/archive/refs/tags/v%{version}.tar.gz
Patch0:          01-replace-images.patch
BuildRequires:   golang

%description
This repository contains a Kubernetes operator which manages the lifecycle of a
 Calico or Calico Enterprise installation on Kubernetes or OpenShift. Its goal is
 to make installation, upgrades, and ongoing lifecycle management of Calico and Calico Enterprise as simple and reliable as possible.

%prep
%setup -q -n operator-%{version}
patch -p1 < %{PATCH0}

%build
GO_CGO=1 go build -v -o build/_output/bin/operator -ldflags "-X github.com/tigera/operator/version.VERSION=v%{version} -w" ./main.go


%install
%{__mkdir_p} %{buildroot}%{_defaultlicensedir}/%{name}-%{version} %{buildroot}%{_bindir}
%{__install} -m0644 LICENSE %{buildroot}%{_defaultlicensedir}/%{name}-%{version}/COPYING
%{__install} -m0755 build/_output/bin/operator %{buildroot}%{_bindir}/operator


%files
%license %{_defaultlicensedir}/%{name}-%{version}/COPYING
%{_bindir}/operator


%changelog
* Wed Feb 8 2023 Dragon
- 初始化项目
