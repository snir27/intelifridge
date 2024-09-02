import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'add_product_screen.dart';

class ShoppingListScreen extends StatefulWidget {
  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    print("ShoppingListScreen initialized");
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateItemQuantity(String itemId, int newQuantity) async {
    if (newQuantity > 0) {
      await _firestore
          .collection('users')
          .doc(user!.uid)
          .collection('shopping_list')
          .doc(itemId)
          .update({
        'quantity': newQuantity,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print("Item $itemId updated to quantity $newQuantity");
    } else {
      await _deleteItem(itemId);
    }
  }

  Future<void> _deleteItem(String itemId) async {
    await _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('shopping_list')
        .doc(itemId)
        .delete();
    print("Item $itemId deleted from shopping list");
  }

  Future<void> _refreshList() async {
    setState(() {});
    print("List refreshed");
  }

  Future<void> _exportList() async {
    final shoppingList = await getShoppingList();
    String formattedList = "Shopping List:\n\n";

    for (var item in shoppingList) {
      formattedList += "${item['name']} - ${item['quantity']}\n";
    }

    await Share.share(formattedList, subject: 'My Shopping List');
    print("List exported");
  }

  Future<List<Map<String, dynamic>>> getShoppingList() async {
    print("Getting shopping list");
    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('shopping_list')
        .get();

    List<Map<String, dynamic>> shoppingList = [];
    for (var doc in snapshot.docs) {
      DocumentSnapshot productDoc =
          await _firestore.collection('products').doc(doc.id).get();

      shoppingList.add({
        'id': doc.id,
        'name': productDoc['name'] ?? 'Unknown Product',
        'quantity': doc['quantity'] ?? 0,
        'imageUrl': productDoc['imageUrl'] ?? '',
        'manuallyAdded': doc['manuallyAdded'] ?? false,
      });
    }
    print("Shopping list retrieved with ${shoppingList.length} items");
    return shoppingList;
  }

  Stream<List<Map<String, dynamic>>> getShoppingListStream() {
    print("Getting shopping list stream");
    return _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('shopping_list')
        .snapshots()
        .asyncMap((snapshot) async {
      print("Snapshot received with ${snapshot.docs.length} documents");
      List<Map<String, dynamic>> shoppingList = [];
      for (var doc in snapshot.docs) {
        DocumentSnapshot productDoc =
            await _firestore.collection('products').doc(doc.id).get();

        shoppingList.add({
          'id': doc.id,
          'name': productDoc['name'] ?? 'Unknown Product',
          'quantity': doc['quantity'] ?? 0,
          'imageUrl': productDoc['imageUrl'] ?? '',
          'manuallyAdded': doc['manuallyAdded'] ?? false,
        });
      }
      print("Shopping list processed with ${shoppingList.length} items");
      return shoppingList;
    });
  }

  void _navigateToAddProductScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddProductScreen()),
    );
    print("Navigated to AddProductScreen");
  }

  Future<void> _toggleManuallyAdded(String itemId, bool currentStatus) async {
    await _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('shopping_list')
        .doc(itemId)
        .update({
      'manuallyAdded': !currentStatus,
    });
    print("Item $itemId manuallyAdded status toggled to ${!currentStatus}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.grey[200],
        child: SafeArea(
          child: Container(
            margin: EdgeInsets.all(20),
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
                _buildShoppingListTop(),
                _buildSearchBar(),
                Expanded(
                  child: _buildShoppingListContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShoppingListTop() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade800, Colors.purple.shade800],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 20),
            child: Text(
              'Shopping List',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white),
                onPressed: _refreshList,
              ),
              IconButton(
                icon: Icon(Icons.share, color: Colors.white),
                onPressed: _exportList,
              ),
              IconButton(
                icon: Icon(Icons.add, color: Colors.white),
                onPressed: _navigateToAddProductScreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search items...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.blue.shade800),
          ),
        ),
      ),
    );
  }

  Widget _buildShoppingListContent() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: getShoppingListStream(),
      builder: (context, snapshot) {
        print("StreamBuilder rebuilding, connection state: ${snapshot.connectionState}");
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print("Error in StreamBuilder: ${snapshot.error}");
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          print("No data in snapshot");
          return _buildEmptyState();
        }

        List<Map<String, dynamic>> filteredList = snapshot.data!.where((item) {
          return item['name']
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
        }).toList();

        // Sort the filtered list
        filteredList.sort((a, b) {
          // First, sort by manuallyAdded (false comes first)
          int manuallyAddedComparison = a['manuallyAdded'].toString().compareTo(b['manuallyAdded'].toString());
          if (manuallyAddedComparison != 0) {
            return manuallyAddedComparison;
          }
          // If manuallyAdded is the same, sort alphabetically by name
          return a['name'].toLowerCase().compareTo(b['name'].toLowerCase());
        });

        print("Filtered and sorted list contains ${filteredList.length} items");

        if (filteredList.isEmpty) {
          return Center(
            child: Text(
              "No items match your search.",
              style: GoogleFonts.poppins(fontSize: 20, color: Colors.black87),
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.7,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            Map<String, dynamic> item = filteredList[index];
            print("Building item: ${item['name']}, manuallyAdded: ${item['manuallyAdded']}");
            return ShoppingItemCard(
              itemId: item['id'],
              data: item,
              onQuantityChanged: _updateItemQuantity,
              onManuallyAddedToggled: _toggleManuallyAdded,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 60,
              color: Colors.blue.shade800,
            ),
            const SizedBox(height: 20),
            Text(
              "All your items are in the fridge!",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Add items manually or wait until you need to restock.",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _navigateToAddProductScreen,
              child: Text("Add Items Manually"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShoppingItemCard extends StatelessWidget {
  final String itemId;
  final Map<String, dynamic> data;
  final Function(String, int) onQuantityChanged;
  final Function(String, bool) onManuallyAddedToggled;

  const ShoppingItemCard({
    required this.itemId,
    required this.data,
    required this.onQuantityChanged,
    required this.onManuallyAddedToggled,
  });

  @override
  Widget build(BuildContext context) {
    print("Building ShoppingItemCard for ${data['name']}");
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: GestureDetector(
              onLongPress: () {
                onManuallyAddedToggled(itemId, data['manuallyAdded']);
              },
              child: Stack(
                children: [
                  if (data['imageUrl'].isNotEmpty)
                    ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        data['imageUrl'],
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
                  else
                    Icon(Icons.image, size: 60, color: Colors.grey.shade400),
                  if (!data['manuallyAdded'])
                    const Positioned(
                      top: 5,
                      right: 5,
                      child: Icon(
                        Icons.auto_awesome,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: data['manuallyAdded'] ? Colors.blue[50] : Colors.orange[50],
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data['name'],
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: data['manuallyAdded'] ? Colors.blue.shade800 : Colors.orange.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  _buildQuantityControls(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControls() {
    if (!data['manuallyAdded']) {
      // For automatically added items, just show the quantity
      return Text(
        'Total: ${data['quantity']}',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 12,
          color: Colors.orange.shade800,
        ),
      );
    } else {
      // For manually added items, show controls
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: () {
              if (data['quantity'] > 1) {
                onQuantityChanged(itemId, data['quantity'] - 1);
              } else {
                onQuantityChanged(itemId, 0); // This will trigger item deletion
              }
            },
            child: Icon(
              data['quantity'] > 1 ? Icons.remove_circle : Icons.delete,
              size: 20,
              color: data['quantity'] > 1 ? Colors.blue.shade600 : Colors.red,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '${data['quantity']}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: Colors.blue.shade800,
              ),
            ),
          ),
          InkWell(
            onTap: () => onQuantityChanged(itemId, data['quantity'] + 1),
            child: Icon(Icons.add_circle,
                size: 20, color: Colors.blue.shade600),
          ),
        ],
      );
    }
  }
}
