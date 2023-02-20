Name:           zot
Version:        1.4.3
Release:        2%{?dist}
Summary:         OCI-native container image registry, simplified

License:        Apache-2.0
URL:            https://github.com/project-zot/zot
Source0:        https://github.com/project-zot/zot/archive/refs/tags/v%{version}.tar.gz
Source1:        zot.service
Source2:        config.json

BuildRequires:  golang make httpd-tools

%if "%{_arch}" == "x86_64"
   %global  _arch amd64
%else
   %global  _arch arm64
%endif

%description
production-ready vendor-neutral OCI image registry -
 images stored in OCI image format, distribution specification on-the-wire, that's it!

%prep
%setup -q -n zot-%{version}

%build
make %{?_smp_mflags} binary cli VERSION=%{version}

%install
%{__mkdir_p} %{buildroot}/%{_bindir} %{buildroot}%{_defaultlicensedir}/%{name}-%{version}
%{__mkdir_p} %{buildroot}%{_unitdir} %{buildroot}/usr/share/bash-completion/completions
%{__mkdir_p} %{buildroot}/etc/zot/ %{buildroot}/var/lib/zot/ %{buildroot}/var/log/zot
%{__install} -m 0755 bin/zot-linux-%{_arch} %{buildroot}/%{_bindir}/zot
%{__install} -m 0755 bin/zli-linux-%{_arch} %{buildroot}/%{_bindir}/zli
%{__install} -m0644 LICENSE %{buildroot}%{_defaultlicensedir}/%{name}-%{version}/COPYING
%{__install} -m0644 %{SOURCE1} %{buildroot}%{_unitdir}/zot.service
%{__install} -m0644 %{SOURCE2} %{buildroot}/etc/zot/config.json
htpasswd -bBn admin admin | tee %{buildroot}/etc/zot/htpasswd > /dev/null
%{__sed} -i "s|{_path_}|%{_bindir}/zot|g" %{buildroot}%{_unitdir}/zot.service
%{buildroot}%{_bindir}/zot completion bash | tee %{buildroot}/usr/share/bash-completion/completions/zot >/dev/null
%{buildroot}%{_bindir}/zli completion bash | tee %{buildroot}/usr/share/bash-completion/completions/zli >/dev/null


%files
%{_bindir}/zot
%license %{_defaultlicensedir}/%{name}-%{version}/COPYING
%{_unitdir}/zot.service
%config(noreplace) /etc/zot/config.json
%config(noreplace) /etc/zot/htpasswd
%dir /var/lib/zot
/usr/share/bash-completion/completions/zot
%dir /var/log/zot

%post
systemctl daemon-reload >/dev/null 2>&1 ||:

%preun
case $1 in
  0)
  systemctl disable --now zot >/dev/null 2>&1 ||:
  ;;
esac

%package  zli
Summary:  OCI-native container image registry Zot CLI

%description zli
OCI-native container image registry Zot CLI


%files zli
%{_bindir}/zli
/usr/share/bash-completion/completions/zli

%changelog
* Wed Feb 8 2023 Dragon
- 初始化项目
