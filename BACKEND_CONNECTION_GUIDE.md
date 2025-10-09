# Panduan Koneksi Backend untuk Mobile App

## ✅ Problem Yang Sudah Fixed

**Masalah:** Mobile app tidak bisa connect ke backend/database
**Penyebab:**

1. Backend tidak running
2. Port salah (app mencari port 5000, tapi backend di 3001)
3. IP address salah (10.0.2.2 untuk emulator, tapi device fisik butuh IP komputer)

**Solusi:**

1. ✅ Backend sudah running di port 3001
2. ✅ API config updated ke IP komputer (192.168.100.17)
3. ✅ App sudah rebuild dan install ulang

## 📱 Konfigurasi Saat Ini

### Backend Server

- **Status:** ✅ Running
- **Port:** 3001
- **URL:** http://192.168.100.17:3001
- **Health Check:** http://192.168.100.17:3001/health
- **API Endpoint:** http://192.168.100.17:3001/api

### Mobile App

- **Device:** V2040 (Device Fisik)
- **API Config:** `lib/config/api_config.dart`
- **Base URL:** http://192.168.100.17:3001/api
- **APK:** `build/app/outputs/flutter-apk/app-debug.apk`

### Database

- **Host:** localhost (dari backend)
- **Port:** 3306
- **Database:** vending_machine
- **Status:** ✅ Connected

## 🔧 Cara Menjalankan Backend

### 1. Masuk ke folder backend

```bash
cd d:\riza\project\vending-machine\backend
```

### 2. Jalankan server development

```bash
npm run dev
```

Output yang benar:

```
🚀 Vending Machine Backend running on port 3001
📊 Health check: http://localhost:3001/health
🌍 Environment: development
✅ Database connected successfully
```

### 3. Test API (optional)

```bash
# Health check
curl http://192.168.100.17:3001/health

# Get products
curl http://192.168.100.17:3001/api/products

# Get orders
curl http://192.168.100.17:3001/api/orders
```

## 📱 Cara Update Mobile App Jika IP Berubah

### 1. Cek IP komputer

```bash
ipconfig | Select-String -Pattern "IPv4"
```

Gunakan IP yang terhubung ke WiFi/LAN yang sama dengan device (biasanya 192.168.x.x)

### 2. Update API Config

Edit file: `vending_mobile/lib/config/api_config.dart`

```dart
class ApiConfig {
  // Base URLs
  // PENTING: Untuk device fisik, gunakan IP komputer di network yang sama
  // Backend berjalan di port 3001
  static const String developmentUrl =
      'http://192.168.100.17:3001/api'; // ⬅️ UBAH IP INI
```

### 3. Rebuild dan Install

```bash
# Rebuild
cd vending_mobile
flutter build apk --debug

# Install ke device
adb install -r build\app\outputs\flutter-apk\app-debug.apk

# Launch app
adb shell am start -n com.example.vending_mobile/com.example.vending_mobile.MainActivity
```

## 🌐 Konfigurasi untuk Berbagai Environment

### Android Emulator

```dart
static const String developmentUrl = 'http://10.0.2.2:3001/api';
```

### iOS Simulator

```dart
static const String developmentUrl = 'http://localhost:3001/api';
```

### Device Fisik (Current)

```dart
static const String developmentUrl = 'http://192.168.100.17:3001/api';
```

### Production

```dart
static const bool isProduction = true;
static const String productionUrl = 'https://your-backend.com/api';
```

## 🔍 Troubleshooting

### Backend Tidak Running

**Cek:**

```bash
netstat -ano | Select-String ":3001"
```

Jika kosong, jalankan:

```bash
cd backend
npm run dev
```

### Device Tidak Bisa Akses Backend

**1. Pastikan device dan komputer di WiFi yang sama**

**2. Test dari komputer:**

```bash
curl http://192.168.100.17:3001/health
```

**3. Cek Windows Firewall:**

- Buka Windows Defender Firewall
- Advanced Settings
- Inbound Rules
- Pastikan Node.js atau port 3001 diizinkan

**4. Jika masih error, allow port manually:**

```powershell
# Run as Administrator
New-NetFirewallRule -DisplayName "Node Backend Port 3001" -Direction Inbound -LocalPort 3001 -Protocol TCP -Action Allow
```

### App Tidak Tampil Produk

**1. Cek console log di terminal backend**
Lihat apakah ada request masuk dari mobile app

**2. Cek API response format**
Mobile app expect:

```json
{
  "products": [
    {
      "id": 1,
      "name": "Product Name",
      "price": "10000",
      "stock": 10
      // ...
    }
  ]
}
```

**3. Rebuild app setelah ubah API config**

```bash
flutter clean
flutter build apk --debug
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

## 📊 API Endpoints Available

### Products

- `GET /api/products` - Get all products
- `GET /api/products/:id` - Get product by ID

### Orders

- `GET /api/orders` - Get all orders
- `POST /api/orders` - Create new order
- `GET /api/orders/:id` - Get order by ID
- `PUT /api/orders/:id/status` - Update order status

### Payment (Midtrans)

- `POST /api/payment/create` - Create payment transaction
- `GET /api/payment/status/:orderId` - Check payment status

### Health

- `GET /health` - Server health check

## 🎯 Quick Start Checklist

Setiap kali development:

- [ ] Backend running: `cd backend && npm run dev`
- [ ] Check backend logs: lihat terminal output
- [ ] Verify IP di API config matches komputer IP
- [ ] App sudah di-rebuild setelah ubah config
- [ ] Device dan komputer di WiFi yang sama
- [ ] Test API: `curl http://192.168.100.17:3001/health`
- [ ] Launch app dan test products list

## ✅ Current Status

**Backend:**

- ✅ Running on http://192.168.100.17:3001
- ✅ Database connected
- ✅ Has product data
- ✅ Accessible from network

**Mobile App:**

- ✅ Installed on device V2040
- ✅ API config updated to correct IP and port
- ✅ Ready to fetch data from backend

**Next Steps:**

1. Buka app di device
2. Navigate ke tab "Produk"
3. Seharusnya produk muncul dari database!

---

**Updated:** October 7, 2025
**Device IP:** 192.168.100.17
**Backend Port:** 3001
**App Version:** Debug APK
