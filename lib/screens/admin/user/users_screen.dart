import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({Key? key}) : super(key: key);

  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _selectedRole = 'student'; // Default role

  bool _isLoading = false;
  QuerySnapshot? users;
  List<QueryDocumentSnapshot<Object?>>? filteredUsers;

  final List<String> roles = const [
    'student',
    'colab',
    'admin'
  ]; // Fixed order of roles

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      getFilteredUsers(_searchController.text);
    });
    refresh();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    getFilteredUsers(_searchController.text);
  }

  Future<void> getUsers() async {
    try {
      setState(() => _isLoading = true);

      // Modify query to correctly fetch users
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('deleted_at', isNull: true)
          .get();

      setState(() {
        users = snapshot;
        filteredUsers = snapshot.docs;
      });

      print('Loaded ${snapshot.docs.length} users'); // Debug log
    } catch (e) {
      print('Error loading users: $e'); // Debug log
      _showError('Error loading users: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void getFilteredUsers(String value) {
    if (users == null) return;

    try {
      final searchTerm = value.toLowerCase();
      setState(() {
        filteredUsers = value.isEmpty
            ? users?.docs
            : users?.docs.where((doc) {
                final username =
                    doc['username']?.toString().toLowerCase() ?? '';
                final email = doc['email']?.toString().toLowerCase() ?? '';
                final role = doc['role']?.toString().toLowerCase() ?? '';
                return username.contains(searchTerm) ||
                    email.contains(searchTerm) ||
                    role.contains(searchTerm);
              }).toList();
      });
    } catch (e) {
      print('Error filtering users: $e'); // Debug log
    }
  }

  Future<void> softDeleteUser(String userId) async {
    try {
      setState(() => _isLoading = true);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'deleted_at': FieldValue.serverTimestamp()});
      refresh();
      _showSuccess('User deleted successfully');
    } catch (e) {
      _showError('Error deleting user');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> addUser(String username, String role) async {
    try {
      if (username.isEmpty) {
        _showError('Username is required');
        return;
      }

      if (!roles.contains(role)) {
        _showError('Invalid role selected');
        return;
      }

      setState(() => _isLoading = true);

      // Check for existing user
      final existing = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .where('deleted_at', isNull: true)
          .get();

      if (existing.docs.isNotEmpty) {
        _showError('Username already exists');
        return;
      }

      await FirebaseFirestore.instance.collection('users').add({
        'username': username,
        'email': null, // Always set email to null for new users
        'role': role,
        'created_at': FieldValue.serverTimestamp(),
        'deleted_at': null,
        'biometric': false,
      });

      refresh();
      _showSuccess('User added successfully');
    } catch (e) {
      _showError('Error adding user');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void refresh() async {
    await getUsers();
    getFilteredUsers(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search users',
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredUsers == null || filteredUsers!.isEmpty
              ? const Center(child: Text('No users found'))
              : ListView.builder(
                  itemCount: filteredUsers!.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers![index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text(user['username'] ?? 'No username'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['email'] ?? 'No email'),
                            Text('Role: ${user['role']}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditDialog(user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteDialog(user),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog() {
    _selectedRole = 'student'; // Default role
    _usernameController.clear();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        // Use StatefulBuilder here too
        builder: (context, setState) => AlertDialog(
          title: const Text('Add User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: roles.map((String role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedRole = newValue;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _usernameController.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_selectedRole.isNotEmpty) {
                  addUser(_usernameController.text, _selectedRole);
                  _usernameController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(DocumentSnapshot user) {
    _usernameController.text = user['username'] ?? '';
    // Validate role value before setting
    String userRole = user['role'] ?? 'student';
    _selectedRole = roles.contains(userRole) ? userRole : 'student';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        // Use StatefulBuilder to handle state changes
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: roles.map((String role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null && roles.contains(newValue)) {
                    setState(() => _selectedRole = newValue);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _usernameController.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_selectedRole.isNotEmpty && roles.contains(_selectedRole)) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.id)
                      .update({
                    'username': _usernameController.text,
                    'role': _selectedRole,
                  });
                  _usernameController.clear();
                  Navigator.pop(context);
                  refresh();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(DocumentSnapshot user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete ${user['username']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              softDeleteUser(user.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
