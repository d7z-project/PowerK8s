Name:           oci-utils
Version:        1.0.0
Release:        1%{?dist}
Summary:        PowerK8s OCI Manager

License:        Apache-2.0
URL:            https://github.com/d7z-project/PowerK8s
Source0:        oci.sh
Source1:        oci-image.sh
BuildArch:      noarch
Requires:       skopeo

%description
PowerK8s TLS Manager

%install
%{__mkdir_p} %{buildroot}/%{_bindir}
%{__install} -m0755 %{SOURCE0} %{buildroot}/%{_bindir}/oci
%{__install} -m0755 %{SOURCE1} %{buildroot}/%{_bindir}/oci-image

%files
%{_bindir}/oci
%{_bindir}/oci-image


%changelog
* Wed Feb 8 2023 Dragon
- 初始化项目
