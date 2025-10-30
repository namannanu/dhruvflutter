// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/state/app_state.dart';
import 'package:talent/features/shared/widgets/business_logo_avatar.dart';

class EditBusiness extends StatefulWidget {
  const EditBusiness({
    super.key,
    required this.business,
  });

  final BusinessLocation business;

  @override
  State<EditBusiness> createState() => _EditBusinessState();
}

class _EditBusinessState extends State<EditBusiness> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _logoUrlController;
  bool _submitting = false;
  late bool _isActive;
  late double _allowedRadius;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.business.name);
    _descriptionController =
        TextEditingController(text: widget.business.description);
    _addressController =
        TextEditingController(text: widget.business.fullAddress);
    _phoneController = TextEditingController(text: widget.business.phone);
    _logoUrlController =
        TextEditingController(text: widget.business.logoUrl ?? '');
    _isActive = widget.business.isActive;
    _allowedRadius = widget.business.allowedRadius ??
        150.0; // Default 150 meters to match backend

    _nameController.addListener(_handleNameChanged);
    _logoUrlController.addListener(_handleLogoChanged);
  }

  @override
  void dispose() {
    _logoUrlController.removeListener(_handleLogoChanged);
    _nameController.removeListener(_handleNameChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final appState = context.read<AppState>();
      debugPrint('DEBUG: Starting business update...');
      debugPrint('Business ID: ${widget.business.id}');
      debugPrint('Name: ${_nameController.text.trim()}');
      debugPrint('Description: ${_descriptionController.text.trim()}');
      await appState.updateBusiness(
        widget.business.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        isActive: _isActive,
        logoUrl: _logoUrlController.text.trim().isEmpty
            ? null
            : _logoUrlController.text.trim(),
        allowedRadius: _allowedRadius,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business updated successfully!')),
      );
    } catch (e, stackTrace) {
      debugPrint('Error updating business: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update business: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _handleLogoChanged() {
    setState(() {});
  }

  void _handleNameChanged() {
    setState(() {});
  }

  Future<void> _pickLogo() async {
    try {
      const typeGroup = XTypeGroup(
        label: 'images',
        extensions: ['png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp', 'svg'],
      );
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected image is empty.')),
        );
        return;
      }

      final mime = file.mimeType ?? _lookupMimeType(file.name);
      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';

      setState(() {
        _logoUrlController.text = dataUrl;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $error')),
      );
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

  Future<void> _delete() async {
    setState(() => _submitting = true);

    try {
      final appState = context.read<AppState>();
      await appState.deleteBusiness(widget.business.id);

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business deleted successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete business: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Business?'),
        content: Text(
          'Are you sure you want to delete "${widget.business.name}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.85,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    16 + bottomInset,
                  ),
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✏️ Edit business',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration:
                            const InputDecoration(labelText: 'Business name'),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Enter business name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        decoration:
                            const InputDecoration(labelText: 'Description'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        decoration:
                            const InputDecoration(labelText: 'Full address'),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Enter business address'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Phone'),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),

                      // Allowed radius slider
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Allowed radius for clock-in: ${_allowedRadius.toInt()} meters',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            value: _allowedRadius,
                            min: 10.0,
                            max: 5000.0,
                            divisions: 499,
                            label: '${_allowedRadius.toInt()}m',
                            onChanged: (value) {
                              setState(() {
                                _allowedRadius = value;
                              });
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '10m',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  '5000m',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Workers can only clock in when they are within this distance from the business location.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _logoUrlController,
                              decoration: const InputDecoration(
                                labelText: 'Logo image',
                                hintText: 'Paste URL or upload an image',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          BusinessLogoAvatar(
                            name: _nameController.text,
                            logoUrl: _logoUrlController.text.trim().isEmpty
                                ? null
                                : _logoUrlController.text.trim(),
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
                            onPressed: _submitting ? null : _pickLogo,
                            icon: const Icon(Icons.file_upload_outlined),
                            label: const Text('Upload image'),
                          ),
                          if (_logoUrlController.text.trim().isNotEmpty)
                            TextButton.icon(
                              onPressed: _submitting
                                  ? null
                                  : () {
                                      _logoUrlController.clear();
                                    },
                              icon: const Icon(Icons.clear),
                              label: const Text('Clear'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You can paste an image URL or upload a PNG, JPG, WEBP file. Uploaded images are converted to a data URL for storage.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 20),
                      SwitchListTile(
                        title: const Text('Active'),
                        subtitle: const Text(
                          'When inactive, this business location will not be visible to workers',
                        ),
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _submitting ? null : _confirmDelete,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Delete'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _submitting ? null : _submit,
                              icon: _submitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(_submitting ? 'Saving…' : 'Save'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
