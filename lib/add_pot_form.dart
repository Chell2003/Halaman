import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'pot_model.dart';


class AddPotForm extends StatefulWidget {
  const AddPotForm({super.key});

  @override
  State<AddPotForm> createState() => _AddPotFormState();
}

class _AddPotFormState extends State<AddPotForm> {
  final _formKey = GlobalKey<FormState>();
  late String _potName;
  late String _potType;
  late String _channelId;
  late String _apiKey;
  late String _ipAddress;

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      final newPot = Pot(
        name: _potName,
        type: _potType,
        channelId: _channelId,
        apiKey: _apiKey,
        ipAddress: _ipAddress,
      );
      // Save the pot data to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('savedPot', json.encode(newPot.toJson()));
      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pot saved successfully')),
      );
      Navigator.pop(context, newPot);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add New Pot',
          style: TextStyle(
            fontSize: 20, // Set the font size
            fontWeight: FontWeight.bold, // Make the text bold
            color: Colors.white, // Set the text color
            // Add more styling properties if needed
          ),
        ),
        backgroundColor: Colors.green[700],
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Pot Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.spa),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name for the pot';
                  }
                  return null;
                },
                onSaved: (value) => _potName = value ?? '',
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Pot Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a type for the pot';
                  }
                  return null;
                },
                onSaved: (value) => _potType = value ?? '',
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Channel ID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the Channel ID';
                  }
                  return null;
                },
                onSaved: (value) => _channelId = value ?? '',
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the API Key';
                  }
                  return null;
                },
                onSaved: (value) => _apiKey = value ?? '',
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'IP Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wifi),
                ),
                validator: (value) {
                  // Add validation for IP address if needed
                  if (value == null || value.isEmpty) {
                    return 'Please enter the IP Address';
                  }
                  // You can also add more complex validation for the IP format
                  return null;
                },
                onSaved: (value) => _ipAddress = value ?? '',
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700], // Button background color
                  foregroundColor: Colors.white, // Button text color
                ),
                onPressed: _submitForm,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15.0),
                  child: Text('Save Pot', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
