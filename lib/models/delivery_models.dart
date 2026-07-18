enum StopStatus {
  assigned,
  accepted,
  rejected,
  reachedRestaurant,
  pickedUp,
  outForDelivery,
  delivered,
  failed,
  cancelled,
  returned,
}

enum PodMethod { otp, signature, photo, none }

class DeliveryStop {
  const DeliveryStop({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.address,
    required this.city,
    required this.windowLabel,
    required this.status,
    required this.itemsSummary,
    required this.sequence,
    required this.requiresOtp,
    required this.requiresSignature,
    required this.lat,
    required this.lng,
    this.phone,
    this.notes,
    this.source,
    this.podMethod,
    this.podSignedBy,
    this.invoiceNumber,
    this.area,
    this.priority,
    this.remarks,
    this.paymentMethod,
    this.codAmount = 0,
    this.paidAmount = 0,
    this.balance = 0,
    this.deliveryCharges = 0,
    this.assignedAt,
    this.expectedAt,
    this.podPhoto,
  });

  final String id;
  final String orderNumber;
  final String customerName;
  final String address;
  final String city;
  final String windowLabel;
  final StopStatus status;
  final String itemsSummary;
  final int sequence;
  final bool requiresOtp;
  final bool requiresSignature;
  final double lat;
  final double lng;
  final String? phone;
  final String? notes;
  final String? source;
  final String? podMethod;
  final String? podSignedBy;
  final String? invoiceNumber;
  final String? area;
  final String? priority;
  final String? remarks;
  final String? paymentMethod;
  final double codAmount;
  final double paidAmount;
  final double balance;
  final double deliveryCharges;
  final String? assignedAt;
  final String? expectedAt;
  final String? podPhoto;

  bool get isTerminal =>
      status == StopStatus.delivered ||
      status == StopStatus.failed ||
      status == StopStatus.rejected ||
      status == StopStatus.cancelled ||
      status == StopStatus.returned;

  bool get isActive => !isTerminal;

  DeliveryStop copyWith({
    StopStatus? status,
    String? source,
    String? podMethod,
    String? podSignedBy,
    String? podPhoto,
    double? paidAmount,
    double? balance,
  }) {
    return DeliveryStop(
      id: id,
      orderNumber: orderNumber,
      customerName: customerName,
      address: address,
      city: city,
      windowLabel: windowLabel,
      status: status ?? this.status,
      itemsSummary: itemsSummary,
      sequence: sequence,
      requiresOtp: requiresOtp,
      requiresSignature: requiresSignature,
      lat: lat,
      lng: lng,
      phone: phone,
      notes: notes,
      source: source ?? this.source,
      podMethod: podMethod ?? this.podMethod,
      podSignedBy: podSignedBy ?? this.podSignedBy,
      invoiceNumber: invoiceNumber,
      area: area,
      priority: priority,
      remarks: remarks,
      paymentMethod: paymentMethod,
      codAmount: codAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      balance: balance ?? this.balance,
      deliveryCharges: deliveryCharges,
      assignedAt: assignedAt,
      expectedAt: expectedAt,
      podPhoto: podPhoto ?? this.podPhoto,
    );
  }

  Map<String, dynamic> toCacheMap() => {
        'id': id,
        'orderNumber': orderNumber,
        'customerName': customerName,
        'address': address,
        'city': city,
        'windowLabel': windowLabel,
        'status': status.name,
        'itemsSummary': itemsSummary,
        'sequence': sequence,
        'requiresOtp': requiresOtp,
        'requiresSignature': requiresSignature,
        'lat': lat,
        'lng': lng,
        'phone': phone,
        'notes': notes,
        'source': source,
        'podMethod': podMethod,
        'podSignedBy': podSignedBy,
        'invoiceNumber': invoiceNumber,
        'area': area,
        'priority': priority,
        'remarks': remarks,
        'paymentMethod': paymentMethod,
        'codAmount': codAmount,
        'paidAmount': paidAmount,
        'balance': balance,
        'deliveryCharges': deliveryCharges,
        'assignedAt': assignedAt,
        'expectedAt': expectedAt,
        'podPhoto': podPhoto,
      };

  factory DeliveryStop.fromCacheMap(Map map) {
    return DeliveryStop(
      id: '${map['id']}',
      orderNumber: '${map['orderNumber'] ?? ''}',
      customerName: '${map['customerName'] ?? ''}',
      address: '${map['address'] ?? ''}',
      city: '${map['city'] ?? ''}',
      windowLabel: '${map['windowLabel'] ?? '—'}',
      status: parseStopStatus('${map['status'] ?? ''}'),
      itemsSummary: '${map['itemsSummary'] ?? ''}',
      sequence: map['sequence'] is int ? map['sequence'] as int : 0,
      requiresOtp: map['requiresOtp'] == true,
      requiresSignature: map['requiresSignature'] != false,
      lat: (map['lat'] as num?)?.toDouble() ?? 0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0,
      phone: map['phone']?.toString(),
      notes: map['notes']?.toString(),
      source: map['source']?.toString(),
      podMethod: map['podMethod']?.toString(),
      podSignedBy: map['podSignedBy']?.toString(),
      invoiceNumber: map['invoiceNumber']?.toString(),
      area: map['area']?.toString(),
      priority: map['priority']?.toString(),
      remarks: map['remarks']?.toString(),
      paymentMethod: map['paymentMethod']?.toString(),
      codAmount: (map['codAmount'] as num?)?.toDouble() ?? 0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0,
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
      deliveryCharges: (map['deliveryCharges'] as num?)?.toDouble() ?? 0,
      assignedAt: map['assignedAt']?.toString(),
      expectedAt: map['expectedAt']?.toString(),
      podPhoto: map['podPhoto']?.toString(),
    );
  }
}

StopStatus parseStopStatus(String raw) {
  final key = raw.toLowerCase().replaceAll(' ', '').replaceAll('_', '').replaceAll('-', '');
  switch (key) {
    case 'pending':
    case 'assigned':
      return StopStatus.assigned;
    case 'accepted':
      return StopStatus.accepted;
    case 'rejected':
      return StopStatus.rejected;
    case 'reachedrestaurant':
    case 'reached':
      return StopStatus.reachedRestaurant;
    case 'pickedup':
    case 'pickup':
      return StopStatus.pickedUp;
    case 'outfordelivery':
    case 'enroute':
    case 'arrived':
      return StopStatus.outForDelivery;
    case 'delivered':
      return StopStatus.delivered;
    case 'failed':
      return StopStatus.failed;
    case 'cancelled':
    case 'canceled':
      return StopStatus.cancelled;
    case 'returned':
      return StopStatus.returned;
    default:
      return StopStatus.assigned;
  }
}

String stopStatusLabel(StopStatus status) => switch (status) {
      StopStatus.assigned => 'Assigned',
      StopStatus.accepted => 'Accepted',
      StopStatus.rejected => 'Rejected',
      StopStatus.reachedRestaurant => 'Reached Restaurant',
      StopStatus.pickedUp => 'Picked Up',
      StopStatus.outForDelivery => 'Out For Delivery',
      StopStatus.delivered => 'Delivered',
      StopStatus.failed => 'Failed',
      StopStatus.cancelled => 'Cancelled',
      StopStatus.returned => 'Returned',
    };

/// Next legal driver actions from [status].
List<StopStatus> nextStatuses(StopStatus status) => switch (status) {
      StopStatus.assigned => [StopStatus.accepted, StopStatus.rejected],
      StopStatus.accepted => [
          StopStatus.reachedRestaurant,
          StopStatus.pickedUp,
          StopStatus.outForDelivery,
          StopStatus.failed,
        ],
      StopStatus.reachedRestaurant => [
          StopStatus.pickedUp,
          StopStatus.failed,
        ],
      StopStatus.pickedUp => [
          StopStatus.outForDelivery,
          StopStatus.failed,
          StopStatus.returned,
        ],
      StopStatus.outForDelivery => [
          StopStatus.delivered,
          StopStatus.failed,
          StopStatus.returned,
        ],
      _ => const [],
    };

class RouteSummary {
  const RouteSummary({
    required this.routeName,
    required this.vehicle,
    required this.driverName,
    required this.stopCount,
    required this.deliveredCount,
    required this.pendingCount,
    required this.points,
    required this.bonus,
    required this.codTotal,
    required this.distanceKm,
    required this.etaLabel,
  });

  final String routeName;
  final String vehicle;
  final String driverName;
  final int stopCount;
  final int deliveredCount;
  final int pendingCount;
  final int points;
  final int bonus;
  final double codTotal;
  final double distanceKm;
  final String etaLabel;
}

class TrackingPing {
  const TrackingPing({
    required this.atLabel,
    required this.lat,
    required this.lng,
    required this.speedKmh,
    required this.note,
  });

  final String atLabel;
  final double lat;
  final double lng;
  final double speedKmh;
  final String note;
}

class PodCapture {
  const PodCapture({
    required this.stopId,
    required this.method,
    this.otpCode,
    this.signedBy,
    this.photoNote,
    this.capturedAt,
  });

  final String stopId;
  final PodMethod method;
  final String? otpCode;
  final String? signedBy;
  final String? photoNote;
  final DateTime? capturedAt;
}
