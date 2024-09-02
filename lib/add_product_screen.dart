import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Map<String, int> _productQuantities = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    print("AddProductScreen initialized");
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<DocumentSnapshot>> getProductsStream() {
    print("Getting products stream");
    return _firestore
        .collection('products')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      print("Snapshot received with ${snapshot.docs.length} documents");
      return snapshot.docs;
    });
  }

  Future<void> _addToShoppingList(DocumentSnapshot product) async {
    final userShoppingListRef = _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('shopping_list');

    try {
      final quantity = _productQuantities[product.id] ?? 1;
      final existingItem = await userShoppingListRef.doc(product.id).get();

      if (existingItem.exists) {
        await userShoppingListRef.doc(product.id).update({
          'quantity': FieldValue.increment(quantity),
          'lastUpdated': FieldValue.serverTimestamp(),
          'manuallyAdded': true,
        });
      } else {
        await userShoppingListRef.doc(product.id).set({
          'quantity': quantity,
          'lastUpdated': FieldValue.serverTimestamp(),
          'manuallyAdded': true,
          'name': product['name'],
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product['name']} (x$quantity) added to shopping list')),
      );
      print("${product['name']} (x$quantity) added to shopping list");
      
      // Reset the quantity for this product
      setState(() {
        _productQuantities[product.id] = 1;
      });
    } catch (e) {
      print('Error adding product to shopping list: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add product. Please try again.')),
      );
    }
  }

  void _updateQuantity(String productId, int delta) {
    setState(() {
      _productQuantities[productId] = (_productQuantities[productId] ?? 1) + delta;
      if (_productQuantities[productId]! < 1) {
        _productQuantities[productId] = 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.grey[200],
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                _buildAddProductsTop(),
                _buildSearchBar(),
                Expanded(
                  child: _buildProductList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddProductsTop() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade800, Colors.purple.shade800],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              'Add Products',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.blue.shade800),
          ),
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return StreamBuilder<List<DocumentSnapshot>>(
      stream: getProductsStream(),
      builder: (context, snapshot) {
        print("StreamBuilder rebuilding, connection state: ${snapshot.connectionState}");
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print("Error in StreamBuilder: ${snapshot.error}");
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          print("No data in snapshot");
          return Center(
            child: Text(
              "No products available.",
              style: GoogleFonts.poppins(fontSize: 20, color: Colors.black87),
            ),
          );
        }

        List<DocumentSnapshot> filteredList = snapshot.data!.where((doc) {
          final name = doc['name'].toString().toLowerCase();
          final query = _searchQuery.toLowerCase();
          return name.startsWith(query) || name.contains(query);
        }).toList();

        print("Filtered list contains ${filteredList.length} items");

        if (filteredList.isEmpty) {
          return Center(
            child: Text(
              "No products match your search.",
              style: GoogleFonts.poppins(fontSize: 20, color: Colors.black87),
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            DocumentSnapshot product = filteredList[index];
            return _buildProductRow(product);
          },
        );
      },
    );
  }

  Widget _buildProductRow(DocumentSnapshot product) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: product['imageUrl'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product['imageUrl'],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  )
                : Icon(Icons.image, size: 60, color: Colors.grey.shade400),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Colors.blue.shade800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    InkWell(
                      onTap: () => _updateQuantity(product.id, -1),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.remove, size: 14, color: Colors.red),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_productQuantities[product.id] ?? 1}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _updateQuantity(product.id, 1),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, size: 14, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _addToShoppingList(product),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_shopping_cart, size: 24, color: Colors.blue.shade800),
            ),
          ),
        ],
      ),
    ),
  );
}
}
