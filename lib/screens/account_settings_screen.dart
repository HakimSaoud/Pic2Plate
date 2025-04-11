import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart'; // For multipart file upload
import 'package:untitled/components/base_auth.dart';
import 'package:untitled/components/base_auth_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isUploadingPicture = false; // Separate loading state for picture upload
  File? _selectedImage; // To store the picked image
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _usernameController.text = BaseAuth.getUsername() ?? 'User';
    _emailController.text = BaseAuth.getEmail() ?? '';
  }

  void _showCustomSnackBar(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  isSuccess
                      ? [Colors.green.shade700, Colors.green.shade400]
                      : [Colors.red.shade700, Colors.red.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      // Automatically upload the image after picking
      await _updateProfilePicture();
    }
  }

  Future<void> _updateProfilePicture() async {
    if (_selectedImage == null) {
      _showCustomSnackBar('No image selected', isSuccess: false);
      return;
    }

    setState(() => _isUploadingPicture = true);

    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('${BaseAuth.baseUrl}/update-profile'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer ${BaseAuth.getAccessToken()}';

      // Add current username and email to keep them unchanged
      request.fields['username'] = BaseAuth.getUsername() ?? '';
      request.fields['email'] = BaseAuth.getEmail() ?? '';

      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'profilePicture',
          _selectedImage!.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      // Send the request
      final response = await request.send();
      final responseBody = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody.body);
        if (data['newAccessToken'] is String) {
          BaseAuth.updateTokens(accessToken: data['newAccessToken']);
        }
        BaseAuth.updateUserDetails(
          username: data['user']['username'],
          email: data['user']['email'],
          profilePicture: data['user']['profilePicture'],
        );
        setState(() {
          _selectedImage = null; // Clear selected image after upload
        });
        _showCustomSnackBar('Profile picture updated successfully');
      } else {
        _showCustomSnackBar(
          'Failed to update profile picture',
          isSuccess: false,
        );
      }
    } catch (e) {
      _showCustomSnackBar(
        'Network error while updating profile picture',
        isSuccess: false,
      );
    } finally {
      setState(() => _isUploadingPicture = false);
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.put(
        Uri.parse('${BaseAuth.baseUrl}/update-profile'),
        headers: {
          'Authorization': 'Bearer ${BaseAuth.getAccessToken()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['newAccessToken'] is String) {
          BaseAuth.updateTokens(accessToken: data['newAccessToken']);
        }
        BaseAuth.updateUserDetails(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          profilePicture:
              data['user']['profilePicture'], // Preserve existing picture
        );
        setState(() {
          _isEditing = false;
        });
        _showCustomSnackBar('Profile updated successfully');
      } else {
        _showCustomSnackBar('Failed to update profile', isSuccess: false);
      }
    } catch (e) {
      _showCustomSnackBar(
        'Network error while updating profile',
        isSuccess: false,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await BaseAuth.logout();
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/signin',
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    String? profilePictureUrl = BaseAuth.getProfilePicture();

    return BaseAuthScreen(
      headerText: 'Account Settings',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFF123B42),
                        backgroundImage:
                            _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : (profilePictureUrl != null
                                        ? NetworkImage(
                                          '${BaseAuth.baseUrl}$profilePictureUrl',
                                        )
                                        : null)
                                    as ImageProvider?,
                        child:
                            profilePictureUrl == null && _selectedImage == null
                                ? const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 40,
                                )
                                : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUploadingPicture ? null : _pickImage,
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor: Colors.white,
                            child:
                                _isUploadingPicture
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF123B42),
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Icon(
                                      Icons.camera_alt,
                                      color: const Color(0xFF123B42),
                                      size: 20,
                                    ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child:
                        _isEditing
                            ? TextField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                hintText: 'Username',
                                hintStyle: const TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: const Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 15,
                                ),
                              ),
                            )
                            : Text(
                              BaseAuth.getUsername() ?? 'User',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF123B42),
                              ),
                            ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _isEditing
                  ? TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 15,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  )
                  : Text(
                    BaseAuth.getEmail() ?? 'No email provided',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        _isLoading
                            ? null
                            : (_isEditing
                                ? _updateProfile
                                : () => setState(() => _isEditing = true)),
                    icon:
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Icon(
                              _isEditing ? Icons.save : Icons.edit,
                              color: Colors.white,
                            ),
                    label: Text(
                      _isEditing ? 'Save' : 'Edit Profile',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF123B42),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                  ),
                  if (_isEditing)
                    ElevatedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                setState(() {
                                  _isEditing = false;
                                  _usernameController.text =
                                      BaseAuth.getUsername() ?? 'User';
                                  _emailController.text =
                                      BaseAuth.getEmail() ?? '';
                                });
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _logout(),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF123B42),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
