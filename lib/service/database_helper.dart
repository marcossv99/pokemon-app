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
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE pokemons(id INTEGER PRIMARY KEY, name TEXT, types TEXT)',
        );
      },
      version: 1,
    );
  }

  Future<void> insertPokemon(Pokemon pokemon) async {
    final db = await database;
    await db.insert(
      'pokemons',
      {'id': pokemon.id, 'name': pokemon.name, 'types': pokemon.types.join(', ')},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print("Pokémon inserido no cache: ${pokemon.name}");
  }

  Future<List<Pokemon>> getCachedPokemons() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('pokemons');

    return List.generate(maps.length, (i) {
      return Pokemon(
        id: maps[i]['id'],
        name: maps[i]['name'],
        types: maps[i]['types'].split(', '),
        baseStats: {}, // Define um mapa vazio para baseStats
      );
    });
  }

  Future<void> clearCache() async {
    final db = await database;
    await db.delete('pokemons');
    print("Cache de Pokémons limpo.");
  }
}
