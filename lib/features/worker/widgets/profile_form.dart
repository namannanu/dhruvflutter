// ignore_for_file: prefer_single_quotes

import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:talent/core/services/image_optimization_service.dart';
import 'package:talent/features/shared/widgets/profile_picture_avatar.dart';
import 'package:talent/features/worker/models/availability.dart';

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
    required this.availability,
    required this.onAvailabilityChanged,
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
  final List<DayAvailability> availability;
  final ValueChanged<List<DayAvailability>> onAvailabilityChanged;
  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationsChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                      profilePictureUrl: profilePictureUrlController.text.trim().isEmpty
                          ? null
                          : profilePictureUrlController.text.trim(),
                      size: 56,
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
                const SizedBox(height: 4),
                Text(
                  'You can paste an image URL or upload a PNG, JPG, WEBP file. Uploaded images are converted to a data URL for storage.',
                  style: theme.textTheme.bodySmall,
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
                ),
                _Field(
                  controller: lastNameController,
                  label: 'Last name',
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (value) => _requiredValidator(value, 'last name'),
                ),
                _Field(
                  controller: phoneController,
                  label: 'Phone',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: _phoneValidator,
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
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  helperText: 'Share a short introduction about your experience.',
                ),
                _Field(
                  controller: experienceController,
                  label: 'Experience',
                  textInputAction: TextInputAction.next,
                ),
                _Field(
                  controller: skillsController,
                  label: 'Skills',
                  helperText: 'Separate multiple skills with commas.',
                  textInputAction: TextInputAction.next,
                ),
                _Field(
                  controller: languagesController,
                  label: 'Languages',
                  helperText: 'Separate multiple languages with commas.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Weekly availability',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (availability.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Add the days and time slots you are available to work.',
                    ),
                  )
                else
                  ...availability.asMap().entries.map(
                    (entry) => DayEditor(
                      day: entry.value,
                      onChanged: (updated) {
                        final newList = [...availability];
                        newList[entry.key] = updated;
                        onAvailabilityChanged(newList);
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (availability.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Tip: keep your availability current so employers can offer the right shifts.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
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
        extensions: ['png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp', 'svg'],
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
          ImageOptimizationService.optimizeDataUrl(dataUrl) ?? dataUrl;

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

class DayEditor extends StatelessWidget {
  const DayEditor({super.key, required this.day, required this.onChanged});

  final DayAvailability day;
  final ValueChanged<DayAvailability> onChanged;

  static TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 9 : 9;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    Future<void> editSlot(int slotIndex) async {
      final current = day.timeSlots[slotIndex];
      final initialStart = _parseTime(current.startTime);
      final initialEnd = _parseTime(current.endTime);

      final start = await showTimePicker(
        context: context,
        initialTime: initialStart,
        helpText: 'Select start time',
      );
      if (start == null) return;

      final end = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: context,
        initialTime: initialEnd.hour > start.hour ||
                (initialEnd.hour == start.hour &&
                    initialEnd.minute >= start.minute)
            ? initialEnd
            : TimeOfDay(
                hour: (start.hour + 1).clamp(0, 23).toInt(),
                minute: start.minute,
              ),
        helpText: 'Select end time',
      );
      if (end == null) return;

      final updatedSlots = [...day.timeSlots];
      updatedSlots[slotIndex] = TimeSlot(_formatTime(start), _formatTime(end));

      onChanged(day.copyWith(timeSlots: updatedSlots));
    }

    void addSlot() {
      final updatedSlots = [
        ...day.timeSlots,
        TimeSlot('09:00', '17:00'),
      ];
      onChanged(
        day.copyWith(
          isAvailable: true,
          timeSlots: updatedSlots,
        ),
      );
      Future.microtask(() => editSlot(updatedSlots.length - 1));
    }

    void removeSlot(int index) {
      final updatedSlots = [...day.timeSlots]..removeAt(index);
      onChanged(
        day.copyWith(timeSlots: updatedSlots),
      );
    }

    final hasSlots = day.timeSlots.isNotEmpty;

    return ExpansionTile(
      title: Text(
        day.day[0].toUpperCase() + day.day.substring(1),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      trailing: Switch(
        value: day.isAvailable,
        onChanged: (val) => onChanged(
          val
              ? day.copyWith(isAvailable: true)
              : day.copyWith(isAvailable: false, timeSlots: []),
        ),
      ),
      children: [
        if (!hasSlots)
          const ListTile(
            title: Text('No time slots added'),
            subtitle: Text('Add the times you are available to work.'),
          ),
        ...day.timeSlots.asMap().entries.map(
              (entry) => ListTile(
                title:
                    Text('${entry.value.startTime} - ${entry.value.endTime}'),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      tooltip: 'Edit time',
                      icon: const Icon(Icons.edit),
                      onPressed: () => editSlot(entry.key),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => removeSlot(entry.key),
                    ),
                  ],
                ),
              ),
            ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: addSlot,
            icon: const Icon(Icons.add),
            label: const Text('Add time slot'),
          ),
        ),
      ],
    );
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
