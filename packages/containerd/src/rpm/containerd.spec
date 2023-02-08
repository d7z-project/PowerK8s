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

BuildRequires:  golang make libseccomp-devel btrfs-progs-devel
Requires:       libseccomp

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
%make_install
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

%preun
case $1 in
  0)
  systemctl disable --now containerd >/dev/null 2>&1 ||:
  ;;
esac
%changelog
* Wed Feb 8 2023 Dragon
- 初始化项目
