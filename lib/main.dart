import 'package:flutter/material.dart';
import 'screens/document_list_page.dart';
import 'db/database_helper.dart';
import 'models/car.dart';
import 'package:carnote/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'services/permission_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await NotificationService.initialize();
  await PermissionService.requestNotificationPermission();
  runApp(const CarnoteApp());
}

class CarnoteApp extends StatelessWidget {
  const CarnoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carnote',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final _pages = [
    const CarListPage(),
    const DocumentListPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Cars',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Documents',
          ),
        ],
      ),
    );
  }
}

class CarListPage extends StatefulWidget {
  const CarListPage({super.key});

  @override
  State<CarListPage> createState() => _CarListPageState();
}

class _CarListPageState extends State<CarListPage> {
  final dbHelper = DatabaseHelper();
  List<Car> cars = [];

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  Future<void> _loadCars() async {
    final data = await dbHelper.getCars();
    setState(() {
      cars = data;
    });
  }

  Future<void> _showAddCarDialog({Car? existing}) async {
    String name = existing?.name ?? '';
    int odometer = existing?.odometer ?? 0;

    final nameController = TextEditingController(text: name);
    final odometerController = TextEditingController(text: odometer.toString());

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Add Car' : 'Edit Car'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: odometerController,
              decoration: const InputDecoration(labelText: 'Odometer'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final car = Car(
                id: existing?.id,
                name: nameController.text,
                odometer: int.tryParse(odometerController.text) ?? 0,
              );
              if (existing == null) {
                await dbHelper.insertCar(car);
              } else {
                await dbHelper.updateCar(car);
              }
              Navigator.of(context).pop();
              _loadCars();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCar(Car car) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete car'),
        content: Text('Are you sure you want to delete "${car.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await dbHelper.deleteCar(car.id!);
      _loadCars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted ${car.name}')),
      );
    } else {
      setState(() {}); // Rebuild to undo swipe
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cars'),
      ),
      body: ListView.builder(
        itemCount: cars.length,
        itemBuilder: (context, index) {
          final car = cars[index];
          return Dismissible(
            key: Key(car.id.toString()),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async => false, // prevent auto-dismiss
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => _deleteCar(car),
            child: ListTile(
              title: Text(car.name),
              subtitle: Text('Odometer: ${car.odometer} km'),
              onLongPress: () => _showAddCarDialog(existing: car),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCarDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}