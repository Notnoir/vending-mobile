# Panduan Pengembangan Vending Machine Mobile App

## 🚀 Quick Start

### 1. Install Dependencies

```bash
cd vending_mobile
flutter pub get
```

### 2. Jalankan Backend

Pastikan backend API sudah berjalan di `http://localhost:5000`

```bash
cd ../backend
npm install
npm run dev
```

### 3. Konfigurasi API

Edit file `lib/config/api_config.dart`:

**Untuk Android Emulator:**

```dart
static const String developmentUrl = 'http://10.0.2.2:5000/api';
```

**Untuk iOS Simulator:**

```dart
static const String developmentUrl = 'http://localhost:5000/api';
```

**Untuk Device Fisik:**

```dart
static const String developmentUrl = 'http://YOUR_LOCAL_IP:5000/api';
// Contoh: 'http://192.168.1.100:5000/api'
```

### 4. Jalankan Aplikasi

```bash
# Android
flutter run

# iOS
flutter run

# Pilih specific device
flutter run -d <device_id>

# List available devices
flutter devices
```

## 📱 Fitur Yang Sudah Tersedia

### ✅ **Struktur Project**

- ✅ Folder structure lengkap
- ✅ Configuration files (API, Theme)
- ✅ Models (Product, Order, Cart, Payment)
- ✅ Services (API, Product, Order, Payment)
- ✅ Providers (Cart State Management)
- ✅ Dependencies sudah dikonfigurasi

### 🔧 **Yang Perlu Dikembangkan**

#### 1. **Screens/UI** (Belum ada)

Anda perlu membuat screen-screen berikut:

```
lib/screens/
├── splash_screen.dart          # Splash screen saat app start
├── home/
│   └── home_screen.dart       # Home screen utama
├── products/
│   ├── product_list_screen.dart   # List produk
│   └── product_detail_screen.dart # Detail produk
├── cart/
│   └── cart_screen.dart       # Shopping cart
├── payment/
│   ├── payment_screen.dart    # Halaman payment
│   └── qr_payment_screen.dart # Display QR code
└── orders/
    ├── order_history_screen.dart  # History order
    └── order_detail_screen.dart   # Detail order
```

#### 2. **Widgets** (Belum ada)

Widget reusable yang perlu dibuat:

```
lib/widgets/
├── product_card.dart          # Card untuk tampilan produk
├── cart_item_widget.dart      # Widget untuk item di cart
├── qr_scanner.dart           # QR code scanner
├── loading_indicator.dart    # Loading spinner
└── custom_button.dart        # Custom button widget
```

#### 3. **Main.dart** (Perlu diupdate)

Update `lib/main.dart` untuk setup Provider dan routing.

## 📖 Langkah-langkah Development

### Step 1: Update Main.dart

Update `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme_config.dart';
import 'providers/cart_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'Vending Machine',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}
```

### Step 2: Buat Splash Screen

Create `lib/screens/splash_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_drink,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              'Vending Machine',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Step 3: Buat Home Screen dengan Product List

Create folder `lib/screens/home/` dan `lib/screens/products/`

Example struktur Home Screen:

```dart
// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import '../products/product_list_screen.dart';
import '../cart/cart_screen.dart';
import '../orders/order_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ProductListScreen(),
    const OrderHistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Orders',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CartScreen()),
          );
        },
        child: const Icon(Icons.shopping_cart),
      ),
    );
  }
}
```

### Step 4: Buat Product List Screen

```dart
// lib/screens/products/product_list_screen.dart
import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import '../../models/product.dart';
import '../../widgets/product_card.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final products = await _productService.getAvailableProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      ElevatedButton(
                        onPressed: _loadProducts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProducts,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      return ProductCard(product: _products[index]);
                    },
                  ),
                ),
    );
  }
}
```

### Step 5: Buat Widget Product Card

```dart
// lib/widgets/product_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../config/theme_config.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigate to product detail
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.grey[200],
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.local_drink, size: 50);
                        },
                      )
                    : const Icon(Icons.local_drink, size: 50),
              ),
            ),

            // Product Info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTheme.subheadingStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${product.price.toStringAsFixed(0)}',
                    style: AppTheme.bodyStyle.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stock: ${product.stock}',
                    style: AppTheme.captionStyle,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<CartProvider>().addProduct(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} added to cart'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Add to Cart'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 🧪 Testing

### Test Connection ke Backend

1. Pastikan backend running
2. Test API dengan curl atau Postman:

```bash
curl http://localhost:5000/api/products
```

3. Jalankan app dan cek log:

```bash
flutter run --verbose
```

### Debug Network Issues

**Android:**
Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<application
    android:usesCleartextTraffic="true"
    ...>
```

**iOS:**
Edit `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## 📝 To-Do List Development

- [ ] Setup main.dart dengan Provider
- [ ] Buat Splash Screen
- [ ] Buat Home Screen dengan Bottom Navigation
- [ ] Buat Product List Screen
- [ ] Buat Product Card Widget
- [ ] Buat Product Detail Screen
- [ ] Buat Cart Screen
- [ ] Buat Cart Item Widget
- [ ] Implement Add/Remove dari Cart
- [ ] Buat Payment Screen
- [ ] Integrate Midtrans Payment
- [ ] Buat QR Payment Screen dengan QR display
- [ ] Implement Payment Status Polling
- [ ] Buat Order History Screen
- [ ] Buat Order Detail Screen
- [ ] Add Search Functionality
- [ ] Add Category Filter
- [ ] Add Error Handling yang comprehensive
- [ ] Add Loading States
- [ ] Test di real device
- [ ] Performance optimization

## 🔗 Resources

- Backend API Documentation: `../backend/README.md`
- Frontend Payment Integration: `../frontend/ARCHITECTURE.md`
- Flutter Documentation: https://flutter.dev/docs
- Provider Package: https://pub.dev/packages/provider

## ❓ Troubleshooting

### Cannot connect to localhost

- Android Emulator: Use `10.0.2.2` instead of `localhost`
- iOS Simulator: Use `localhost`
- Physical Device: Use your computer's local IP address

### CORS Issues

Backend sudah configured untuk handle CORS, pastikan backend running dengan benar.

### Dependencies Error

```bash
flutter pub get
flutter clean
flutter pub get
```

## 📞 Next Steps

1. **Run `flutter pub get`** untuk install semua dependencies
2. **Update `lib/main.dart`** seperti contoh di atas
3. **Buat screens satu per satu** mulai dari Splash → Home → Product List
4. **Test API connection** dengan Product List Screen
5. **Implement Cart functionality**
6. **Integrate Payment** dengan Midtrans

Selamat coding! 🚀
