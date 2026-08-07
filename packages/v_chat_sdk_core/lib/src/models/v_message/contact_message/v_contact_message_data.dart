// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

class VContactItem {
  final String name;
  final List<String> phones;

  const VContactItem({
    required this.name,
    required this.phones,
  });

  factory VContactItem.fromMap(Map<String, dynamic> map) {
    return VContactItem(
      name: map['name'] as String,
      phones: (map['phones'] as List<dynamic>).cast<String>(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phones': phones,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VContactItem &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          phones.toString() == other.phones.toString());

  @override
  int get hashCode => name.hashCode ^ phones.hashCode;

  @override
  String toString() => 'VContactItem{name: $name, phones: $phones}';

  VContactItem copyWith({
    String? name,
    List<String>? phones,
  }) {
    return VContactItem(
      name: name ?? this.name,
      phones: phones ?? this.phones,
    );
  }
}

class VContactMessageData {
  final List<VContactItem> contacts;

  const VContactMessageData({required this.contacts});

  factory VContactMessageData.fromMap(Map<String, dynamic> map) {
    final contactsList = (map['contacts'] as List<dynamic>)
        .map((e) => VContactItem.fromMap(e as Map<String, dynamic>))
        .toList();
    return VContactMessageData(contacts: contactsList);
  }

  Map<String, dynamic> toMap() => {
        'contacts': contacts.map((c) => c.toMap()).toList(),
      };

  String get displayName {
    if (contacts.isEmpty) return '';
    if (contacts.length == 1) return contacts.first.name;
    return '${contacts.first.name} +${contacts.length - 1}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VContactMessageData &&
          runtimeType == other.runtimeType &&
          contacts.toString() == other.contacts.toString());

  @override
  int get hashCode => contacts.hashCode;

  @override
  String toString() => 'VContactMessageData{contacts: $contacts}';

  VContactMessageData copyWith({
    List<VContactItem>? contacts,
  }) {
    return VContactMessageData(
      contacts: contacts ?? this.contacts,
    );
  }
}
