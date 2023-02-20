Name:           caddy
Version:        2.6.4
Release:        2%{?dist}
Summary:        Caddy is an extensible server platform that uses TLS by default.

License:        Apache-2.0
URL:            https://github.com/caddyserver/caddy
Source0:        https://github.com/caddyserver/caddy/archive/refs/tags/v%{version}.tar.gz
Source1:        caddy.service
Source2:        Caddyfile
BuildRequires:  golang

%define         run_user caddy
%define         run_group caddy

%description
Caddy is an extensible server platform that uses TLS by default.

%prep
%setup


%build
cd cmd/caddy && go build

%install
%{__mkdir_p} %{buildroot}/%{_bindir} %{buildroot}%{_defaultlicensedir}/%{name}-%{version}
%{__mkdir_p} %{buildroot}%{_unitdir}
%{__mkdir_p} %{buildroot}/etc/caddy
%{__install} -m 0755 cmd/caddy/caddy %{buildroot}/%{_bindir}/caddy
%{__install} -m0644 LICENSE %{buildroot}%{_defaultlicensedir}/%{name}-%{version}/COPYING
%{__install} -m0644 %{SOURCE1} %{buildroot}%{_unitdir}/caddy.service
%{__sed} -i -e "s|{_path_}|%{_bindir}/caddy|g" -e 's|{_group_}|%{run_group}|g' -e 's|{_user_}|%{run_user}|g' %{buildroot}%{_unitdir}/caddy.service
%{__install} -m0644 %{SOURCE2} %{buildroot}/etc/caddy/Caddyfile


%files
%license %{_defaultlicensedir}/%{name}-%{version}/COPYING
%{_bindir}/caddy
%{_unitdir}/caddy.service
%attr(0755, %{run_user}, %{run_group}) /etc/caddy
%config(noreplace) /etc/caddy/Caddyfile

%pre
getent group %{run_group} >/dev/null || groupadd -r %{run_group}
getent passwd %{run_user} >/dev/null || \
    useradd -r -g %{run_group} -m -d /var/lib/%{run_user} -s /sbin/nologin \
    -c "Caddy User" %{run_user}


%post
systemctl daemon-reload >/dev/null 2>&1 ||:


%preun
case $1 in
  0)
  systemctl disable --now caddy >/dev/null 2>&1 ||:
  ;;
esac

%changelog
* Wed Feb 8 2023 Dragon
- 初始化项目
