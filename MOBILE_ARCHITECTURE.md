# Vending Machine Mobile App - Flutter Architecture

## 📱 Project Overview

Aplikasi mobile Flutter untuk vending machine yang terintegrasi dengan backend Node.js dan Midtrans payment gateway.

## 🏗️ Architecture

### Folder Structure

```
lib/
├── main.dart                 # Entry point aplikasi
├── config/
│   ├── api_config.dart      # API endpoints configuration
│   ├── theme_config.dart    # Theme & styling configuration
│   └── routes.dart          # App routing configuration
├── models/
│   ├── product.dart         # Product data model
│   ├── order.dart           # Order data model
│   ├── cart_item.dart       # Cart item model
│   └── payment.dart         # Payment model
├── services/
│   ├── api_service.dart     # HTTP client & API calls
│   ├── auth_service.dart    # Authentication service
│   ├── product_service.dart # Product CRUD operations
│   ├── order_service.dart   # Order management
│   └── payment_service.dart # Midtrans payment integration
├── providers/
│   ├── cart_provider.dart   # Cart state management
│   ├── order_provider.dart  # Order state management
│   └── auth_provider.dart   # Auth state management
├── screens/
│   ├── splash_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── products/
│   │   ├── product_list_screen.dart
│   │   └── product_detail_screen.dart
│   ├── cart/
│   │   └── cart_screen.dart
│   ├── payment/
│   │   ├── payment_screen.dart
│   │   └── qr_payment_screen.dart
│   ├── orders/
│   │   ├── order_history_screen.dart
│   │   └── order_detail_screen.dart
│   └── admin/
│       └── admin_login_screen.dart
├── widgets/
│   ├── product_card.dart
│   ├── cart_item_widget.dart
│   ├── qr_scanner.dart
│   └── loading_indicator.dart
└── utils/
    ├── constants.dart
    ├── helpers.dart
    └── validators.dart
```

## 🎯 Key Features

### 1. **Product Browsing**

- Grid/List view untuk menampilkan produk
- Filter berdasarkan kategori dan ketersediaan
- Search functionality
- Product detail dengan gambar dan informasi lengkap

### 2. **Shopping Cart**

- Add/remove products
- Update quantity
- Calculate total price
- Persist cart state

### 3. **Payment Integration**

- Midtrans QRIS payment
- Real-time payment status checking
- QR code display untuk payment
- Payment success/failure handling

### 4. **Order Management**

- Order history
- Order status tracking
- Order details view

### 5. **Admin Features** (Optional)

- Product management
- Stock updates
- Order monitoring

## 🔧 Tech Stack

### Core

- **Flutter SDK**: ^3.9.2
- **Dart**: ^3.9.2

### State Management

- **Provider**: ^6.1.0 - Simple state management

### HTTP & API

- **http**: ^1.2.0 - HTTP requests
- **dio**: ^5.4.0 - Advanced HTTP client (alternative)

### UI Components

- **cached_network_image**: ^3.3.0 - Image caching
- **flutter_svg**: ^2.0.9 - SVG support
- **shimmer**: ^3.0.0 - Loading shimmer effect

### Payment & QR

- **qr_flutter**: ^4.1.0 - QR code generation
- **mobile_scanner**: ^3.5.5 - QR code scanning

### Storage

- **shared_preferences**: ^2.2.2 - Local storage
- **hive**: ^2.2.3 - NoSQL database

### Utilities

- **intl**: ^0.19.0 - Internationalization
- **url_launcher**: ^6.2.2 - Open URLs
- **image_picker**: ^1.0.5 - Image selection

## 🔌 API Integration

### Base URL Configuration

```dart
// Development
const String API_BASE_URL = 'http://localhost:5000/api';

// Production (akan disesuaikan)
const String API_BASE_URL = 'https://your-backend.com/api';
```

### API Endpoints

#### Products

- `GET /products` - Get all products
- `GET /products/:id` - Get product by ID
- `POST /products` - Create product (admin)
- `PUT /products/:id` - Update product (admin)
- `DELETE /products/:id` - Delete product (admin)

#### Orders

- `GET /orders` - Get all orders
- `GET /orders/:id` - Get order by ID
- `POST /orders` - Create new order
- `PUT /orders/:id/status` - Update order status

#### Payment (via Frontend API)

- `POST /api/payment/create` - Create Midtrans transaction
- `GET /api/payment/status/:orderId` - Check payment status

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  provider: ^6.1.0

  # HTTP & Networking
  http: ^1.2.0
  dio: ^5.4.0

  # UI Components
  cupertino_icons: ^1.0.8
  cached_network_image: ^3.3.0
  flutter_svg: ^2.0.9
  shimmer: ^3.0.0

  # QR & Payment
  qr_flutter: ^4.1.0
  mobile_scanner: ^3.5.5

  # Storage
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # Utilities
  intl: ^0.19.0
  url_launcher: ^6.2.2
  image_picker: ^1.0.5
  connectivity_plus: ^5.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  hive_generator: ^2.0.1
  build_runner: ^2.4.7
```

## 🚀 Getting Started

### 1. Install Dependencies

```bash
cd vending_mobile
flutter pub get
```

### 2. Configure API Endpoint

Update `lib/config/api_config.dart` dengan backend URL Anda

### 3. Run the App

```bash
# Development
flutter run

# Release build
flutter build apk --release
flutter build ios --release
```

## 🔐 Environment Configuration

Create `.env` file:

```
API_BASE_URL=http://10.0.2.2:5000/api  # Android emulator
# API_BASE_URL=http://localhost:5000/api  # iOS simulator
MIDTRANS_CLIENT_KEY=your_midtrans_client_key
```

## 📱 Screens Flow

```
Splash Screen
    ↓
Home Screen
    ↓
Product List → Product Detail → Add to Cart
    ↓
Cart Screen → Checkout
    ↓
Payment Screen → QR Payment
    ↓
Order Confirmation → Order History
```

## 🎨 UI/UX Guidelines

### Colors

- Primary: #2196F3 (Blue)
- Secondary: #FFC107 (Amber)
- Success: #4CAF50 (Green)
- Error: #F44336 (Red)
- Background: #F5F5F5 (Light Grey)

### Typography

- Heading: Roboto Bold, 24px
- Subheading: Roboto Medium, 18px
- Body: Roboto Regular, 14px
- Caption: Roboto Light, 12px

## 🧪 Testing

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Widget tests
flutter test test/widgets/
```

## 📝 Development Checklist

- [ ] Setup project structure
- [ ] Configure API endpoints
- [ ] Implement models
- [ ] Create API services
- [ ] Setup state management (Provider)
- [ ] Build UI screens
- [ ] Implement cart functionality
- [ ] Integrate Midtrans payment
- [ ] Add QR code scanner
- [ ] Implement order history
- [ ] Add error handling
- [ ] Add loading states
- [ ] Test on real devices
- [ ] Optimize performance
- [ ] Build and deploy

## 🔄 Integration Points

### Backend Integration

- Products API untuk menampilkan produk
- Orders API untuk membuat dan tracking order
- Stock management untuk update stok real-time

### Frontend Integration

- Payment API untuk Midtrans transaction
- QR code generation untuk payment
- Payment status checking

## 📚 Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Provider Package](https://pub.dev/packages/provider)
- [Midtrans Mobile SDK](https://docs.midtrans.com/en/snap/integration-guide)
- [Material Design Guidelines](https://material.io/design)

## 🐛 Common Issues

### Android Network Issues

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<application android:usesCleartextTraffic="true">
```

### iOS Network Issues

Add to `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## 🔮 Future Enhancements

- [ ] Push notifications untuk order updates
- [ ] Loyalty program
- [ ] Product recommendations
- [ ] Wishlist feature
- [ ] Multiple payment methods
- [ ] Offline mode support
- [ ] Analytics integration

---

**Version**: 1.0.0  
**Last Updated**: October 7, 2025  
**Developer**: Vending Machine Team
