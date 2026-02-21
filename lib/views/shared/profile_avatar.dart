import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:project_management/services/profile_photo_service.dart';

// ==================== PRESET AVATARS ====================
class PresetAvatar {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  const PresetAvatar({
    required this.icon,
    required this.backgroundColor,
    this.iconColor = Colors.white,
  });
}

const List<PresetAvatar> presetAvatars = [
  PresetAvatar(icon: Icons.person, backgroundColor: Color(0xFF4285F4)),
  PresetAvatar(icon: Icons.person, backgroundColor: Color(0xFFEA4335)),
  PresetAvatar(icon: Icons.person, backgroundColor: Color(0xFF34A853)),
  PresetAvatar(
    icon: Icons.person,
    backgroundColor: Color(0xFFFBBC05),
    iconColor: Colors.white,
  ),
  PresetAvatar(icon: Icons.person, backgroundColor: Color(0xFF9C27B0)),
  PresetAvatar(icon: Icons.person, backgroundColor: Color(0xFF00BCD4)),
  PresetAvatar(icon: Icons.face, backgroundColor: Color(0xFF4285F4)),
  PresetAvatar(icon: Icons.face, backgroundColor: Color(0xFFEA4335)),
  PresetAvatar(icon: Icons.face, backgroundColor: Color(0xFF34A853)),
  PresetAvatar(icon: Icons.face, backgroundColor: Color(0xFF9C27B0)),
  PresetAvatar(icon: Icons.face_2, backgroundColor: Color(0xFF00BCD4)),
  PresetAvatar(
    icon: Icons.face_2,
    backgroundColor: Color(0xFFFBBC05),
    iconColor: Colors.white,
  ),
  PresetAvatar(icon: Icons.face_3, backgroundColor: Color(0xFF4285F4)),
  PresetAvatar(icon: Icons.face_3, backgroundColor: Color(0xFFEA4335)),
  PresetAvatar(icon: Icons.face_4, backgroundColor: Color(0xFF34A853)),
  PresetAvatar(icon: Icons.face_4, backgroundColor: Color(0xFF9C27B0)),
  PresetAvatar(icon: Icons.face_5, backgroundColor: Color(0xFF00BCD4)),
  PresetAvatar(icon: Icons.face_5, backgroundColor: Color(0xFF4285F4)),
  PresetAvatar(icon: Icons.face_6, backgroundColor: Color(0xFFEA4335)),
  PresetAvatar(icon: Icons.face_6, backgroundColor: Color(0xFF34A853)),
  PresetAvatar(
    icon: Icons.sentiment_satisfied_alt,
    backgroundColor: Color(0xFF9C27B0),
  ),
  PresetAvatar(
    icon: Icons.sentiment_satisfied_alt,
    backgroundColor: Color(0xFF00BCD4),
  ),
  PresetAvatar(icon: Icons.emoji_emotions, backgroundColor: Color(0xFF4285F4)),
  PresetAvatar(
    icon: Icons.emoji_emotions,
    backgroundColor: Color(0xFFFBBC05),
    iconColor: Colors.white,
  ),
];

// ==================== PROFILE AVATAR WIDGET ====================
class ProfileAvatarWidget extends StatefulWidget {
  final double radius;
  final Color defaultColor;
  final VoidCallback? onChanged;

  const ProfileAvatarWidget({
    Key? key,
    this.radius = 50,
    this.defaultColor = const Color(0xFFE5A72E),
    this.onChanged,
  }) : super(key: key);

  @override
  State<ProfileAvatarWidget> createState() => _ProfileAvatarWidgetState();
}

class _ProfileAvatarWidgetState extends State<ProfileAvatarWidget> {
  String _photoType = 'none'; // 'none', 'image', 'avatar'
  String _photoPath = '';
  int _avatarIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedAvatar();
  }

  Future<void> _loadSavedAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _photoType = prefs.getString('profilePhotoType') ?? 'none';
      _photoPath = prefs.getString('profilePhotoPath') ?? '';
      _avatarIndex = prefs.getInt('profileAvatarIndex') ?? 0;
    });
  }

  Future<String> _getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email') ?? '';
  }

  Future<void> _saveAvatar({
    required String type,
    String path = '',
    int index = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profilePhotoType', type);
    await prefs.setString('profilePhotoPath', path);
    await prefs.setInt('profileAvatarIndex', index);
    setState(() {
      _photoType = type;
      _photoPath = path;
      _avatarIndex = index;
    });
    widget.onChanged?.call();

    // Sync with backend
    final email = await _getUserEmail();
    if (email.isNotEmpty) {
      if (type == 'avatar') {
        ProfilePhotoService.setAvatar(email, index);
      } else if (type == 'none') {
        ProfilePhotoService.removePhoto(email);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked != null) {
        // Save to app directory for persistence
        final appDir = await getApplicationDocumentsDirectory();
        final savedPath = '${appDir.path}/profile_photo.jpg';
        final savedFile = await File(picked.path).copy(savedPath);
        await _saveAvatar(type: 'image', path: savedFile.path);

        // Upload to server
        final email = await _getUserEmail();
        if (email.isNotEmpty) {
          ProfilePhotoService.uploadImage(email, savedFile.path);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Profile Photo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildOptionButton(
                        icon: Icons.camera_alt,
                        label: 'Camera',
                        color: const Color(0xFF4285F4),
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                      _buildOptionButton(
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        color: const Color(0xFF34A853),
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                      _buildOptionButton(
                        icon: Icons.emoji_emotions,
                        label: 'Avatars',
                        color: const Color(0xFFFBBC05),
                        onTap: () {
                          Navigator.pop(context);
                          _showAvatarPicker();
                        },
                      ),
                      if (_photoType != 'none')
                        _buildOptionButton(
                          icon: Icons.delete_outline,
                          label: 'Remove',
                          color: const Color(0xFFEA4335),
                          onTap: () {
                            Navigator.pop(context);
                            _saveAvatar(type: 'none');
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.85,
            expand: false,
            builder:
                (context, scrollController) => Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Choose an Avatar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: presetAvatars.length,
                        itemBuilder: (context, index) {
                          final avatar = presetAvatars[index];
                          final isSelected =
                              _photoType == 'avatar' && _avatarIndex == index;
                          return GestureDetector(
                            onTap: () {
                              _saveAvatar(type: 'avatar', index: index);
                              Navigator.pop(context);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    isSelected
                                        ? Border.all(
                                          color: const Color(0xFFE5A72E),
                                          width: 3,
                                        )
                                        : null,
                              ),
                              child: CircleAvatar(
                                backgroundColor: avatar.backgroundColor,
                                child: Icon(
                                  avatar.icon,
                                  color: avatar.iconColor,
                                  size: 32,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showPhotoOptions,
      child: Stack(
        children: [
          _buildAvatar(),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE5A72E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                Icons.camera_alt,
                size: widget.radius * 0.3,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    switch (_photoType) {
      case 'image':
        final file = File(_photoPath);
        if (file.existsSync()) {
          return CircleAvatar(
            radius: widget.radius,
            backgroundImage: FileImage(file),
          );
        }
        return _defaultAvatar();
      case 'avatar':
        if (_avatarIndex >= 0 && _avatarIndex < presetAvatars.length) {
          final avatar = presetAvatars[_avatarIndex];
          return CircleAvatar(
            radius: widget.radius,
            backgroundColor: avatar.backgroundColor,
            child: Icon(
              avatar.icon,
              size: widget.radius * 0.9,
              color: avatar.iconColor,
            ),
          );
        }
        return _defaultAvatar();
      default:
        return _defaultAvatar();
    }
  }

  Widget _defaultAvatar() {
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: Colors.white,
      child: Icon(
        Icons.person,
        size: widget.radius * 0.9,
        color: widget.defaultColor,
      ),
    );
  }
}

// ==================== STATIC HELPER ====================
/// Use this to display the avatar without the edit button (e.g. in home screens)
class ProfileAvatarDisplay extends StatefulWidget {
  final double radius;
  final Color defaultColor;

  const ProfileAvatarDisplay({
    Key? key,
    this.radius = 20,
    this.defaultColor = const Color(0xFFE5A72E),
  }) : super(key: key);

  @override
  State<ProfileAvatarDisplay> createState() => _ProfileAvatarDisplayState();
}

class _ProfileAvatarDisplayState extends State<ProfileAvatarDisplay> {
  String _photoType = 'none';
  String _photoPath = '';
  int _avatarIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _photoType = prefs.getString('profilePhotoType') ?? 'none';
        _photoPath = prefs.getString('profilePhotoPath') ?? '';
        _avatarIndex = prefs.getInt('profileAvatarIndex') ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_photoType) {
      case 'image':
        final file = File(_photoPath);
        if (file.existsSync()) {
          return CircleAvatar(
            radius: widget.radius,
            backgroundImage: FileImage(file),
          );
        }
        return _default();
      case 'avatar':
        if (_avatarIndex >= 0 && _avatarIndex < presetAvatars.length) {
          final av = presetAvatars[_avatarIndex];
          return CircleAvatar(
            radius: widget.radius,
            backgroundColor: av.backgroundColor,
            child: Icon(
              av.icon,
              size: widget.radius * 0.9,
              color: av.iconColor,
            ),
          );
        }
        return _default();
      default:
        return _default();
    }
  }

  Widget _default() {
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: Colors.white,
      child: Icon(
        Icons.person,
        size: widget.radius * 0.9,
        color: widget.defaultColor,
      ),
    );
  }
}
