Name:           caddy
Version:        2.6.4
Release:        1%{?dist}
Summary:        Caddy is an extensible server platform that uses TLS by default.

License:        Apache-2.0
URL:            https://github.com/caddyserver/caddy
Source0:        https://github.com/caddyserver/caddy/archive/refs/tags/v%{version}.tar.gz
Source1:        caddy.service
Source2:        Caddyfile
Source3:        Caddyfile.sample
BuildRequires:  golang


%description
Caddy is an extensible server platform that uses TLS by default.

%prep
%setup


%build
cd cmd/caddy
go build


%install
%{__mkdir_p} %{buildroot}/%{_bindir} %{buildroot}%{_defaultlicensedir}/%{name}-%{version}
%{__mkdir_p} %{buildroot}%{_unitdir} %{buildroot}/var/www
%{__mkdir_p} %{buildroot}/etc/caddy
%{__install} -m 0755 cmd/caddy/caddy %{buildroot}/%{_bindir}/caddy
%{__install} -m0644 LICENSE %{buildroot}%{_defaultlicensedir}/%{name}-%{version}/COPYING
%{__install} -m0644 %{SOURCE1} %{buildroot}%{_unitdir}/caddy.service
%{__sed} -i "s|{_path_}|%{_bindir}/caddy|g" %{buildroot}%{_unitdir}/caddy.service
%{__install} -m0644 %{SOURCE2} %{buildroot}/etc/caddy/Caddyfile
%{__install} -m0644 %{SOURCE3} %{buildroot}/etc/caddy/Caddyfile.sample


%files
%license %{_defaultlicensedir}/%{name}-%{version}/COPYING
%{_bindir}/caddy
%{_unitdir}/caddy.service
%attr(0755, www, www) /etc/caddy
%config(noreplace) /etc/caddy/Caddyfile
%attr(0755, www, www) /var/www

%pre
getent group www >/dev/null || groupadd -r www
getent passwd www >/dev/null || \
    useradd -r -g www -m -d /var/www -s /sbin/nologin \
    -c "Caddy User" www


%post
systemctl daemon-reload >/dev/null 2>&1 ||:
systemctl enable caddy ||:
systemctl restart caddy ||:


%preun
case $1 in
  0)
  systemctl disable --now caddy >/dev/null 2>&1 ||:
  ;;
esac

%changelog
* Wed Feb 8 2023 Dragon
- 初始化项目
