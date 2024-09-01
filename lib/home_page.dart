import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'add_pot_form.dart';
import 'pot_model.dart';
import 'monitoring_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Pot> pots = [];

  @override
  void initState() {
    super.initState();
    _loadPots();
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/pots.json');
  }

  Future<void> _loadPots() async {
    try {
      final file = await _localFile;
      final contents = await file.readAsString();
      final List<dynamic> jsonPots = jsonDecode(contents);
      setState(() {
        pots = jsonPots.map((jsonPot) => Pot.fromJson(jsonPot)).toList();
      });
    } catch (e) {
      // If encountering an error, such as the file doesn't exist, set pots to an empty list
      setState(() {
        pots = [];
      });
    }
  }

  Future<void> _savePots() async {
    final file = await _localFile;
    final String jsonPots = jsonEncode(pots.map((pot) => pot.toJson()).toList());
    await file.writeAsString(jsonPots);
  }

  void _addNewPot(Pot pot) {
    setState(() {
      pots.add(pot);
    });
    _savePots();
  }

  void _deletePot(int index) {
    setState(() {
      pots.removeAt(index);
    });
    _savePots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Pots',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.green[700],
        elevation: 0,
      ),
      body: pots.isEmpty
          ? const Center(
        child: Text(
          'No pots added yet!',
          style: TextStyle(fontSize: 18, color: Colors.black54),
        ),
      )
          : ListView.builder(
        itemCount: pots.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: const Icon(Icons.local_florist, color: Colors.green),
              title: Text(
                pots[index].name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(pots[index].type),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MonitoringScreen(pot: pots[index]),
                  ),
                );
              },
              onLongPress: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Text(
                        'Delete Pot',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: const Text(
                        'Are you sure you want to delete this pot?',
                        style: TextStyle(
                          color: Colors.black87,
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent, // Text Color
                          ),
                          child: const Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop(); // Dismiss the dialog
                          },
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.redAccent, // Button Background Color
                            foregroundColor: Colors.white, // Text Color
                          ),
                          child: const Text('Delete'),
                          onPressed: () {
                            _deletePot(index); // Remove the pot from the list
                            Navigator.of(context).pop(); // Dismiss the dialog
                          },
                        ),
                      ],
                    );
                  },
                );
              },

            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newPot = await Navigator.push<Pot>(
            context,
            MaterialPageRoute(builder: (context) => const AddPotForm()),
          );
          if (newPot != null) {
            _addNewPot(newPot);
          }
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
}