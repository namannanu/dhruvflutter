// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/state/app_state.dart';

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
  bool _submitting = false;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.business.name);
    _descriptionController =
        TextEditingController(text: widget.business.description);
    _addressController =
        TextEditingController(text: widget.business.fullAddress);
    _phoneController = TextEditingController(text: widget.business.phone);
    _isActive = widget.business.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
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
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                padding: const EdgeInsets.all(16),
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '✏️ Edit business',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          const InputDecoration(labelText: 'Business name'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter business name' : null,
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
    );
  }
}
