import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../widgets/custom_button.dart';
import '../profile/profile_screen.dart';
import '../analysis/loading_screen.dart';
import '../analysis/results_screen.dart';
import '../../../data/providers/auth_provider.dart' as app;
import '../../../data/models/skin_analysis_result.dart';
import '../../../data/services/recommendation_engine.dart';
import 'package:path_provider/path_provider.dart';
import '../../../data/services/gemini_vision_service.dart';
import '../../../data/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../profile/privacy_permissions_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Ready for your next skin analysis?',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: const CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: NetworkImage(
                        'https://i.pravatar.cc/150?img=5',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Main Card Section
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Icon(
                          Icons.face_retouching_natural,
                          size: 120,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Start Your Skin Analysis',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            'Take or upload a clear photo to get your personalized skin analysis.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40.0),
                          child: CustomButton(
                            text: 'Start Analysis',
                            onPressed: () => _showImageSourceModal(context),
                          ),
                        ),
                        const SizedBox(height: 20),
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

  void _showImageSourceModal(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final cameraPref = prefs.getBool('camera_access') ?? false;
    final galleryPref = prefs.getBool('photo_library_access') ?? true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Text(
                  'Add your photo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              _buildModalOption(
                icon: Icons.photo_camera,
                title: 'Take Photo',
                subtitle: 'Use your camera to capture a clear image.',
                onTap: () async {
                  Navigator.pop(modalContext);
                  if (!cameraPref) {
                    _showPermissionDeniedDialog(context, 'camera');
                    return;
                  }
                  // Request camera permission manually
                  final status = await Permission.camera.request();
                  if (!status.isGranted) {
                    if (status.isPermanentlyDenied) {
                      _showPermissionDeniedDialog(
                        context,
                        'camera',
                        isPermanent: true,
                      );
                    } else {
                      _showPermissionDeniedDialog(context, 'camera');
                    }
                    return;
                  }
                  _handleImageUpload(ImageSource.camera, context);
                },
              ),
              const SizedBox(height: 12),
              _buildModalOption(
                icon: Icons.photo_library,
                title: 'Upload Photo',
                subtitle: 'Choose a photo from your gallery.',
                onTap: () async {
                  Navigator.pop(modalContext);
                  if (!galleryPref) {
                    _showPermissionDeniedDialog(context, 'gallery');
                    return;
                  }
                  _handleImageUpload(ImageSource.gallery, context);
                },
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(modalContext),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Also update your _showPermissionDeniedDialog to accept isPermanent:
  void _showPermissionDeniedDialog(
    BuildContext context,
    String type, {
    bool isPermanent = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${type == 'camera' ? 'Camera' : 'Photo Library'} Access Denied',
        ),
        content: Text(
          isPermanent
              ? 'You have permanently denied access. Please enable it in device settings.'
              : (type == 'camera'
                    ? 'You have disabled camera access. Please enable it to take photos.'
                    : 'You have disabled photo library access. Please enable it to upload images.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // ✅ Navigate to the in‑app Privacy & Permissions screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPermissionsScreen(),
                ),
              );
            },
            child: const Text('Go to Privacy'),
          ),
        ],
      ),
    );
  }

  void _handleImageUpload(ImageSource source, BuildContext context) async {
    final authProvider = Provider.of<app.AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image == null) return;

    final File imageFile = File(image.path);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoadingScreen()),
    );

    try {
      final String localPath = await _saveImageLocally(imageFile);

      const apiKey = 'AIzaSyC5yoKSZZeW20zwfWuuuSt0nl9Xx-T94uc';
      final geminiService = GeminiVisionService(apiKey);
      final analysisJson = await geminiService.analyzeSkin(imageFile);

      final analysis = SkinAnalysisResult.fromJson(analysisJson);
      final analysisWithPhoto = analysis.copyWith(photoUrl: localPath);

      final prefs = await SharedPreferences.getInstance();
      final bool saveHistory = prefs.getBool('save_analysis_history') ?? true;

      final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
      if (saveHistory) {
        await dbHelper.saveAnalysisSession(analysisWithPhoto);
      }
      final engine = RecommendationEngine(dbHelper);
      final routine = await engine.generateRoutine(analysisWithPhoto);

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsScreen(
              analysisData: analysisWithPhoto,
              routine: routine,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Analysis error: $e');
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<String> _saveImageLocally(File imageFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final localPath = '${directory.path}/skin_analysis_$timestamp.jpg';
    await imageFile.copy(localPath);
    return localPath;
  }

  Widget _buildModalOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade600, size: 28),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
