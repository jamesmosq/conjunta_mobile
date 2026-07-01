class Vehicle {
  const Vehicle({
    required this.id,
    required this.plate,
    required this.type,
    this.brand,
    this.model,
    this.color,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as int,
        plate: json['plate'] as String? ?? '',
        type: json['type'] as String? ?? '',
        brand: json['brand'] as String?,
        model: json['model'] as String?,
        color: json['color'] as String?,
      );

  final int id;
  final String plate;
  final String type;
  final String? brand;
  final String? model;
  final String? color;

  String get typeLabel => switch (type) {
        'car' => 'Carro',
        'motorcycle' => 'Moto',
        'bicycle' => 'Bicicleta',
        _ => type,
      };
}

class Pet {
  const Pet({
    required this.id,
    required this.name,
    required this.species,
    this.breed,
  });

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        species: json['species'] as String? ?? '',
        breed: json['breed'] as String?,
      );

  final int id;
  final String name;
  final String species;
  final String? breed;

  String get speciesLabel => switch (species) {
        'dog' => 'Perro',
        'cat' => 'Gato',
        'bird' => 'Ave',
        _ => species,
      };
}

class ResidentProfile {
  const ResidentProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.apartmentNumber,
    this.tower,
    required this.vehicles,
    required this.pets,
  });

  factory ResidentProfile.fromJson(Map<String, dynamic> json) {
    final apto = json['apartment'] as Map<String, dynamic>?;
    return ResidentProfile(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      apartmentNumber: apto?['number'] as String?,
      tower: apto?['tower'] as String?,
      vehicles: (json['vehicles'] as List<dynamic>? ?? [])
          .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
          .toList(),
      pets: (json['pets'] as List<dynamic>? ?? [])
          .map((e) => Pet.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? apartmentNumber;
  final String? tower;
  final List<Vehicle> vehicles;
  final List<Pet> pets;
}
