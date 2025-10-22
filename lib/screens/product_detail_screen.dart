import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../utils/helpers.dart';
import '../theme/app_theme.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  bool _isFavorite = false;

  void _showSuccessToast() {
    Fluttertoast.showToast(
      msg: "✓ Berhasil ditambahkan ke keranjang",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 2,
      backgroundColor: const Color(0xFF4CAF50),
      textColor: Colors.white,
      fontSize: 14.0,
      webBgColor: "linear-gradient(to right, #4CAF50, #45A049)",
      webPosition: "center",
    );
  }

  void _addToCart() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (_quantity > widget.product.stock) {
      Fluttertoast.showToast(
        msg: "⚠ Stok tidak mencukupi",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 14.0,
      );
      return;
    }

    cartProvider.addItem(widget.product, _quantity);
    _showSuccessToast();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Scrollable Content
          CustomScrollView(
            slivers: [
              // App Bar with Image
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                backgroundColor: Colors.white,
                leading: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.black87,
                      size: 20,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isFavorite = !_isFavorite;
                      });
                      Fluttertoast.showToast(
                        msg: _isFavorite
                            ? "♥ Ditambahkan ke favorit"
                            : "Dihapus dari favorit",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: _isFavorite
                            ? Colors.red
                            : Colors.grey.shade600,
                        textColor: Colors.white,
                        fontSize: 14.0,
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.black87,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: 'product-${widget.product.id}',
                    child: Container(
                      color: Colors.white,
                      child:
                          (widget.product.imageUrl != null &&
                              widget.product.imageUrl!.isNotEmpty)
                          ? Image.network(
                              Helpers.getImageUrl(widget.product.imageUrl),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.medical_services,
                                    size: 120,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            )
                          : const Center(
                              child: Icon(
                                Icons.medical_services,
                                size: 120,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category
                        if (widget.product.category.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.product.category,
                              style: const TextStyle(
                                color: AppTheme.primaryBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),

                        // Product Name
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Price
                        Text(
                          Helpers.formatCurrency(widget.product.price),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Stock Info
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 18,
                              color: widget.product.stock > 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.product.stock > 0
                                  ? 'Stok: ${widget.product.stock}'
                                  : 'Stok Habis',
                              style: TextStyle(
                                fontSize: 14,
                                color: widget.product.stock > 0
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Description
                        const Text(
                          'Deskripsi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.product.description.isNotEmpty
                              ? widget.product.description
                              : 'Tidak ada deskripsi untuk produk ini.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Similar Products Section
                        const Text(
                          'Similar this',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Similar Products Horizontal List
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 3,
                            itemBuilder: (context, index) {
                              return Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.medical_services,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Product',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 100), // Space for bottom bar
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Bottom Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Quantity Control
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              if (_quantity > 1) {
                                setState(() {
                                  _quantity--;
                                });
                              }
                            },
                            child: Container(
                              width: 40,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  bottomLeft: Radius.circular(10),
                                ),
                              ),
                              child: const Icon(Icons.remove, size: 20),
                            ),
                          ),
                          Container(
                            width: 50,
                            alignment: Alignment.center,
                            child: Text(
                              _quantity.toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              if (_quantity < widget.product.stock) {
                                setState(() {
                                  _quantity++;
                                });
                              }
                            },
                            child: Container(
                              width: 40,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),
                              ),
                              child: const Icon(Icons.add, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Add to Cart Button
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.product.stock > 0 ? _addToCart : null,
                            borderRadius: BorderRadius.circular(12),
                            child: const Center(
                              child: Text(
                                'Add To Cart',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
