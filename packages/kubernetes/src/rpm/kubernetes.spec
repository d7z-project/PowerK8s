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
BuildRequires:  golang gcc automake autoconf libtool make rsync

%description
an open source system for managing containerized
 applications across multiple hosts.
 It provides basic mechanisms for deployment,
  maintenance, and scaling of applications


%prep
%setup -q -D


%build
test -f "_output/local/go/bin/kubelet" || %{__make}  WHAT=cmd/kubelet
test -f "_output/local/go/bin/kubeadm" || %{__make}  WHAT=cmd/kubeadm
test -f "_output/local/go/bin/kubectl" || %{__make}  WHAT=cmd/kubectl


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
Requires: socat util-linux ethtool ebtables  conntrack iptables oci-runtime crictl
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
- 初始化项目
