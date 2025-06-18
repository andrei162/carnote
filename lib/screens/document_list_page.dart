import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/document.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../services/notification_service.dart';


class DocumentListPage extends StatefulWidget {
  const DocumentListPage({super.key});

  @override
  State<DocumentListPage> createState() => _DocumentListPageState();
}

class _DocumentListPageState extends State<DocumentListPage> {
  final dbHelper = DatabaseHelper();
  List<Document> documents = [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final data = await dbHelper.getDocuments();
    setState(() {
      documents = data;
    });
  }

  Future<void> _showAddDocumentDialog({Document? existing}) async {
    String title = existing?.title ?? '';
    String type = existing?.type ?? '';
    DateTime? expiryDate = existing?.expiryDate;

    final titleController = TextEditingController(text: title);
    final typeController = TextEditingController(text: type);

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: Text(existing == null ? 'Add document' : 'Edit document'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    TextField(
                      controller: typeController,
                      decoration: const InputDecoration(labelText: 'Type'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Expires on:'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            expiryDate != null
                                ? DateFormat.yMMMMd().format(expiryDate!)
                                : 'Select date',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: expiryDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                expiryDate = picked;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty ||
                        typeController.text.trim().isEmpty ||
                        expiryDate == null) {
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all fields'),
                        ),
                      );
                      return;
                    }

                    final newDoc = Document(
                      id: existing?.id,
                      title: titleController.text.trim(),
                      type: typeController.text.trim(),
                      expiryDate: expiryDate!,
                    );

                    if (existing == null) {
                      int newId = await dbHelper.insertDocument(newDoc);
                      await NotificationService.showDocumentNotification(
                        id: newId,
                        title: newDoc.title,
                        expiryDate: DateTime.now().add(Duration(seconds:10))
                        //expiryDate: newDoc.expiryDate,
                      );
                    } else {
                      await dbHelper.updateDocument(newDoc);
                    }

                    Navigator.of(dialogContext).pop();
                    _loadDocuments();
                  },

                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }



  Future<void> _deleteDocument(Document doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete document'),
        content: Text('Are you sure you want to delete "${doc.title}"?'),
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
      await dbHelper.deleteDocument(doc.id!);
      _loadDocuments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
      ),
      body: ListView.builder(
        itemCount: documents.length,
        itemBuilder: (context, index) {
          final doc = documents[index];
          final isExpired = doc.expiryDate.isBefore(DateTime.now());
          final daysLeft = doc.expiryDate.difference(DateTime.now()).inDays;

          return ListTile(
            title: Text(doc.title),
            subtitle: Text('${doc.type} • expires in $daysLeft days'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteDocument(doc),
            ),
            onLongPress: () => _showAddDocumentDialog(existing: doc),
            tileColor: isExpired
                ? Colors.red[100]
                : daysLeft < 7
                ? Colors.orange[100]
                : null,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDocumentDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}