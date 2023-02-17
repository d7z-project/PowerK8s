%define        git_commit_id 74ae2a2168c28c94dada36cdb809031682f0832e

Name:           powerk8s-static-kubevela
Version:        20230217
Release:        1%{?dist}
Summary:        KubeVela Catalog

License:        Apache-2.0
URL:            https://github.com/kubevela/catalog
Source0:        https://github.com/kubevela/catalog/archive/%{git_commit_id}.tar.gz
BuildArch:      noarch
BuildRequires:  golang gcc
Requires:       caddy

%description
This repo is a catalog of addons which extend the capability of KubeVela control plane. Generally,
an addon consists of Kubernetes CRD and corresponding X-definition,
 but none of them is necessary. For example, the fluxcd addon consists of FluxCD controller and the helm component definition,
 while VelaUX just deploy a web server without any CRD or Definitions.

%prep
%setup -q -n catalog-%{git_commit_id}

%build
%{__cp} hack/addons/syn_addon_package.go ./addons/
%{__cp} hack/addons/syn_addon_package.go ./experimental/addons/
%{__mkdir_p} release/addons
%{__mkdir_p} release/experimental/addons
(
cd addons &&
go run ./syn_addon_package.go ./ https://addons.kubevela.net &&
sed -i -e 's|https://addons.kubevela.net/|https://boot.powerk8s.cn/static/kubevela/catalog/addons|g' index.yaml &&
cp index.yaml ../release/addons &&
cp *.tgz ../release/addons
);
(
cd experimental/addons &&
go run ./syn_addon_package.go ./ https://addons.kubevela.net &&
sed -i -e 's|https://addons.kubevela.net/|https://boot.powerk8s.cn/static/kubevela/catalog/addons|g' index.yaml &&
cp index.yaml ../../release/experimental/addons &&
cp *.tgz ../../release/experimental/addons
)


%install
%{__mkdir_p} %{buildroot}/var/www/kubevela/ %{buildroot}%{_defaultlicensedir}/%{name}-%{version}
%{__cp} -r release/* %{buildroot}/var/www/kubevela/
%{__install} -m0644 LICENSE %{buildroot}%{_defaultlicensedir}/%{name}-%{version}/COPYING


%files
%license %{_defaultlicensedir}/%{name}-%{version}/COPYING
%attr(0755, www, www) /var/www/kubevela

%changelog
* Wed Feb 8 2023 Dragon
- 初始化项目
