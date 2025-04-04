import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:untitled/components/base_auth.dart';
import 'package:untitled/components/base_auth_screen.dart';
import 'package:untitled/components/custom_snackbar.dart';

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

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) {
      SnackBarUtils.showCustomSnackBar(
        context,
        'No image selected',
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _image = pickedFile;
      _isUploading = true;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${BaseAuth.baseUrl}/upload-ingredients'),
      );
      request.headers['Authorization'] = 'Bearer ${BaseAuth.getAccessToken()}';
      request.fields['refreshToken'] = BaseAuth.getRefreshToken() ?? '';
      request.files.add(
        await http.MultipartFile.fromPath('image', pickedFile.path),
      );

      final response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timed out'),
      );

      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (response.statusCode == 201) {
        if (data['newAccessToken'] is String) {
          BaseAuth.updateTokens(accessToken: data['newAccessToken']);
        }
        final ingredient = data['ingredient'] ?? 'unknown';
        final confidence = data['confidence'] ?? '0.00';
        SnackBarUtils.showCustomSnackBar(
          context,
          'Identified: $ingredient ($confidence%)',
        );
        setState(() => _image = null);
      } else if (response.statusCode == 200) {
        final ingredient = data['ingredient'] ?? 'unknown';
        SnackBarUtils.showCustomSnackBar(context, '$ingredient already exists');
        setState(() => _image = null);
      } else {
        SnackBarUtils.showCustomSnackBar(
          context,
          'Failed to upload ingredient. Please try again.',
          isSuccess: false,
        );
      }
    } catch (e) {
      SnackBarUtils.showCustomSnackBar(
        context,
        'Failed to upload due to a network issue.',
        isSuccess: false,
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseAuthScreen(
      headerText: 'Add Ingredients',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isUploading
                            ? null
                            : () => _pickAndUploadImage(ImageSource.camera),
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
                            : const Icon(Icons.camera_alt, color: Colors.white),
                    label: Text(
                      _isUploading ? 'Uploading...' : 'Take Photo',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF123B42),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isUploading
                            ? null
                            : () => _pickAndUploadImage(ImageSource.gallery),
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
                            : const Icon(
                              Icons.photo_library,
                              color: Colors.white,
                            ),
                    label: Text(
                      _isUploading ? 'Uploading...' : 'From Gallery',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF123B42),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
