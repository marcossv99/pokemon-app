  import 'dart:io';
  import 'package:flutter/material.dart';
  import 'package:path_provider/path_provider.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import '../models/pokemon.dart';
  import 'pokemon_card.dart';

  class MeusPokemonsPage extends StatefulWidget {
    const MeusPokemonsPage({Key? key}) : super(key: key);

    @override
    _MeusPokemonsPageState createState() => _MeusPokemonsPageState();
  }

  class _MeusPokemonsPageState extends State<MeusPokemonsPage> {
    List<Pokemon> _meusPokemons = [];

    @override
    void initState() {
      super.initState();
      _carregarMeusPokemons();
    }

    Future<void> _carregarMeusPokemons() async {
      final prefs = await SharedPreferences.getInstance();
      final meusPokemonsIds = prefs.getStringList('meusPokemons') ?? [];
      
      setState(() {
        _meusPokemons = meusPokemonsIds.map((id) => Pokemon(id: int.parse(id), name: 'Pokemon $id', types: ['Tipo1'], baseStats: {})).toList();
      });
    }

    Future<String> _getLocalImagePath(int pokemonId) async {
      final directory = await getApplicationDocumentsDirectory();
      return '${directory.path}/pokemon_images/${pokemonId.toString().padLeft(3, '0')}.png';
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Meus Pokémons'),
        ),
        body: ListView.builder(
          itemCount: _meusPokemons.length,
          itemBuilder: (context, index) {
            final pokemon = _meusPokemons[index];
            return FutureBuilder<String>(
              future: _getLocalImagePath(pokemon.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  final imagePath = snapshot.data;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(8),
                      leading: imagePath != null && File(imagePath).existsSync()
                          ? Image.file(
                              File(imagePath),
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              'https://raw.githubusercontent.com/fanzeyi/pokemon.json/master/images/${pokemon.id.toString().padLeft(3, '0')}.png',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                      title: Text(pokemon.name),
                      subtitle: Text('Tipo: ${pokemon.types.join(', ')}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PokemonDetailPage(pokemon: pokemon),
                          ),
                        );
                      },
                    ),
                  );
                } else {
                  return const CircularProgressIndicator();
                }
              },
            );
          },
        ),
      );
    }
  }
