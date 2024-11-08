import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/pokemon.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'pokemon_cache.db'),
      onCreate: (db, version) async {
        await db.execute(
          '''
          CREATE TABLE pokemons(
            id INTEGER PRIMARY KEY,
            name TEXT,
            types TEXT,
            baseStats TEXT
          )
          '''
        );
      },
      version: 1,
    );
  }

  Future<void> insertPokemon(Pokemon pokemon) async {
    final db = await database;
    await db.insert(
      'pokemons',
      {
        'id': pokemon.id,
        'name': pokemon.name,
        'types': pokemon.types.join(', '),
        'baseStats': _mapToString(pokemon.baseStats),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updatePokemon(Pokemon pokemon) async {
    final db = await database;
    await db.update(
      'pokemons',
      {
        'name': pokemon.name,
        'types': pokemon.types.join(', '),
        'baseStats': _mapToString(pokemon.baseStats),
      },
      where: 'id = ?',
      whereArgs: [pokemon.id],
    );
  }

  Future<List<Pokemon>> getCachedPokemons() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('pokemons');

    return List.generate(maps.length, (i) {
      return Pokemon(
        id: maps[i]['id'],
        name: maps[i]['name'],
        types: maps[i]['types'].split(', '),
        baseStats: _stringToMap(maps[i]['baseStats']),
      );
    });
  }

  Future<void> clearCache() async {
    final db = await database;
    await db.delete('pokemons');
  }

  // Converte um Map<String, int> para uma String JSON para armazenamento
  String _mapToString(Map<String, int> map) {
    return map.entries.map((e) => '${e.key}:${e.value}').join(',');
  }

  // Converte a String JSON de volta para um Map<String, int>
  Map<String, int> _stringToMap(String? str) {
    if (str == null || str.isEmpty) return {};
    return Map.fromEntries(
      str.split(',').map((entry) {
        final split = entry.split(':');
        return MapEntry(split[0], int.parse(split[1]));
      }),
    );
  }
}
