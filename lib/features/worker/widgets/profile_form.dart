// ignore_for_file: prefer_single_quotes

import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:talent/core/services/image_optimization_service.dart';
import 'package:talent/core/utils/image_url_optimizer.dart';
import 'package:talent/features/shared/widgets/profile_picture_avatar.dart';

class EditableProfileForm extends StatelessWidget {
  const EditableProfileForm({
    super.key,
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.phoneController,
    required this.bioController,
    required this.experienceController,
    required this.skillsController,
    required this.languagesController,
    required this.profilePictureUrlController,
    required this.notificationsEnabled,
    required this.onNotificationsChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController phoneController;
  final TextEditingController bioController;
  final TextEditingController experienceController;
  final TextEditingController skillsController;
  final TextEditingController languagesController;
  final TextEditingController profilePictureUrlController;
  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationsChanged;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionCard(
            title: 'Profile picture',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: profilePictureUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Profile picture',
                          hintText: 'Paste URL or upload an image',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ProfilePictureAvatar(
                      firstName: firstNameController.text.isEmpty
                          ? 'User'
                          : firstNameController.text,
                      lastName: lastNameController.text,
                      profilePictureUrl:
                          profilePictureUrlController.text.trim().isEmpty
                              ? null
                              : profilePictureUrlController.text.trim(),
                      size: 56,
                      imageContext: ImageContext.workerProfile,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _pickProfilePicture(context),
                      icon: const Icon(Icons.file_upload_outlined),
                      label: const Text('Upload image'),
                    ),
                    if (profilePictureUrlController.text.trim().isNotEmpty)
                      TextButton.icon(
                        onPressed: () => profilePictureUrlController.clear(),
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Personal information',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Field(
                  controller: firstNameController,
                  label: 'First name',
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (value) => _requiredValidator(value, 'first name'),
                  hintText: 'first name',
                ),
                _Field(
                  controller: lastNameController,
                  label: 'Last name',
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (value) => _requiredValidator(value, 'last name'),
                  hintText: 'last name',
                ),
                _Field(
                  controller: phoneController,
                  label: 'Phone',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: _phoneValidator,
                  hintText: 'phone number',
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: notificationsEnabled,
                  onChanged: onNotificationsChanged,
                  title: const Text('Enable notifications'),
                  subtitle: const Text(
                    'Get alerts for application updates and job matches.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Professional profile',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Field(
                  controller: bioController,
                  label: 'Bio',
                  hintText: 'Tell us about yourself',
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  helperText:
                      'Share a short introduction about your experience.',
                ),
                _Field(
                  controller: experienceController,
                  label: 'Experience',
                  textInputAction: TextInputAction.next,
                  hintText: 'Describe your work history',
                ),
                _Field(
                  controller: skillsController,
                  label: 'Skills',
                  helperText: 'Separate multiple skills with commas.',
                  textInputAction: TextInputAction.next,
                  hintText: 'List your key skills',
                ),
                _Field(
                  controller: languagesController,
                  label: 'Languages',
                  helperText: 'Separate multiple languages with commas.',
                  hintText: 'List languages you speak',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String? _requiredValidator(String? value, String fieldLabel) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your $fieldLabel';
    }
    return null;
  }

  static String? _phoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final digits = value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.length < 7) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  // Helper method to pick profile picture
  void _pickProfilePicture(BuildContext context) async {
    try {
      const typeGroup = XTypeGroup(
        label: 'images',
        // UTIs for iOS/macOS
        uniformTypeIdentifiers: [
          'public.image',
          'public.jpeg',
          'public.png',
        ],
        // Extensions for other platforms
        extensions: ['png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp'],
      );
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected image is empty.')),
          );
        }
        return;
      }

      final mime = file.mimeType ?? _lookupMimeType(file.name);
      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
      final optimized =
          ImageOptimizationService.optimizeProfilePictureDataUrl(dataUrl) ??
              dataUrl;

      if (kDebugMode) {
        debugPrint(
          '📉 Optimized profile photo data URL to '
          '${optimized.length} chars (was ${dataUrl.length})',
        );
      }

      profilePictureUrlController.text = optimized;
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $error')),
        );
      }
    }
  }

  static String _lookupMimeType(String? nameOrExtension) {
    if (nameOrExtension == null || nameOrExtension.isEmpty) {
      return 'image/png';
    }
    final lower = nameOrExtension.toLowerCase();
    final ext = lower.contains('.') ? lower.split('.').last : lower;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'svg':
        return 'image/svg+xml';
      default:
        return 'image/png';
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.textInputAction = TextInputAction.next,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.sentences,
    this.validator,
    this.helperText,
    this.maxLines = 1,
    required String hintText,
  });

  final TextEditingController controller;
  final String label;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final String? helperText;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        textInputAction: textInputAction,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
        ),
      ),
    );
  }
}
