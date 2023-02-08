%if "%{_arch}" == "x86_64"
   %global  _arch amd64
%else
   %global  _arch arm64
%endif

Name:           yq
Version:        4.30.8
Release:        1%{?dist}
Summary:        a lightweight and portable command-line YAML, JSON and XML processor.

License:        MIT
URL:            https://github.com/mikefarah/yq
Source0:        https://github.com/mikefarah/yq/archive/refs/tags/v%{version}.tar.gz
BuildRequires:  golang

%description
a lightweight and portable command-line YAML, JSON and XML processor.
yq uses jq like syntax but works with yaml files as well as json, xml, properties,
csv and tsv. It doesn't yet support everything jq does
- but it does support the most common operations and
 functions, and more is being added continuously.

%prep
%{__mkdir_p} %{_builddir}
%{__tar} zxf %{SOURCE0}

%build
cd %{_builddir}/yq-%{version}
LDFLAGS="-X main.GitDescribe=%{version}" go build

%install
%{__mkdir_p} %{buildroot}%{_bindir} %{buildroot}%{_defaultlicensedir}/%{name}-%{version}
%{__install} -m 0755 %{_builddir}/yq-%{version}/yq %{buildroot}%{_bindir}/yq
%{__install} -m 066 %{_builddir}/yq-%{version}/LICENSE %{buildroot}%{_defaultlicensedir}/%{name}-%{version}/COPYING

%files
%license %{_defaultlicensedir}/%{name}-%{version}/COPYING
%{_bindir}/yq



%changelog
* Wed Oct 26 2022 Dragon
- 初始化项目
