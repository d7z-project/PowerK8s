Name:           containerd
Version:        1.6.16
Release:        1%{?dist}
Summary:        An industry-standard container runtime with an emphasis on simplicity, robustness and portability

License:        Apache-2.0
URL:            https://github.com/containerd/containerd/
Source0:        https://github.com/containerd/containerd/archive/refs/tags/v%{version}.tar.gz
Source1:        containerd.service
Source2:        containerd.toml
Source3:        crictl.yaml
Source4:        modprobe.conf
Source5:        sysctl.conf

BuildRequires:  golang make gcc libseccomp-devel btrfs-progs-devel
Requires:       libseccomp cni-plugins runc
Provides:       oci-rumtime = 1.0.0-1%{?dist}


%description
containerd is an industry-standard container runtime with an emphasis on simplicity,
robustness, and portability. It is available as a daemon for Linux and Windows,
 which can manage the complete container lifecycle of
 its host system: image transfer and storage, container execution and supervision, low-level storage and network attachments, etc.


%prep
%setup -q


%build
make %{?_smp_mflags}


%install
%{__mkdir_p} %{buildroot}%{_defaultlicensedir}/%{name}-%{version} %{buildroot}%{_unitdir} %{buildroot}/etc/containerd %{buildroot}/etc
%{__mkdir_p} %{buildroot}/etc/modules-load.d %{buildroot}/etc/sysctl.d/
%make_install
%{__install} -m0644 LICENSE %{buildroot}%{_defaultlicensedir}/%{name}-%{version}/COPYING
%{__install} -m 0644 %{SOURCE1} %{buildroot}%{_unitdir}
%{__install} -m 0644 %{SOURCE2} %{buildroot}/etc/containerd/config.toml
%{__install} -m 0644 %{SOURCE3} %{buildroot}/etc/crictl.yaml
%{__install} -m 0644 %{SOURCE4} %{buildroot}/etc/modules-load.d/containerd.conf
%{__install} -m 0644 %{SOURCE5} %{buildroot}/etc/sysctl.d/zz-containerd.conf

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
/etc/modules-load.d/containerd.conf
/etc/sysctl.d/zz-containerd.conf

%license %{_defaultlicensedir}/%{name}-%{version}/COPYING


%post
sysctl --system >/dev/null 2>&1 ||:
systemctl daemon-reload >/dev/null 2>&1 ||:
systemctl enable --now containerd ||:

%preun
case $1 in
  0)
  systemctl disable --now containerd >/dev/null 2>&1 ||:
  ;;
esac

%changelog
* Wed Feb 8 2023 Dragon
- 初始化项目
