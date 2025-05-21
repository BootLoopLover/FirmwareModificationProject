#!/bin/sh

echo "📡 Memeriksa ttyd..."

# 1. Cek apakah ttyd terpasang
if ! command -v ttyd >/dev/null 2>&1; then
    echo "❌ ttyd tidak ditemukan. Memasang sekarang..."
    opkg update && opkg install ttyd || {
        echo "Gagal memasang ttyd. Periksa koneksi internet atau sumber feed."
        exit 1
    }
else
    echo "✅ ttyd sudah terpasang."
fi

# 2. Hentikan ttyd jika sedang jalan
if pidof ttyd >/dev/null; then
    echo "🔁 Mematikan proses ttyd lama..."
    killall ttyd
fi

# 3. Jalankan ttyd di port 7681
echo "🚀 Menjalankan ttyd pada port 7681..."
ttyd -p 7681 /bin/ash &

# 4. Tambahkan ke /etc/rc.local jika belum ada
if ! grep -q "ttyd -p 7681" /etc/rc.local; then
    echo "🔧 Menambahkan ttyd ke autostart /etc/rc.local..."
    sed -i '/^exit 0/i ttyd -p 7681 /bin/ash &' /etc/rc.local
fi

# 5. Tambahkan aturan firewall untuk port 7681
echo "🌐 Memastikan firewall mengizinkan port 7681 dari LAN..."
uci add firewall rule
uci set firewall.@rule[-1].name='Allow-ttyd'
uci set firewall.@rule[-1].src='lan'
uci set firewall.@rule[-1].dest_port='7681'
uci set firewall.@rule[-1].proto='tcp'
uci set firewall.@rule[-1].target='ACCEPT'
uci commit firewall
/etc/init.d/firewall restart

echo "✅ Selesai. Sekarang kamu boleh akses: http://<IP-Router>:7681"
