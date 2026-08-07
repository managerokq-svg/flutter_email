// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:s_translation/generated/l10n.dart';

class ContactPickerPage extends StatefulWidget {
  final String title;
  final String searchHint;
  final String noContactsFound;
  final String permissionDenied;
  final String noPhoneNumber;
  final String done;

  ContactPickerPage({
    super.key,
    String? title,
    String? searchHint,
    String? noContactsFound,
    String? permissionDenied,
    String? noPhoneNumber,
    String? done,
  })  : title = title ?? S.current.selectContacts,
        searchHint = searchHint ?? S.current.searchContacts,
        noContactsFound = noContactsFound ?? S.current.noContactsFound,
        permissionDenied = permissionDenied ?? S.current.permissionDeniedGrantAccess,
        noPhoneNumber = noPhoneNumber ?? S.current.noPhoneNumber,
        done = done ?? S.current.done;

  @override
  State<ContactPickerPage> createState() => _ContactPickerPageState();
}

class _ContactPickerPageState extends State<ContactPickerPage> {
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  final Set<String> _selectedIds = {};
  bool _isLoading = true;
  bool _permissionDenied = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    var status = await Permission.contacts.status;
    if (!status.isGranted) {
      status = await Permission.contacts.request();
    }
    if (!status.isGranted) {
      if (mounted) {
        setState(() {
          _permissionDenied = true;
          _isLoading = false;
        });
      }
      return;
    }
    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );
      if (mounted) {
        setState(() {
          _contacts = contacts;
          _filteredContacts = contacts;
          _isLoading = false;
          _permissionDenied = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _permissionDenied = true;
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _filteredContacts = _contacts);
      return;
    }
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredContacts = _contacts.where((contact) {
        final nameMatch = contact.displayName.toLowerCase().contains(lowerQuery);
        final phoneMatch = contact.phones.any(
          (phone) => phone.number.contains(query),
        );
        return nameMatch || phoneMatch;
      }).toList();
    });
  }

  void _toggleSelection(Contact contact) {
    setState(() {
      if (_selectedIds.contains(contact.id)) {
        _selectedIds.remove(contact.id);
      } else {
        _selectedIds.add(contact.id);
      }
    });
  }

  void _onDone() {
    final selectedContacts = _contacts
        .where((c) => _selectedIds.contains(c.id) && c.phones.isNotEmpty)
        .toList();
    Navigator.of(context).pop(selectedContacts);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIds.isEmpty
              ? widget.title
              : '${widget.title} (${_selectedIds.length})',
        ),
        actions: [
          if (_selectedIds.isNotEmpty)
            TextButton(
              onPressed: _onDone,
              child: Text(
                widget.done,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
        bottom: _permissionDenied || _isLoading
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: widget.searchHint,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              ),
      ),
      body: _buildBody(),
      floatingActionButton: _selectedIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _onDone,
              icon: const Icon(Icons.check),
              label: Text('${widget.done} (${_selectedIds.length})'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (_permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.contacts, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                widget.permissionDenied,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadContacts,
                child: Text(S.of(context).grantPermission),
              ),
            ],
          ),
        ),
      );
    }
    if (_filteredContacts.isEmpty) {
      return Center(
        child: Text(
          widget.noContactsFound,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        final hasPhone = contact.phones.isNotEmpty;
        final phoneNumber = hasPhone
            ? contact.phones.first.number
            : widget.noPhoneNumber;
        final isSelected = _selectedIds.contains(contact.id);
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: contact.photo != null
                ? MemoryImage(contact.photo!)
                : null,
            child: contact.photo == null
                ? Text(
                    contact.displayName.isNotEmpty
                        ? contact.displayName[0].toUpperCase()
                        : '?',
                  )
                : null,
          ),
          title: Text(contact.displayName),
          subtitle: Text(phoneNumber),
          trailing: hasPhone
              ? Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSelection(contact),
                )
              : null,
          onTap: hasPhone ? () => _toggleSelection(contact) : null,
          enabled: hasPhone,
        );
      },
    );
  }
}
