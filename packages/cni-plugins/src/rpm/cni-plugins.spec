Name:           cni-plugins
Version:        1.2.0
Release:        1%{?dist}
Summary:        Some CNI network plugins, maintained by the containernetworking team

License:        Apache-2.0
URL:            https://github.com/containernetworking/plugins
Source0:        https://github.com/containernetworking/plugins/archive/refs/tags/v%{version}.tar.gz

BuildRequires:  golang make

%description
Some CNI network plugins, maintained by the containernetworking team.
 For more information, see the CNI website : https://www.cni.dev/

%prep
%setup -q -n plugins-%{version}


%build
rm -rf bin
bash -x ./build_linux.sh -ldflags '-extldflags -static -X github.com/containernetworking/plugins/pkg/utils/buildversion.BuildVersion=%{version}'

%install
%{__mkdir_p} %{buildroot}/opt/cni/bin %{buildroot}%{_defaultlicensedir}/%{name}-%{version}
%{__install} -m0755 bin/{bandwidth,bridge,dhcp,dummy,firewall,host-device,host-local,ipvlan,loopback,macvlan,portmap,ptp,sbr,static,tuning,vlan,vrf} %{buildroot}/opt/cni/bin
%{__install} -m0644 LICENSE %{buildroot}%{_defaultlicensedir}/%{name}-%{version}/COPYING

%files
/opt/cni/bin
%license %{_defaultlicensedir}/%{name}-%{version}/COPYING



%changelog
* Wed Feb 8 2023 Dragon
- 初始化项目
