// lib/models/device.dart
class Device {
  String id;
  String name;
  String category;
  String status;
  int quantity;
  double estWeightKg;

  Device({
    required this.id,
    required this.name,
    required this.category,
    this.status = 'available',
    this.quantity = 1,
    this.estWeightKg = 0.5,
  });
}