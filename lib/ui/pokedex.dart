// lib/screens/pokedex.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../models/pokemon.dart';
import '../service/api_service.dart';
import '../ui/pokemon_card.dart';

class Pokedex extends StatefulWidget {
  const Pokedex({super.key});

  @override
  _PokedexPageState createState() => _PokedexPageState();
}

class _PokedexPageState extends State<Pokedex> {
  final PokemonService _pokemonService = PokemonService();
  static const int pageSize = 20;

  final PagingController<int, Pokemon> _pagingController =
      PagingController(firstPageKey: 0);

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    final newPokemons =
        await _pokemonService.fetchPokemonsPage(pageKey, pageSize);
    final isLastPage = newPokemons.length < pageSize;

    if (isLastPage) {
      _pagingController.appendLastPage(newPokemons);
    } else {
      final nextPageKey = pageKey + newPokemons.length;
      _pagingController.appendPage(newPokemons, nextPageKey);
    }
  }

  Future<String> _getLocalImagePath(int pokemonId) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/pokemon_images/${pokemonId.toString().padLeft(3, '0')}.png';
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex'),
        titleTextStyle: const TextStyle(
          color: Color.fromARGB(255, 48, 48, 48),
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: const Color.fromARGB(255, 182, 205, 253),
        toolbarHeight: 120,
      ),
      body: Container(
        color: const Color.fromARGB(255, 182, 205, 253),
        child: PagedGridView<int, Pokemon>(
          pagingController: _pagingController,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Exibe dois cards por linha
            mainAxisSpacing: 6.0,
            crossAxisSpacing: 6.0,
            childAspectRatio: 2 / 2, // Define a proporção do card
          ),
          builderDelegate: PagedChildBuilderDelegate<Pokemon>(
            itemBuilder: (context, pokemon, index) {
              return FutureBuilder<String>(
                future: _getLocalImagePath(pokemon.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    final localImagePath = snapshot.data;
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PokemonCard(
                                pokemon: pokemon), // Abre a tela de detalhes
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 226, 226, 226),
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.file(
                              File(localImagePath!),
                              width: 120,
                              height: 120,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.network(
                                  'https://raw.githubusercontent.com/fanzeyi/pokemon.json/master/images/${pokemon.id.toString().padLeft(3, '0')}.png',
                                  width: 120,
                                  height: 120,
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              pokemon.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tipo(s): ${pokemon.types.join(', ')}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              );
            },
            noItemsFoundIndicatorBuilder: (context) =>
                const Center(child: Text('Nenhum Pokémon encontrado')),
            firstPageProgressIndicatorBuilder: (context) =>
                const Center(child: CircularProgressIndicator()),
            newPageProgressIndicatorBuilder: (context) =>
                const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }
}
