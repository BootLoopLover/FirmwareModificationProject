#!/bin/bash

set -e

echo "[+] Update dan install dependencies..."
opkg update
opkg install bash curl

echo "[+] Menjalankan installer Libernet..."
bash -c "$(curl -sko - 'https://raw.githubusercontent.com/lutfailham96/libernet/main/install.sh')"

echo "[+] Menambahkan menu LuCI untuk Libernet..."
cat <<'EOF' >/usr/lib/lua/luci/controller/libernet.lua
module("luci.controller.libernet", package.seeall)
function index()
entry({"admin","services","libernet"}, template("libernet"), _("Libernet"), 55).leaf=true
end
EOF

cat <<'EOF' >/usr/lib/lua/luci/view/libernet.htm
<%+header%>
<div class="cbi-map">
<iframe id="libernet" style="width: 100%; min-height: 650px; border: none; border-radius: 2px;"></iframe>
</div>
<script type="text/javascript">
document.getElementById("libernet").src = "http://" + window.location.hostname + "/libernet";
</script>
<%+footer%>
EOF

echo "[+] Menghapus autentikasi password di halaman Libernet..."
TARGET_FILE="/www/libernet/index.php"
if grep -q "auth.php" "$TARGET_FILE"; then
    sed -i '/auth.php/d' "$TARGET_FILE"
    sed -i '/check_session/d' "$TARGET_FILE"
    echo "[✓] Baris autentikasi berhasil dihapus."
else
    echo "[i] Tidak ditemukan baris autentikasi. Lewat."
fi

echo "[+] Selesai! Silakan akses Libernet via LuCI atau langsung di: http://<ip-router>/libernet"
