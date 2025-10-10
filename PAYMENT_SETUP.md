# Setup Pembayaran Midtrans - Mobile App

## Konfigurasi

### 1. Pastikan Frontend Next.js Berjalan

Frontend harus running di port **3000** karena mobile app memanggil API route Next.js untuk Midtrans.

```bash
cd frontend
npm run dev
```

### 2. Update IP Address

Edit file `lib/config/api_config.dart` dan update IP address sesuai dengan IP komputer Anda:

```dart
static const String developmentUrl = 'http://192.168.100.17:3001/api'; // Backend
static const String frontendUrl = 'http://192.168.100.17:3000'; // Frontend
```

Cara cek IP:

- Windows: `ipconfig` (lihat IPv4 Address)
- Mac/Linux: `ifconfig` atau `ip addr`

### 3. Pastikan Midtrans Server Key Tersedia

Edit file `frontend/.env.local`:

```env
MIDTRANS_SERVER_KEY=SB-Mid-server-YOUR_ACTUAL_SERVER_KEY
NEXT_PUBLIC_MIDTRANS_CLIENT_KEY=SB-Mid-client-YOUR_ACTUAL_CLIENT_KEY
```

## Alur Pembayaran

### QRIS (Langsung ke Backend)

1. User pilih metode QRIS
2. Mobile app → Backend `/api/orders` (POST)
3. Backend return QR code URL
4. Tampilkan QR code
5. Polling status ke Backend `/api/orders/:id` (GET)

### Midtrans Snap (Via Frontend Next.js)

1. User pilih metode Midtrans
2. Mobile app → Frontend `/api/payment/create` (POST)
3. Frontend panggil Midtrans Snap API
4. Frontend return `token` dan `redirect_url`
5. Mobile app buka `redirect_url` di browser eksternal
6. User bayar di Midtrans Snap page
7. Polling status ke Backend `/api/orders/:id` (GET)

## URLs yang Digunakan

### Backend (Port 3001)

- Create QRIS Order: `POST http://IP:3001/api/orders`
- Get Order Status: `GET http://IP:3001/api/orders/:id`

### Frontend (Port 3000)

- Create Midtrans Transaction: `POST http://IP:3000/api/payment/create`
- Check Payment Status: `GET http://IP:3000/api/payment/status/:orderId`

### Midtrans Sandbox

- Snap URL: `https://app.sandbox.midtrans.com/snap/snap.js`
- API URL: `https://api.sandbox.midtrans.com`

## Troubleshooting

### Error: "Could not launch payment URL"

**Penyebab**: AndroidManifest.xml tidak memiliki permission dan queries untuk url_launcher

**Solusi**:

1. ✅ Sudah ditambahkan INTERNET permission
2. ✅ Sudah ditambahkan queries untuk http/https
3. Rebuild APK: `flutter clean && flutter build apk --debug`
4. Install ulang APK di device

### Error: "Route not found /api/payment/create"

**Penyebab**: Frontend Next.js tidak running atau IP salah

**Solusi**:

1. Pastikan frontend running: `cd frontend && npm run dev`
2. Cek IP address di `api_config.dart` sesuai dengan IP komputer
3. Test akses: buka browser di HP → `http://IP:3000`

### Error: "Situs tidak dapat dijangkau" saat buka Midtrans

**Penyebab**: Redirect URL menggunakan `localhost` atau device tidak bisa akses internet

**Solusi**:

1. Pastikan HP terhubung ke WiFi yang sama dengan komputer
2. Pastikan HP bisa akses internet
3. Cek firewall komputer tidak memblok port 3000

### Error: "Failed to create payment transaction"

**Penyebab**: Midtrans Server Key tidak valid atau tidak diset

**Solusi**:

1. Cek file `frontend/.env.local` ada dan berisi Server Key yang valid
2. Restart frontend setelah update .env: `npm run dev`
3. Dapatkan Server Key dari: https://dashboard.sandbox.midtrans.com

## Testing

### Test Koneksi ke Frontend

Buka browser di HP dan akses:

```
http://192.168.100.17:3000
```

(Ganti dengan IP komputer Anda)

Jika halaman Next.js terbuka, berarti koneksi OK.

### Test Payment API

Gunakan Postman atau curl dari komputer:

```bash
curl -X POST http://localhost:3000/api/payment/create \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": "TEST-123",
    "amount": 10000,
    "customerName": "Test User",
    "customerEmail": "test@example.com",
    "items": [{
      "id": "1",
      "name": "Test Product",
      "price": 10000,
      "quantity": 1
    }]
  }'
```

Response yang diharapkan:

```json
{
  "token": "xxx",
  "redirect_url": "https://app.sandbox.midtrans.com/snap/v4/redirection/xxx"
}
```

## Catatan Penting

1. **Frontend HARUS running** untuk pembayaran Midtrans
2. **Backend tetap digunakan** untuk QRIS dan cek status order
3. **Gunakan IP yang sama** di seluruh konfigurasi
4. **HP dan Komputer harus di WiFi yang sama**
5. **Midtrans Snap** membuka di browser eksternal, bukan WebView
