import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/profile_service.dart';

class EditProfileDialog extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final bool isRecruiter;
  final VoidCallback onSaved;

  const EditProfileDialog({
    super.key,
    required this.initialData,
    this.isRecruiter = false,
    required this.onSaved,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _profileService = ProfileService();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _avatarController;
  late TextEditingController _bioController;
  late TextEditingController _dobController;
  late TextEditingController _websiteController;
  late TextEditingController _industryController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData['full_name'] ?? '');
    _phoneController = TextEditingController(text: widget.initialData['phone_number'] ?? '');
    _addressController = TextEditingController(text: widget.initialData['address'] ?? '');
    _avatarController = TextEditingController(text: widget.initialData['avatar_url'] ?? '');
    _bioController = TextEditingController(text: widget.initialData['bio'] ?? '');
    _dobController = TextEditingController(text: widget.initialData['date_of_birth'] ?? '');
    _websiteController = TextEditingController(text: widget.initialData['website'] ?? '');
    _industryController = TextEditingController(text: widget.initialData['industry'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _avatarController.dispose();
    _bioController.dispose();
    _dobController.dispose();
    _websiteController.dispose();
    _industryController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    
    final updateData = {
      'full_name': _nameController.text.trim(),
      'phone_number': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'avatar_url': _avatarController.text.trim(),
      'bio': _bioController.text.trim(),
    };
    
    if (widget.isRecruiter) {
      updateData['website'] = _websiteController.text.trim();
      updateData['industry'] = _industryController.text.trim();
    } else {
      updateData['date_of_birth'] = _dobController.text.trim();
    }

    try {
      await _profileService.updateProfile(updateData);
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(ShadToast.destructive(
          title: const Text('Error'),
          description: Text(e.toString()),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Edit Profile',
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField('Full Name', _nameController),
              const SizedBox(height: 16),
              _buildField('Phone Number', _phoneController),
              const SizedBox(height: 16),
              _buildField('Address', _addressController),
              const SizedBox(height: 16),
              _buildField('Avatar URL', _avatarController, placeholder: 'https://example.com/avatar.jpg'),
              const SizedBox(height: 16),
              if (widget.isRecruiter) ...[
                _buildField('Website', _websiteController),
                const SizedBox(height: 16),
                _buildField('Industry', _industryController),
                const SizedBox(height: 16),
              ] else ...[
                _buildField('Date of Birth', _dobController, placeholder: 'YYYY-MM-DD'),
                const SizedBox(height: 16),
              ],
              _buildField('Bio / About Me', _bioController, maxLines: 4),
            ],
          ),
        ),
      ),
      actions: [
        ShadButton.ghost(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ShadButton(
          onPressed: _isLoading ? null : _saveProfile,
          child: _isLoading 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save Changes'),
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller, {int maxLines = 1, String? placeholder}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        ShadInput(
          controller: controller,
          maxLines: maxLines,
          placeholder: placeholder != null ? Text(placeholder) : null,
        ),
      ],
    );
  }
}
