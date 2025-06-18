class Car {
  final int? id;
  final String name;
  final int odometer;

  Car({this.id, required this.name, required this.odometer});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'odometer': odometer,
    };
  }

  factory Car.fromMap(Map<String, dynamic> map) {
    return Car(
      id: map['id'],
      name: map['name'],
      odometer: map['odometer'],
    );
  }
}