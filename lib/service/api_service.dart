import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/pokemon.dart';
import 'database_helper.dart';

class PokemonService {
  static const String apiUrl = 'http://192.168.0.28:3000/pokemons';
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Dio _dio = Dio();

  // função principal para buscar Pokémons paginados
  Future<List<Pokemon>> fetchPokemonsPage(int offset, int limit) async {
    final connectivityResult = await Connectivity().checkConnectivity();

    // verifica se há conectividade com a internet
    if (connectivityResult != ConnectivityResult.none) {
      // tenta buscar os Pokémons da API
      return await _fetchPokemonsFromApi(offset, limit);
    }

    // caso não tenha internet, carrega do cache
    return await _fetchPokemonsFromCache(offset, limit);
  }

  // busca os Pokémons da API e salva no cache
  Future<List<Pokemon>> _fetchPokemonsFromApi(int offset, int limit) async {
    final response = await _dio.get(apiUrl);
    if (response.statusCode == 200) {
      List<dynamic> data = response.data;
      List<Pokemon> allPokemons =
          data.map((json) => Pokemon.fromJson(json)).toList();
      List<Pokemon> pagePokemons =
          _getPaginatedPokemons(allPokemons, offset, limit);

      // salva os Pokémons da página atual no cache
      for (var pokemon in pagePokemons) {
        await _dbHelper.insertPokemon(pokemon);
        await _savePokemonImage(pokemon.id);
      }
      return pagePokemons;
    } else {
      throw Exception('Erro ao acessar API com status ${response.statusCode}');
    }
  }

  // busca os Pokémons do cache local
  Future<List<Pokemon>> _fetchPokemonsFromCache(int offset, int limit) async {
    print("carregando dados do cache local.");
    final cachedPokemons = await _dbHelper.getCachedPokemons();

    if (cachedPokemons.isEmpty) {
      print("nenhum Pokémon encontrado no cache.");
    }

    // filtra apenas pokemons com imagens armazenadas localmente
    final cachedPokemonsWithImages =
        await _filterPokemonsWithImages(cachedPokemons);
    return _getPaginatedPokemons(cachedPokemonsWithImages, offset, limit);
  }

  // método para obter um Pokémon específico pelo id
  Future<Pokemon> getPokemonById(int pokemonId) async {
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult != ConnectivityResult.none) {
      // busca Pokémon da API se houver conexão
      return await _fetchPokemonFromApiById(pokemonId);
    }

    // caso contrário, carrega do cache
    return await _fetchPokemonFromCacheById(pokemonId);
  }

  // busca um Pokémon específico da API e salva no cache
  Future<Pokemon> _fetchPokemonFromApiById(int pokemonId) async {
    final response = await _dio.get('$apiUrl/$pokemonId');
    if (response.statusCode == 200) {
      Pokemon pokemon = Pokemon.fromJson(response.data);

      // armazena o Pokémon e sua imagem no cache
      await _dbHelper.insertPokemon(pokemon);
      await _savePokemonImage(pokemon.id);

      return pokemon;
    } else {
      throw Exception("Erro ${response.statusCode} ao buscar Pokémon");
    }
  }

  // busca um Pokémon específico do cache
  Future<Pokemon> _fetchPokemonFromCacheById(int pokemonId) async {
    final cachedPokemons = await _dbHelper.getCachedPokemons();

    // verifica se o Pokémon está no cache
    return cachedPokemons.firstWhere(
      (p) => p.id == pokemonId,
      orElse: () => throw Exception("Pokémon não encontrado no cache."),
    );
  }

  // método auxiliar para realizar a paginação dos Pokémons
  List<Pokemon> _getPaginatedPokemons(
      List<Pokemon> pokemons, int offset, int limit) {
    final endIndex = offset + limit;
    return pokemons.sublist(
      offset,
      endIndex > pokemons.length ? pokemons.length : endIndex,
    );
  }

  // salva a imagem de um pokemon localmente
  Future<void> _savePokemonImage(int pokemonId) async {
    final imageUrl =
        'https://raw.githubusercontent.com/fanzeyi/pokemon.json/master/images/${pokemonId.toString().padLeft(3, '0')}.png';

    final response = await _dio.get(imageUrl,
        options: Options(responseType: ResponseType.bytes));
    if (response.statusCode == 200) {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath =
          '${directory.path}/pokemon_images/${pokemonId.toString().padLeft(3, '0')}.png';

      final imageFile = File(imagePath);
      await imageFile.create(recursive: true);
      await imageFile.writeAsBytes(response.data);
    }
  }

  // verifica se a imagem de um Pokémon está no cache
  Future<bool> _isImageCached(int pokemonId) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath =
        '${directory.path}/pokemon_images/${pokemonId.toString().padLeft(3, '0')}.png';
    return File(imagePath).existsSync();
  }

  // filtra os Pokémons com imagens disponíveis localmente
  Future<List<Pokemon>> _filterPokemonsWithImages(
      List<Pokemon> pokemons) async {
    List<Pokemon> pokemonsWithImages = [];
    for (var pokemon in pokemons) {
      if (await _isImageCached(pokemon.id)) {
        pokemonsWithImages.add(pokemon);
      }
    }
    return pokemonsWithImages;
  }
}
