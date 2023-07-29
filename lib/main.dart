import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp (
      debugShowCheckedModeBanner: false,
      home:  NotesList(),
    );
  }
}

class NotesList extends StatefulWidget {
  const NotesList({Key? key}) : super(key: key);

  @override
  _NotesListState createState() => _NotesListState();
}

class _NotesListState extends State<NotesList> {
  late final Database _db;
  final List<Map<String, dynamic>> _notes = [];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    final String databasesPath = await getDatabasesPath();
    final String dbPath = join(databasesPath, 'notes.db');

    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE Notes (
            id INTEGER PRIMARY KEY,
            title TEXT,
            content TEXT,
            date TEXT
          )
        ''');
      },
    );

    _refreshNotes();
  }

  Future<void> _refreshNotes() async {
    final List<Map<String, dynamic>> list =
        await _db.rawQuery('SELECT * FROM Notes');
    setState(() {
      _notes.clear();
      _notes.addAll(list);
    });
  }

  Future<void> _addNote() async {
    await _db.insert(
      'Notes',
      {
        'title': _titleController.text,
        'content': _contentController.text,
        'date': DateTime.now().toIso8601String(),
      },
    );
    _titleController.clear();
    _contentController.clear();
    await _refreshNotes();
  }

  Future<void> _deleteNote(int id) async {
    await _db.delete('Notes', where: 'id = ?', whereArgs: [id]);
    await _refreshNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 114, 95, 95),
      appBar: AppBar(
        title: const Text('Notes'),
      ),
      body: ListView.builder(
        itemCount: _notes.length,
        itemBuilder: (BuildContext context, int index) {
          final Map<String, dynamic> note = _notes[index];
          return Card(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  title: Text(note['title'] as String),
                  subtitle: Text(note['content'] as String),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteNote(note['id'] as int),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    note['date'] as String,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Add note'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                    ),
                  ),
                  TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      labelText: 'Content',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text('Save'),
                  onPressed: () {
                    setState(() {
                      _addNote();
                      Navigator.of(context).pop();
                    });
                  },
                ),
              ],
            );
          },
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
