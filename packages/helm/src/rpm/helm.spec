Name:           helm
Version:        3.11.0
Release:        1%{?dist}
Summary:        a tool for managing Charts. Charts are packages of pre-configured Kubernetes resources.

License:        Apache-2.0
URL:            https://github.com/helm/helm
Source0:        https://github.com/helm/helm/archive/refs/tags/v3.11.0.tar.gz

BuildRequires:  golang
Requires:       kubernetes-kubectl

%description
Helm is a tool for managing Charts. Charts are packages of pre-configured Kubernetes resources.

%prep
%setup -q


%build
make %{?_smp_mflags} VERSION=%{version}


%install
%make_install
%{__mkdir_p} %{buildroot}%{_bindir} %{buildroot}/%{_defaultlicensedir}/%{name}-%{version} %{buildroot}/usr/share/bash-completion/completions
%{__install} -m 0755 bin/helm  %{buildroot}/%{_bindir}/helm
%{__install} -m 0644 LICENSE %{buildroot}/%{_defaultlicensedir}/%{name}-%{version}/COPYING
%{_bindir}/helmhelm completion bash | tee %{buildroot}/usr/share/bash-completion/completions/helm > /dev/null
%{__ln_s} %{_bindir}/helm %{buildroot}%{_bindir}/kubectl-helm

%files
%license %{_defaultlicensedir}/%{name}-%{version}/COPYING
/usr/share/bash-completion/completions/helm
%{_bindir}/helm
%{_bindir}/kubectl-helm


%changelog
* Wed Oct 26 2022 Dragon
- 初始化项目
