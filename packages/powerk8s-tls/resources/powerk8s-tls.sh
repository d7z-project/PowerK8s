#!/usr/bin/env bash
set -e
CA_PATH=${CA_PATH:-"/etc/PowerK8s/tls"}
CA_NAME=${CA_NAME:-"PowerK8s Self-Sign CA"}
if [ "$(id -u)" != "0" ]; then
  echo "This tool is only available to root users."
  exit 1
fi
case $1 in
init)
  test ! -f "$CA_PATH/ca.crt" || (
    echo "Error: ca already initialized."
    exit 1
  )

  mkdir -p "$CA_PATH"
  if [ ! -d "$CA_PATH" ]; then
    chown root "$CA_PATH"
    chmod 600 "$CA_PATH"
  fi
  openssl genrsa -out "$CA_PATH/ca.key" 4096
  openssl req -x509 -new -nodes -sha512 -extensions v3_ca -days 9125 -subj "/CN=$CA_NAME" -key "$CA_PATH/ca.key" -out "$CA_PATH/ca.crt"

  ;;
system)
  case $2 in
  install)
    test -f "$CA_PATH/ca.crt" || (
      echo "Error: ca already not initialized."
      exit 1
    )
    command -v update-ca-trust > /dev/null 2>&1 && update-ca-trust force-enable
    test ! -f /etc/pki/ca-trust/source/anchors/PowerK8s.pem || rm /etc/pki/ca-trust/source/anchors/PowerK8s.pem
    test ! -f /usr/local/share/ca-certificates/PowerK8s.pem || rm /usr/local/share/ca-certificates/PowerK8s.pem
    test ! -f /etc/pki/ca-trust/source/anchors/PowerK8s.pem || ln -sf "$CA_PATH/ca.crt" /etc/pki/ca-trust/source/anchors/PowerK8s.pem
    test ! -f /usr/local/share/ca-certificates/PowerK8s.pem || ln -sf "$CA_PATH/ca.crt" /usr/local/share/ca-certificates/PowerK8s.pem
    command -v update-ca-trust > /dev/null 2>&1 && update-ca-trust
    command -v update-ca-certificates > /dev/null 2>&1 && update-ca-certificates --fresh
    ;;
  remove)
    test ! -f /etc/pki/ca-trust/source/anchors/PowerK8s.pem || rm /etc/pki/ca-trust/source/anchors/PowerK8s.pem
    test ! -f /usr/local/share/ca-certificates/PowerK8s.pem || rm /usr/local/share/ca-certificates/PowerK8s.pem
    command -v update-ca-trust > /dev/null 2>&1 && update-ca-trust
    command -v update-ca-certificates > /dev/null 2>&1 && update-ca-certificates --fresh
    ;;
  *)
    echo "$(basename "$0") system help"
    echo ""
    echo -e "  $(basename "$0") system <args>"
    echo ""
    echo -e "install       \t install self certificate to system."
    echo -e "remove        \t remove self certificate to system."
    ;;
  esac
  ;;
info)
  test -f "$CA_PATH/ca.crt" || (echo "ca not exists！" && exit 1)
  openssl x509 -noout -text -in "$CA_PATH/ca.crt"
  ;;
server)
  SERVER_NAME=$2
  SERVER_PATH=$CA_PATH/$SERVER_NAME
  mkdir -p "$SERVER_PATH"
  case $3 in
  new)
    test "$SERVER_NAME" || (echo "$SERVER_NAME non-compliance" && exit 1)
    test ! -f "$SERVER_PATH/server.key" || (echo "$SERVER_NAME exists！" && exit 1)
    openssl genrsa -out "$SERVER_PATH/server.key" 4096
    cat >"$SERVER_PATH/v3.ext" <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1=$SERVER_NAME
EOF
    openssl req -new -sha512 -subj "/CN=$SERVER_NAME" -key "$SERVER_PATH/server.key" -out "$SERVER_PATH/server.csr"
    openssl x509 -req -sha512 -days 3650 \
      -extfile "$SERVER_PATH/v3.ext" \
      -CA "$CA_PATH/ca.crt" -CAkey "$CA_PATH/ca.key" -CAcreateserial \
      -in "$SERVER_PATH/server.csr" \
      -out "$SERVER_PATH/server.cert"
    ;;
  update)
    test "$SERVER_NAME" || (echo "$SERVER_NAME non-compliance" && exit 1)
    test -f "$SERVER_PATH/server.key" || (echo "$SERVER_NAME not exists！" && exit 1)
    openssl req -new -sha512 -subj "/CN=$SERVER_NAME" -key "$SERVER_PATH/server.key" -out "$SERVER_PATH/server.csr"
    openssl x509 -req -sha512 -days 3650 \
      -extfile "$SERVER_PATH/v3.ext" \
      -CA "$CA_PATH/ca.crt" -CAkey "$CA_PATH/ca.key" -CAcreateserial \
      -in "$SERVER_PATH/server.csr" \
      -out "$SERVER_PATH/server.cert"
    ;;
  install)
    test "$SERVER_NAME" || (echo "$SERVER_NAME non-compliance" && exit 1)
    test -f "$SERVER_PATH/server.cert" || (echo "$SERVER_NAME not exists！" && exit 1)
    test -f "$SERVER_PATH/server.key" || (echo "$SERVER_NAME not exists！" && exit 1)
    DIST_PATH=$4
    test -d "$DIST_PATH" || (echo "directory '$DIST_PATH' not exists! " && exit 1)
    install -m 0600 "$SERVER_PATH/server.key" "$DIST_PATH/server.key"
    install -m 0600 "$SERVER_PATH/server.cert" "$DIST_PATH/server.cert"
    ;;

  info)
    test "$SERVER_NAME" || (echo "$SERVER_NAME non-compliance" && exit 1)
    test -f "$SERVER_PATH/server.cert" || (echo "$SERVER_NAME not exists！" && exit 1)
    openssl x509 -noout -text -in "$SERVER_PATH/server.cert"
    ;;
  *)
    echo "$(basename "$0") server help"
    echo ""
    echo -e "  $(basename "$0") server SERVER_NAME <args>"
    echo ""
    echo -e "new             \t sign new server certificates"
    echo -e "update          \t update server certificates"
    echo -e "info            \t get server certificates info"
    echo -e "install <path>  \t install cert/key to path"
    ;;
  esac
  ;;
*)
  echo "$(basename "$0")  help"
  echo ""
  echo -e "init             \t sign new ca certificate"
  echo -e "system           \t install/remove ca to system"
  echo -e "server args...   \t Manage server certificate"
  echo -e "info             \t get ca certificates infopath"
  ;;
esac
