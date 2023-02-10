%define __os_install_post %{nil}
%global _missing_build_ids_terminate_build 0

%if "%{_arch}" == "x86_64"
   %global  _arch amd64
%else
   %global  _arch arm64
%endif

Name:           golang
Version:        1.19.2
Release:        3%{?dist}
Summary:        Build fast, reliable, and efficient software at scale
License:        Apache 2
URL:            https://go.dev/
Source0:        http://mirrors.ustc.edu.cn/golang/go%{version}.linux-%{_arch}.tar.gz
BuildRequires:  tar gzip

%description
“At the time, no single team member knew Go, but within a month, everyone was writing in Go and we were building out the endpoints.
 It was the flexibility, how easy it was to use, and the really cool concept behind Go (how Go handles native concurrency, garbage collection, and of course safety+speed.)
 that helped engage us during the build. Also, who can beat that cute mascot!”

%install
%{__mkdir_p} %{buildroot}{/usr/lib,/usr/bin}
%{__tar} Czxf %{buildroot}/usr/lib %{SOURCE0}
%{__ln_s} /usr/lib/go/bin/go %{buildroot}/usr/bin/go
%{__ln_s} /usr/lib/go/bin/gofmt %{buildroot}/usr/bin/gofmt

%files
/usr/lib/go
/usr/bin/go
/usr/bin/gofmt


%changelog
* Wed Oct 26 2022 Dragon
- 初始化项目
