Name:           containerd
Version:        1.6.16
Release:        3%{?dist}
Summary:        An industry-standard container runtime with an emphasis on simplicity, robustness and portability

License:        Apache-2.0
URL:            https://github.com/containerd/containerd/
Source0:        https://github.com/containerd/containerd/archive/refs/tags/v%{version}.tar.gz
Source1:        containerd.service
# el9 才支持 cgroup v2
%if %{?rhel} < 9
Source2:        containerd-v1.toml
%else
Source2:        containerd-v2.toml
%endif
Source3:        crictl.yaml
Patch0:         00-replace-images-registry.patch

BuildRequires:  golang make gcc libseccomp-devel
Requires:       libseccomp runc
Provides:       oci-rumtime = 1.0.0-1%{?dist}


%description
containerd is an industry-standard container runtime with an emphasis on simplicity,
robustness, and portability. It is available as a daemon for Linux and Windows,
 which can manage the complete container lifecycle of
 its host system: image transfer and storage, container execution and supervision, low-level storage and network attachments, etc.


%prep
%setup -q
patch -p1 < %{PATCH0}

%build
make %{?_smp_mflags} VERSION=%{version} REVISION=%{release} BUILDTAGS=no_btrfs


%install
%{__mkdir_p} %{buildroot}%{_defaultlicensedir}/%{name}-%{version} %{buildroot}%{_unitdir} %{buildroot}/etc/containerd %{buildroot}/etc
%{__mkdir_p} %{buildroot}/etc/modules-load.d %{buildroot}/etc/sysctl.d/
%make_install VERSION=%{version} REVISION=%{release}
%{__install} -m0644 LICENSE %{buildroot}%{_defaultlicensedir}/%{name}-%{version}/COPYING
%{__install} -m 0644 %{SOURCE1} %{buildroot}%{_unitdir}
%{__install} -m 0644 %{SOURCE2} %{buildroot}/etc/containerd/config.toml
%{__install} -m 0644 %{SOURCE3} %{buildroot}/etc/crictl.yaml

%files
/usr/local/bin/ctr
/usr/local/bin/containerd-stress
/usr/local/bin/containerd-shim-runc-v2
/usr/local/bin/containerd-shim-runc-v1
/usr/local/bin/containerd-shim
/usr/local/bin/containerd
%{_unitdir}/containerd.service
/etc/containerd/config.toml
/etc/crictl.yaml

%license %{_defaultlicensedir}/%{name}-%{version}/COPYING


%post
systemctl daemon-reload >/dev/null 2>&1 ||:
systemctl enable --now containerd ||:
case $1 in
  1)
  systemctl restart containerd >/dev/null 2>&1 ||:
  ;;
esac

%preun
case $1 in
  0)
  systemctl disable --now containerd >/dev/null 2>&1 ||:
  ;;
esac

%changelog
* Fri Feb 10 2023 Dragon
- 替换默认 docker.io 到 boot.powerk8s.cn


* Wed Feb 8 2023 Dragon
- 初始化项目
