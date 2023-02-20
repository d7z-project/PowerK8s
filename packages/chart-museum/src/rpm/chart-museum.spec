Name:           chart-museum
Version:        0.15.0
Release:        1%{?dist}
Summary:         an open-source Helm Chart Repository server written in Go (Golang),

License:        Apache-2.0
URL:            https://github.com/helm/chartmuseum
Source0:        https://github.com/helm/chartmuseum/archive/refs/tags/v%{version}.tar.gz
Source1:        chart-museum.service
Source2:        chart-museum.yaml

BuildRequires:  golang

%define         run_user chartmuseum
%define         run_group chartmuseum

%if "%{_arch}" == "x86_64"
   %global  _arch amd64
%else
   %global  _arch arm64
%endif


%description
ChartMuseum is an open-source Helm Chart Repository server written in Go (Golang),
with support for cloud storage backends, including Google Cloud Storage, Amazon S3,
 Microsoft Azure Blob Storage, Alibaba Cloud OSS Storage, Openstack Object Storage,
  Oracle Cloud Infrastructure Object Storage, Baidu Cloud BOS Storage,
   Tencent Cloud Object Storage, DigitalOcean Spaces, Minio, and etcd.

%prep
%setup -q -n chartmuseum-%{version}


%build
%__make build-linux REVISION=%{release} VERSION=%{version} BINNAME=%{name}

%install
%{__mkdir_p} %{buildroot}%{_bindir} %{buildroot}%{_defaultlicensedir}/%{name}-%{version}
%{__mkdir_p} %{buildroot}%{_unitdir} %{buildroot}/etc/%{name}
%{__install} -m0644 LICENSE %{buildroot}%{_defaultlicensedir}/%{name}-%{version}/COPYING
%{__install} -m0755 bin/linux/%{_arch}/chartmuseum %{buildroot}%{_bindir}/%{name}
%{__install} -m0644 %{SOURCE1} %{buildroot}%{_unitdir}/%{name}.service
%{__install} -m0644 %{SOURCE2} %{buildroot}/etc/%{name}/%{name}.yaml
%{__sed} -i \
    -e 's|{_user_}|%{run_user}|g' \
    -e 's|{_group_}|%{run_group}|g' \
    -e 's|{_name_}|%{name}|g' \
    -e 's|{_path_}|%{_bindir}/%{name}|g' \
    %{buildroot}/etc/%{name}/%{name}.yaml
%{__sed} -i \
    -e 's|{_user_}|%{run_user}|g' \
    -e 's|{_group_}|%{run_group}|g' \
    -e 's|{_name_}|%{name}|g' \
    -e 's|{_path_}|%{_bindir}/%{name}|g' \
    %{buildroot}%{_unitdir}/%{name}.service


%files
%license %{_defaultlicensedir}/%{name}-%{version}/COPYING
%{_bindir}/%{name}
%{_unitdir}/%{name}.service
%attr(0755, %{run_user}, %{run_group}) /etc/%{name}
%config(noreplace) /etc/%{name}/%{name}.yaml

%pre
getent group %{run_group} >/dev/null || groupadd -r %{run_group}
getent passwd %{run_user} >/dev/null || \
    useradd -r -g %{run_group} -m -d /var/lib/%{run_user} -s /sbin/nologin \
    -c "Chart Museum User" %{run_user}


%post
systemctl daemon-reload >/dev/null 2>&1 ||:

%preun
case $1 in
  0)
  systemctl disable --now %{name} >/dev/null 2>&1 ||:
  ;;
esac


%changelog
* Wed Feb 8 2023 Dragon
- 初始化项目
