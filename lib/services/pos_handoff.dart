import 'dart:convert';
import 'dart:io';

/// Shared mock queue written by ZatGo POS (`~/.zatgo/pos-delivery-handoff.json`).
class PosHandoffItem {
  const PosHandoffItem({
    required this.id,
    required this.posOrderId,
    required this.orderNumber,
    required this.customerName,
    required this.address,
    required this.phone,
    required this.itemsSummary,
    required this.handedOffAt,
    this.notes,
    this.amount = 0,
  });

  final String id;
  final String posOrderId;
  final String orderNumber;
  final String customerName;
  final String address;
  final String phone;
  final String itemsSummary;
  final String handedOffAt;
  final String? notes;
  final double amount;

  factory PosHandoffItem.fromJson(Map<String, dynamic> json) {
    return PosHandoffItem(
      id: json['id'] as String? ?? '',
      posOrderId: json['posOrderId'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      customerName: json['customerName'] as String? ?? 'Guest',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      itemsSummary: json['itemsSummary'] as String? ?? 'Order',
      handedOffAt: json['handedOffAt'] as String? ?? '',
      notes: json['notes'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

String posHandoffFilePath() {
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home == null || home.isEmpty) {
    return '.zatgo/pos-delivery-handoff.json';
  }
  return '$home/.zatgo/pos-delivery-handoff.json';
}

/// Returns handoff items from the POS queue file, or empty if missing/unreadable.
Future<List<PosHandoffItem>> readPosHandoffQueue() async {
  try {
    final file = File(posHandoffFilePath());
    if (!await file.exists()) return const [];
    final raw = await file.readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return const [];
    if (decoded['version'] != 1) return const [];
    final items = decoded['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(PosHandoffItem.fromJson)
        .where((i) => i.id.isNotEmpty && i.orderNumber.isNotEmpty)
        .toList();
  } catch (_) {
    return const [];
  }
}
