import 'dart:io';
import 'dart:convert';
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
        print("Conectado. Tentando acessar API: $apiUrl");
        final response = await _dio.get(apiUrl);
        print("Status da resposta: ${response.statusCode}");

        if (response.statusCode == 200) {
          List<dynamic> data = response.data;
          List<Pokemon> allPokemons = data.map((json) => Pokemon.fromJson(json)).toList();

          List<Pokemon> pagePokemons = _getPaginatedPokemons(allPokemons, offset, limit);

          for (var pokemon in pagePokemons) {
            await _dbHelper.insertPokemon(pokemon);
            await _savePokemonImage(pokemon.id);
          }

          print("Pokémons carregados e cache atualizado.");
          return pagePokemons;
        } else {
          print('Erro ao acessar API. Status: ${response.statusCode}, Resposta: ${response.data}');
          throw Exception('Falha ao carregar os Pokémons');
        }
      } else {
        print("Sem conexão. Carregando dados do cache.");
        final cachedPokemons = await _dbHelper.getCachedPokemons();
        final cachedPokemonsWithImages = await _filterPokemonsWithImages(cachedPokemons);
        return _getPaginatedPokemons(cachedPokemonsWithImages, offset, limit);
      }
    } catch (e) {
      print("Erro durante o carregamento dos Pokémons: $e");
      rethrow; // Repassa o erro para ser capturado na PokedexPage
    }
  }

  // Método auxiliar para obter a paginação dos Pokémons
  List<Pokemon> _getPaginatedPokemons(List<Pokemon> pokemons, int offset, int limit) {
    final endIndex = offset + limit;
    return pokemons.sublist(offset, endIndex > pokemons.length ? pokemons.length : endIndex);
  }

  // Métodos para salvar imagens e verificar cache (outros métodos da classe)
  Future<void> _savePokemonImage(int pokemonId) async {
    final url = 'https://raw.githubusercontent.com/fanzeyi/pokemon.json/master/images/${pokemonId.toString().padLeft(3, '0')}.png';
    final response = await _dio.get(url, options: Options(responseType: ResponseType.bytes));

    if (response.statusCode == 200) {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/pokemon_images/${pokemonId.toString().padLeft(3, '0')}.png';

      final imageFile = File(imagePath);
      await imageFile.create(recursive: true);
      await imageFile.writeAsBytes(response.data);
    }
  }

  Future<bool> _isImageCached(int pokemonId) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/pokemon_images/${pokemonId.toString().padLeft(3, '0')}.png';
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
