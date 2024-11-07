import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/pokemon.dart';
import 'database_helper.dart';

class PokemonService {
  static const String apiUrl = 'http://192.168.15.7:3000/pokemons';
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Dio _dio = Dio();

  // Função principal para buscar Pokémons paginados
  Future<List<Pokemon>> fetchPokemonsPage(int offset, int limit) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      print("Conectividade: $connectivityResult");

      if (connectivityResult != ConnectivityResult.none) {
        return await _fetchPokemonsFromApi(offset, limit);
      } else {
        return await _fetchPokemonsFromCache(offset, limit);
      }
    } catch (e) {
      print("Erro durante o carregamento dos Pokémons: $e");
      return await _fetchPokemonsFromCache(offset, limit);
    }
  }

  // Busca os Pokémons da API e salva no cache
  Future<List<Pokemon>> _fetchPokemonsFromApi(int offset, int limit) async {
    try {
      final response = await _dio.get(apiUrl);
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        List<Pokemon> allPokemons = data.map((json) => Pokemon.fromJson(json)).toList();
        List<Pokemon> pagePokemons = _getPaginatedPokemons(allPokemons, offset, limit);

        // Salvar no cache
        for (var pokemon in pagePokemons) {
          await _dbHelper.insertPokemon(pokemon);
          await _savePokemonImage(pokemon.id);
        }

        print("Pokémons carregados e cache atualizado.");
        return pagePokemons;
      } else {
        throw Exception('Erro ao acessar API com status ${response.statusCode}');
      }
    } catch (e) {
      print("Erro ao buscar Pokémons da API: $e");
      rethrow;
    }
  }

  // Busca os Pokémons do cache local
  Future<List<Pokemon>> _fetchPokemonsFromCache(int offset, int limit) async {
    print("Sem conexão. Carregando dados do cache.");
    final cachedPokemons = await _dbHelper.getCachedPokemons();
    if (cachedPokemons.isEmpty) {
      print("Nenhum Pokémon encontrado no cache.");
    } else {
      print("Pokémons cacheados: ${cachedPokemons.length}");
    }
    final cachedPokemonsWithImages = await _filterPokemonsWithImages(cachedPokemons);
    return _getPaginatedPokemons(cachedPokemonsWithImages, offset, limit);
  }

  // Método para obter um Pokémon específico pelo ID
  Future<Pokemon> getPokemonById(int pokemonId) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        return await _fetchPokemonFromApiById(pokemonId);
      } else {
        return await _fetchPokemonFromCacheById(pokemonId);
      }
    } catch (e) {
      print("Erro ao buscar Pokémon por ID: $e");
      return await _fetchPokemonFromCacheById(pokemonId);
    }
  }

  // Busca um Pokémon específico da API e salva no cache
  Future<Pokemon> _fetchPokemonFromApiById(int pokemonId) async {
    final response = await _dio.get('$apiUrl/$pokemonId');
    if (response.statusCode == 200) {
      Pokemon pokemon = Pokemon.fromJson(response.data);
      await _dbHelper.insertPokemon(pokemon);
      await _savePokemonImage(pokemon.id);
      return pokemon;
    } else {
      throw Exception("Erro ao buscar Pokémon na API com status ${response.statusCode}");
    }
  }

  // Busca um Pokémon específico do cache
  Future<Pokemon> _fetchPokemonFromCacheById(int pokemonId) async {
    final cachedPokemons = await _dbHelper.getCachedPokemons();
    return cachedPokemons.firstWhere(
      (p) => p.id == pokemonId,
      orElse: () => throw Exception("Pokémon com ID $pokemonId não encontrado no cache."),
    );
  }

  // Método auxiliar para obter a paginação dos Pokémons
  List<Pokemon> _getPaginatedPokemons(List<Pokemon> pokemons, int offset, int limit) {
    final endIndex = offset + limit;
    return pokemons.sublist(
      offset,
      endIndex > pokemons.length ? pokemons.length : endIndex,
    );
  }

  // Método para salvar a imagem de um Pokémon
  Future<void> _savePokemonImage(int pokemonId) async {
    final url =
        'https://raw.githubusercontent.com/fanzeyi/pokemon.json/master/images/${pokemonId.toString().padLeft(3, '0')}.png';
    final response =
        await _dio.get(url, options: Options(responseType: ResponseType.bytes));

    if (response.statusCode == 200) {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath =
          '${directory.path}/pokemon_images/${pokemonId.toString().padLeft(3, '0')}.png';

      final imageFile = File(imagePath);
      await imageFile.create(recursive: true);
      await imageFile.writeAsBytes(response.data);
      print("Imagem do Pokémon $pokemonId salva em: $imagePath");
    }
  }

  Future<bool> _isImageCached(int pokemonId) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath =
        '${directory.path}/pokemon_images/${pokemonId.toString().padLeft(3, '0')}.png';
    return File(imagePath).existsSync();
  }

  Future<List<Pokemon>> _filterPokemonsWithImages(List<Pokemon> pokemons) async {
    List<Pokemon> pokemonsWithImages = [];
    for (var pokemon in pokemons) {
      if (await _isImageCached(pokemon.id)) {
        pokemonsWithImages.add(pokemon);
      }
    }
    return pokemonsWithImages;
  }
}
