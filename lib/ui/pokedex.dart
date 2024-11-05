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
      try {
        final newPokemons =
            await _pokemonService.fetchPokemonsPage(pageKey, pageSize);
        final isLastPage = newPokemons.length < pageSize;

        if (isLastPage) {
          _pagingController.appendLastPage(newPokemons);
        } else {
          final nextPageKey = pageKey + newPokemons.length;
          _pagingController.appendPage(newPokemons, nextPageKey);
        }
      } catch (error) {
        _pagingController.error = error;
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
        ),
        body: PagedListView<int, Pokemon>(
          pagingController: _pagingController,
          builderDelegate: PagedChildBuilderDelegate<Pokemon>(
            itemBuilder: (context, pokemon, index) {
              return FutureBuilder<String>(
                future: _getLocalImagePath(pokemon.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    final localImagePath = snapshot.data;
                    return ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PokemonDetailPage(pokemon: pokemon),
                          ),
                        );
                      },
                      leading: Image.file(
                        File(localImagePath!),
                        width: 50,
                        height: 50,
                        errorBuilder: (context, error, stackTrace) {
                          // Caso não encontre a imagem local, carrega da internet
                          return Image.network(
                            'https://raw.githubusercontent.com/fanzeyi/pokemon.json/master/images/${pokemon.id.toString().padLeft(3, '0')}.png',
                            width: 50,
                            height: 50,
                          );
                        },
                      ),
                      title: Text(pokemon.name),
                      subtitle: Text('Tipo: ${pokemon.types.join(', ')}'),
                    );
                  } else {
                    return const CircularProgressIndicator();
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
      );
    }
  }
