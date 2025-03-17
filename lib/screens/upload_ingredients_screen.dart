import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:untitled/components/base_auth.dart';
import 'package:untitled/components/base_auth_screen.dart';

class UploadIngredientsScreen extends StatefulWidget {
  const UploadIngredientsScreen({super.key});

  @override
  State<UploadIngredientsScreen> createState() =>
      _UploadIngredientsScreenState();
}

class _UploadIngredientsScreenState extends State<UploadIngredientsScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await BaseAuth.redirectIfNotAuthenticated(context);
  }

  Future<void> _pickAndUploadImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
        _isUploading = true;
      });

      try {
        print('Preparing to upload image: ${pickedFile.path}'); // Debug
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('${BaseAuth.baseUrl}/upload-ingredients'),
        );
        request.headers['Authorization'] =
            'Bearer ${BaseAuth.getAccessToken()}';
        request.fields['refreshToken'] = BaseAuth.getRefreshToken() ?? '';
        request.files.add(
          await http.MultipartFile.fromPath('image', pickedFile.path),
        );

        print('Sending request to server...'); // Debug
        final response = await request.send().timeout(
          const Duration(seconds: 30), // Add timeout
          onTimeout: () {
            throw Exception('Request timed out after 30 seconds');
          },
        );
        print('Response status: ${response.statusCode}'); // Debug

        final responseBody = await response.stream.bytesToString();
        print('Response body: $responseBody'); // Debug
        final data = jsonDecode(responseBody);

        if (response.statusCode == 201) {
          if (data['newAccessToken'] != null &&
              data['newAccessToken'] is String) {
            BaseAuth.updateTokens(accessToken: data['newAccessToken']);
          }
          final ingredient = data['ingredient'] ?? 'unknown';
          final confidence = data['confidence'] ?? '0.00';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ingredient identified: $ingredient ($confidence%)',
              ),
            ),
          );
          setState(() => _image = null);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Upload failed: ${data['error'] ?? 'Unknown error'}',
              ),
            ),
          );
        }
      } catch (e) {
        print('Upload error: $e'); // Debug
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      } finally {
        setState(() => _isUploading = false);
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No image selected.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseAuthScreen(
      headerText: 'Upload Ingredients',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Capture or select an ingredient image',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF123B42),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey, width: 1),
              ),
              child:
                  _image == null
                      ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 80,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No image selected',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      )
                      : ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          File(_image!.path),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 250,
                        ),
                      ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickAndUploadImage,
              icon:
                  _isUploading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Icon(Icons.upload, color: Colors.white),
              label: Text(
                _isUploading ? 'Uploading...' : 'Upload Picture',
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
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed:
                  () => Navigator.pushNamed(context, '/view-ingredients'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF123B42),
                side: const BorderSide(color: Color(0xFF123B42), width: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'View All Ingredients',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF123B42),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
