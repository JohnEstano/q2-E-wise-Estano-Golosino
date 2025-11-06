// lib/models/device.dart
class Device {
  String id;
  String name;
  String category;
  String status;
  int quantity;
  double estWeightKg;

  // Additional fields from analysis
  String? description;
  String? imagePath;
  String? imageUrl; // Firebase Storage URL
  String? brand;
  String? model;
  String? year;
  String? color;
  List<String>? components;
  List<String>? hazards;
  Map<String, int>? materialStreams;
  String? disposalPath;
  Map<String, dynamic>? metrics;
  DateTime? scannedAt;
  String? qrCode; // Unique identifier for QR code

  Device({
    required this.id,
    required this.name,
    required this.category,
    this.status = 'available',
    this.quantity = 1,
    this.estWeightKg = 0.5,
    this.description,
    this.imagePath,
    this.imageUrl,
    this.brand,
    this.model,
    this.year,
    this.color,
    this.components,
    this.hazards,
    this.materialStreams,
    this.disposalPath,
    this.metrics,
    this.scannedAt,
    this.qrCode,
  });

  // Convert Device to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'status': status,
      'quantity': quantity,
      'estWeightKg': estWeightKg,
      'description': description,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'brand': brand,
      'model': model,
      'year': year,
      'color': color,
      'components': components,
      'hazards': hazards,
      'materialStreams': materialStreams,
      'disposalPath': disposalPath,
      'metrics': metrics,
      'scannedAt': scannedAt?.toIso8601String(),
      'qrCode': qrCode,
    };
  }

  // Create Device from Firestore Map
  factory Device.fromMap(Map<String, dynamic> map) {
    return Device(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? 'Other',
      status: map['status'] ?? 'available',
      quantity: map['quantity'] ?? 1,
      estWeightKg: (map['estWeightKg'] ?? 0.5).toDouble(),
      description: map['description'],
      imagePath: map['imagePath'],
      imageUrl: map['imageUrl'],
      brand: map['brand'],
      model: map['model'],
      year: map['year'],
      color: map['color'],
      components: map['components'] != null
          ? List<String>.from(map['components'])
          : null,
      hazards: map['hazards'] != null
          ? List<String>.from(map['hazards'])
          : null,
      materialStreams: map['materialStreams'] != null
          ? Map<String, int>.from(map['materialStreams'])
          : null,
      disposalPath: map['disposalPath'],
      metrics: map['metrics'],
      scannedAt: map['scannedAt'] != null
          ? DateTime.parse(map['scannedAt'])
          : null,
      qrCode: map['qrCode'],
    );
  }
}
