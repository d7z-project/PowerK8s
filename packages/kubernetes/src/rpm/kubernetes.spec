Name:           kubernetes
Version:        1.25.6
Release:        1%{?dist}
Summary:        an open source system for managing containerized applications across multiple hosts.

License:        Apache-2.0
URL:            https://github.com/kubernetes/kubernetes
Source0:        https://github.com/kubernetes/kubernetes/archive/refs/tags/v%{version}.tar.gz
Source1:        sysctl.conf
Source2:        kubelet.service
Source3:        10-kubeadm.conf
Source4:        modprobe.conf
Patch0:         00-replace-cert-to-100.patch
Patch1:         01-replace-default-registry.patch
Patch2:         02-replace-remote-update-url.patch
Patch3:         03-add-default-config-path.patch

BuildRequires:  golang gcc automake autoconf libtool make rsync

%description
an open source system for managing containerized
 applications across multiple hosts.
 It provides basic mechanisms for deployment,
  maintenance, and scaling of applications

%prep
%setup -q
patch -p1 < %{PATCH0}
patch -p1 < %{PATCH1}
patch -p1 < %{PATCH2}
patch -p1 < %{PATCH3}

%build
 %{__make}  WHAT=cmd/kubelet VERSION=%{version}
 %{__make}  WHAT=cmd/kubeadm VERSION=%{version}
 %{__make}  WHAT=cmd/kubectl VERSION=%{version}

%install
%{__mkdir_p} %{buildroot}%{_defaultlicensedir}/%{name}-%{version} %{buildroot}%{_unitdir}  %{buildroot}/etc
%{__mkdir_p} %{buildroot}%{_bindir} %{buildroot}/usr/share/bash-completion/completions
%{__mkdir_p} %{buildroot}/etc/kubernetes/manifests %{buildroot}/etc/sysctl.d %{buildroot}/etc/systemd/system/kubelet.service.d/
%{__mkdir_p} %{buildroot}/etc/modules-load.d

%{__install} -m 0755 _output/local/go/bin/kubelet %{buildroot}%{_bindir}/kubelet
%{__install} -m 0755 _output/local/go/bin/kubeadm %{buildroot}%{_bindir}/kubeadm
%{__install} -m 0755 _output/local/go/bin/kubectl %{buildroot}%{_bindir}/kubectl
%{buildroot}%{_bindir}/kubeadm completion bash | tee %{buildroot}/usr/share/bash-completion/completions/kubeadm >/dev/null
%{buildroot}%{_bindir}/kubectl completion bash | tee %{buildroot}/usr/share/bash-completion/completions/kubectl >/dev/null
%{__install} -m 0644 %{SOURCE1} %{buildroot}/etc/sysctl.d/zz-kubernetes.conf
%{__install} -m 0644 %{SOURCE2} %{buildroot}%{_unitdir}/kubelet.service
%{__install} -m 0644 %{SOURCE3} %{buildroot}/etc/systemd/system/kubelet.service.d/10-kubeadm.conf
%{__install} -m 0644 %{SOURCE4} %{buildroot}/etc/modules-load.d/kubernetes.conf


%package kubelet
Requires: socat util-linux ethtool ebtables  conntrack iptables crictl
Requires: oci-rumtime >= 1.0.0-1%{?dist}
Summary:  An agent that runs on each node in a Kubernetes cluster making sure that containers are running in a Pod.

%description kubelet
An agent that runs on each node in a Kubernetes cluster making sure that containers are running in a Pod.

%files kubelet
%{_bindir}/kubelet
%{_unitdir}/kubelet.service
%config(noreplace) /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
/etc/modules-load.d/kubernetes.conf
/etc/sysctl.d/zz-kubernetes.conf
%config(noreplace) /etc/kubernetes/manifests

%post kubelet
sysctl --system >/dev/null 2>&1 ||:
systemctl daemon-reload >/dev/null 2>&1 ||:
systemctl enable --now kubelet ||:


%package kubeadm
Requires: kubernetes-kubelet = %{version}-%{release}
Summary:  An agent that runs on each node in a Kubernetes cluster making sure that containers are running in a Pod.

%description kubeadm
An agent that runs on each node in a Kubernetes cluster making sure that containers are running in a Pod.

%files kubeadm
%{_bindir}/kubeadm
/usr/share/bash-completion/completions/kubeadm


%package kubectl
Summary:  An agent that runs on each node in a Kubernetes cluster making sure that containers are running in a Pod.

%description kubectl
An agent that runs on each node in a Kubernetes cluster making sure that containers are running in a Pod.


%files kubectl
%{_bindir}/kubectl
/usr/share/bash-completion/completions/kubectl


%files

%changelog
* Wed Feb 8 2023 Dragon
- 初始化项目 使用 1.25.6
