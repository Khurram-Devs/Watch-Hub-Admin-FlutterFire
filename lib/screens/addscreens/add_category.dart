import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  _AddCategoryScreenState createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen>
    with SingleTickerProviderStateMixin {
  // Controllers and variables
  TextEditingController categoryController = TextEditingController();
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool isActive = true; // Default active status
  bool isLoading = false;
  String selectedType = "1"; // Default to Brand (type = "1")

  // Type options
  final List<Map<String, String>> typeOptions = [
    {"value": "1", "label": "Brand"},
    {"value": "2", "label": "Type"},
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Slide animation from bottom to top
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start animation when screen loads
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    categoryController.dispose();
    super.dispose();
  }

  // Function to handle the category submission with animation
  void addCategory() async {
    String category = categoryController.text.trim();
    print(category);

    if (category.isNotEmpty) {
      setState(() {
        isLoading = true;
      });

      try {
        DatabaseReference dr = FirebaseDatabase.instance.ref().child(
          "Category",
        );

        // Adding the category to the database with timestamp, active status, and type
        await dr.push().set({
          'Name': category,
          'type': selectedType, // Add type field
          'isActive': isActive,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });

        // Show success animation and snackbar
        _showSuccessAnimation();

        String typeLabel = typeOptions.firstWhere((option) => option['value'] == selectedType)['label']!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Text('$typeLabel "$category" added successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Clear the input field
        categoryController.clear();
        setState(() {
          isActive = true; // Reset to default
          selectedType = "1"; // Reset to default
        });
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 10),
                Text('Failed to add category: $error'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 10),
              Text('Please enter a category name.'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessAnimation() {
    // Reset and replay animation for success feedback
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5B8A9A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Category',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false, // Aligns title to the left
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header Icon and Title
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B8A9A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.category,
                    size: 40,
                    color: Color(0xFF5B8A9A),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Create New Category',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'Enter a name for your new category',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 40),

                // Category Type Selection Dropdown
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Category Type',
                        prefixIcon: Icon(
                          Icons.label_outline,
                          color: Color(0xFF5B8A9A),
                        ),
                        border: InputBorder.none,
                        labelStyle: TextStyle(color: Color(0xFF5B8A9A)),
                      ),
                      dropdownColor: Colors.white,
                      items: typeOptions.map((option) {
                        return DropdownMenuItem<String>(
                          value: option['value'],
                          child: Row(
                            children: [
                              Icon(
                                option['value'] == '1' ? Icons.branding_watermark : Icons.style,
                                color: const Color(0xFF5B8A9A),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                option['label']!,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedType = value!;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Category input field with modern design
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: categoryController,
                    decoration: InputDecoration(
                      labelText: selectedType == '1' ? 'Brand Name' : 'Type Name',
                      hintText: selectedType == '1' ? 'e.g., Rolex, Nike, Apple' : 'e.g., automatic, android, mens',
                      prefixIcon: Icon(
                        selectedType == '1' ? Icons.branding_watermark : Icons.style,
                        color: const Color(0xFF5B8A9A),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                      labelStyle: const TextStyle(color: Color(0xFF5B8A9A)),
                      hintStyle: TextStyle(color: Colors.grey[400]),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),

                // Active Status Toggle
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isActive ? Icons.toggle_on : Icons.toggle_off,
                              color: isActive ? Colors.green : Colors.grey,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Active Status',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: isActive,
                          onChanged: (value) {
                            setState(() {
                              isActive = value;
                            });
                          },
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Submit button with loading state
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : addCategory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B8A9A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                    ),
                    child:
                        isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Add ${selectedType == '1' ? 'Brand' : 'Type'}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}