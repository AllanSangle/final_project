import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


class Draft{
  final String description;
  final String imageURL;

  Draft({required this.description, required this.imageURL});

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'imageURL': imageURL,
    };
  }

factory Draft.fromMap(Map<String, dynamic> map) {
    return Draft(
      description: map['description'],
      imageURL: map['imageURL'],
    );
  }
}

class DraftsDatabase {
  static final DraftsDatabase instance = DraftsDatabase._init();

  static Database? _database;

  DraftsDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('drafts.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE drafts (
        description TEXT,
        imageURL TEXT
      )
    ''');
  }

  Future<int> insertDraft(Draft draft) async {
    final db = await instance.database;
    return await db.insert('drafts', draft.toMap());
  }

  Future<List<Draft>> getDrafts() async {
    final db = await instance.database;
    final result = await db.query('drafts');
    return result.map((map) => Draft.fromMap(map)).toList();
  }

}

class DraftsScreen extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Previous Drafts'),
      ),
      body: FutureBuilder<List<Draft>>(
        future: DraftsDatabase.instance.getDrafts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final drafts = snapshot.data ?? [];

          if (drafts.isEmpty) {
            return const Center(child: Text('No drafts available.'));
          }

          return ListView.builder(
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              final draft = drafts[index];
              return ListTile(
                title: Text(draft.description),
                subtitle: Text(draft.imageURL.isEmpty ? 'No image URL' : draft.imageURL),
              );
            },
          );
        },
      ),
    );
  }
}