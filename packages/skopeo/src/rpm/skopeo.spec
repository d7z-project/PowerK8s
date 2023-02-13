Name:           skopeo
Version:        1.11.0
Release:        1%{?dist}
Summary:         a command line utility that performs various operations on container images and image repositories.

License:        Apache-2.0
URL:            https://github.com/containers/skopeo
Source0:        https://github.com/containers/skopeo/archive/refs/tags/v%{version}.tar.gz

BuildRequires:  golang gcc

%description
skopeo is a command line utility that performs various operations on container images and image repositories.

%prep
%setup -q


%build
DISABLE_DOCS=1 make %{?_smp_mflags} VERSION=%{version} bin/skopeo BUILDTAGS=containers_image_openpgp GO_DYN_FLAGS= CGO_ENABLED=0


%install
%{__mkdir_p} %{buildroot}%{_bindir} %{buildroot}/%{_defaultlicensedir}/%{name}-%{version} %{buildroot}/usr/share/bash-completion/completions
%{__install} -m 0755 bin/skopeo  %{buildroot}/%{_bindir}/skopeo
%{__install} -m 0644 LICENSE %{buildroot}/%{_defaultlicensedir}/%{name}-%{version}/COPYING
%{buildroot}/%{_bindir}/skopeo completion bash | tee %{buildroot}/usr/share/bash-completion/completions/skopeo > /dev/null

%files
%license %{_defaultlicensedir}/%{name}-%{version}/COPYING
/usr/share/bash-completion/completions/skopeo
%{_bindir}/skopeo


%changelog
* Wed Oct 26 2022 Dragon
- 初始化项目
