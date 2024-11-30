import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({Key? key}) : super(key: key);

  @override
  _MyAccountPageState createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _degreeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _gmailController = TextEditingController();
  String? _gender = 'Male';
  DateTime? _dob;
  bool _isEditing = false;

  String? _userId;

  @override
  void initState() {
    super.initState();
    _fetchUserIdAndData();
  }

  void _fetchUserIdAndData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      _userId = user.uid;
      _gmailController.text = user.email ?? '';
      await _loadUserData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No user logged in. Please log in first.")),
      );
    }
  }

  Future<void> _loadUserData() async {
    if (_userId != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          _nameController.text = data?['name'] ?? '';
          _degreeController.text = data?['degree'] ?? '';
          _phoneController.text = data?['phone'] ?? '';
          _addressController.text = data?['address'] ?? '';
          _gender = data?['gender'] ?? 'Male';
          _dob = (data?['dob'] as Timestamp?)?.toDate();
          _gmailController.text = data?['gmail'] ?? _gmailController.text;
        });
      }
    }
  }

  void _saveUserData() async {
    if (_formKey.currentState!.validate() && _userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(_userId).set({
        'name': _nameController.text,
        'degree': _degreeController.text,
        'phone': _phoneController.text,
        'gender': _gender,
        'dob': _dob,
        'address': _addressController.text,
        'gmail': _gmailController.text,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      setState(() {
        _isEditing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header Section
              CircleAvatar(
                radius: 40,
                backgroundColor: theme.primaryColor,
                child: const Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                _nameController.text.isEmpty ? 'Your Name' : _nameController.text,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _gmailController.text.isEmpty ? 'your.email@example.com' : _gmailController.text,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              // Form Section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField('Name', _nameController, _isEditing),
                        _buildTextField('Degree/Class', _degreeController, _isEditing),
                        _buildTextField('Phone', _phoneController, _isEditing, TextInputType.phone),
                        _buildTextField('Gmail', _gmailController, false, TextInputType.emailAddress),
                        _buildDropdown(),
                        _buildTextField('Address', _addressController, _isEditing),
                        _buildDateField(context),
                        const SizedBox(height: 16),
                        _buildActionButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool enabled, [TextInputType? inputType]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        enabled: enabled,
        keyboardType: inputType ?? TextInputType.text,
        validator: (value) => value?.isEmpty ?? true ? 'Please enter $label' : null,
      ),
    );
  }

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _gender,
        items: ['Male', 'Female', 'Other']
            .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
            .toList(),
        onChanged: _isEditing ? (value) => setState(() => _gender = value) : null,
        decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
      ),
    );
  }

  Widget _buildDateField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: TextEditingController(
          text: _dob == null ? '' : '${_dob!.toLocal()}'.split(' ')[0],
        ),
        decoration: const InputDecoration(labelText: 'Date of Birth', border: OutlineInputBorder()),
        readOnly: true,
        onTap: _isEditing
            ? () async {
          FocusScope.of(context).requestFocus(FocusNode());
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: _dob ?? DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (pickedDate != null && pickedDate != _dob) {
            setState(() {
              _dob = pickedDate;
            });
          }
        }
            : null,
      ),
    );
  }

  Widget _buildActionButton() {
    return ElevatedButton(
      onPressed: _isEditing ? _saveUserData : () => setState(() => _isEditing = true),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(_isEditing ? 'Save Changes' : 'Edit Profile'),
    );
  }
}
