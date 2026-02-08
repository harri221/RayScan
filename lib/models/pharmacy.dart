class Pharmacy {
  final int id;
  final String name;
  final String address;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final bool isOpen;
  final Map<String, dynamic>? openingHours;
  final String? distance;
  final String? createdAt;
  final int? matchingProducts;

  Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.latitude,
    this.longitude,
    required this.isOpen,
    this.openingHours,
    this.distance,
    this.createdAt,
    this.matchingProducts,
  });

  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    return Pharmacy(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      isOpen: json['isOpen'] as bool,
      openingHours: json['openingHours'] as Map<String, dynamic>?,
      distance: json['distance'] as String?,
      createdAt: json['createdAt'] as String?,
      matchingProducts: json['matchingProducts'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'isOpen': isOpen,
      'openingHours': openingHours,
      'distance': distance,
      'createdAt': createdAt,
      'matchingProducts': matchingProducts,
    };
  }
}

class PharmacyDetail extends Pharmacy {
  final List<PharmacyProduct> products;
  final String? updatedAt;

  PharmacyDetail({
    required super.id,
    required super.name,
    required super.address,
    super.phone,
    super.latitude,
    super.longitude,
    required super.isOpen,
    super.openingHours,
    super.distance,
    super.createdAt,
    required this.products,
    this.updatedAt,
  });

  factory PharmacyDetail.fromJson(Map<String, dynamic> json) {
    final productsData = json['products'] as List? ?? [];

    return PharmacyDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      isOpen: json['isOpen'] as bool,
      openingHours: json['openingHours'] as Map<String, dynamic>?,
      distance: json['distance'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      products: productsData.map((data) => PharmacyProduct.fromJson(data)).toList(),
    );
  }
}

class PharmacyProduct {
  final int id;
  final int pharmacyId;
  final String name;
  final String category;
  final double? price;
  final bool inStock;
  final String? createdAt;

  PharmacyProduct({
    required this.id,
    required this.pharmacyId,
    required this.name,
    required this.category,
    this.price,
    required this.inStock,
    this.createdAt,
  });

  factory PharmacyProduct.fromJson(Map<String, dynamic> json) {
    return PharmacyProduct(
      id: json['id'] as int,
      pharmacyId: json['pharmacyId'] as int,
      name: json['name'] as String,
      category: json['category'] as String,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      inStock: json['inStock'] as bool,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pharmacyId': pharmacyId,
      'name': name,
      'category': category,
      'price': price,
      'inStock': inStock,
      'createdAt': createdAt,
    };
  }

  String get formattedPrice {
    if (price == null) return 'Price not available';
    return 'PKR ${price!.toStringAsFixed(2)}';
  }

  String get formattedCategory {
    switch (category) {
      case 'covid19':
        return 'COVID-19';
      case 'blood_pressure':
        return 'Blood Pressure';
      case 'pain_killers':
        return 'Pain Killers';
      case 'stomach':
        return 'Stomach';
      case 'epiapcy':
        return 'Epilepsy';
      case 'pancreatics':
        return 'Pancreatic';
      case 'nuero_pill':
        return 'Neurological';
      case 'immune_system':
        return 'Immune System';
      case 'other':
        return 'Other';
      default:
        return category;
    }
  }
}

class ProductWithPharmacy {
  final int id;
  final String name;
  final String category;
  final double? price;
  final bool inStock;
  final Pharmacy pharmacy;
  final String? createdAt;

  ProductWithPharmacy({
    required this.id,
    required this.name,
    required this.category,
    this.price,
    required this.inStock,
    required this.pharmacy,
    this.createdAt,
  });

  factory ProductWithPharmacy.fromJson(Map<String, dynamic> json) {
    return ProductWithPharmacy(
      id: json['id'] as int,
      name: json['name'] as String,
      category: json['category'] as String,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      inStock: json['inStock'] as bool,
      pharmacy: Pharmacy.fromJson(json['pharmacy'] as Map<String, dynamic>),
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'inStock': inStock,
      'pharmacy': pharmacy.toJson(),
      'createdAt': createdAt,
    };
  }

  String get formattedPrice {
    if (price == null) return 'Price not available';
    return 'PKR ${price!.toStringAsFixed(2)}';
  }

  String get formattedCategory {
    switch (category) {
      case 'covid19':
        return 'COVID-19';
      case 'blood_pressure':
        return 'Blood Pressure';
      case 'pain_killers':
        return 'Pain Killers';
      case 'stomach':
        return 'Stomach';
      case 'epiapcy':
        return 'Epilepsy';
      case 'pancreatics':
        return 'Pancreatic';
      case 'nuero_pill':
        return 'Neurological';
      case 'immune_system':
        return 'Immune System';
      case 'other':
        return 'Other';
      default:
        return category;
    }
  }
}