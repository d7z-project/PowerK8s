Name:           powerk8s-tls
Version:        1.0.1
Release:        3%{?dist}
Summary:        PowerK8s TLS Manager

License:        Apache-2.0
URL:            https://github.com/d7z-project/PowerK8s
Source0:        powerk8s-tls.sh
BuildArch:      noarch
Requires:       httpd-tools openssl ca-certificates

%description
PowerK8s TLS Manager

%install
%{__mkdir_p} %{buildroot}/%{_bindir}
%{__install} -m0755 %{SOURCE0} %{buildroot}/%{_bindir}/powerk8s-tls

%files
%{_bindir}/powerk8s-tls



%changelog
* Wed Feb 8 2023 Dragon
- 初始化项目
