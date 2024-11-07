import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pokemon.dart';
import '../service/api_service.dart';

class EncontroDiarioPage extends StatefulWidget {
  const EncontroDiarioPage({super.key});

  @override
  _EncontroDiarioPageState createState() => _EncontroDiarioPageState();
}

class _EncontroDiarioPageState extends State<EncontroDiarioPage> {
  Pokemon? _pokemonDoDia;
  late Timer _timer;
  Duration _tempoRestante = const Duration(hours: 24);
  bool _pokemonCapturado = false;
  final int maxCapturas = 6;
  final PokemonService _pokemonService = PokemonService();

  @override
  void initState() {
    super.initState();
    _carregarPokemonDoDia();
    _iniciarContador();
  }

  Future<void> _carregarPokemonDoDia() async {
    final prefs = await SharedPreferences.getInstance();
    final ultimoPokemonId = prefs.getInt('ultimoPokemonId');
    final ultimoEncontro = prefs.getInt('ultimoEncontro');
    final capturasHoje = prefs.getBool('pokemonCapturadoHoje') ?? false;

    final agora = DateTime.now();
    if (ultimoEncontro == null ||
        agora
                .difference(DateTime.fromMillisecondsSinceEpoch(ultimoEncontro))
                .inHours >=
            24) {
      _pokemonDoDia = await _sortearPokemon();
      await prefs.setInt('ultimoPokemonId', _pokemonDoDia!.id);
      await prefs.setInt('ultimoEncontro', agora.millisecondsSinceEpoch);
      await prefs.setBool('pokemonCapturadoHoje', false);
    } else {
      _pokemonDoDia = await _carregarPokemonPorId(ultimoPokemonId!);
      setState(() {
        _tempoRestante = const Duration(hours: 24) -
            agora.difference(
                DateTime.fromMillisecondsSinceEpoch(ultimoEncontro));
        _pokemonCapturado = capturasHoje;
      });
    }
  }

  Future<Pokemon> _sortearPokemon() async {
    final randomId = Random().nextInt(800) + 1;
    return await _pokemonService.getPokemonById(randomId);
  }

  Future<Pokemon> _carregarPokemonPorId(int id) async {
    return await _pokemonService.getPokemonById(id);
  }

  void _iniciarContador() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_tempoRestante.inSeconds > 0) {
          _tempoRestante -= const Duration(seconds: 1);
        } else {
          _carregarPokemonDoDia();
        }
      });
    });
  }

  Future<void> _capturarPokemon() async {
    if (_pokemonCapturado) return;

    final prefs = await SharedPreferences.getInstance();
    final meusPokemons = prefs.getStringList('meusPokemons') ?? [];

    if (meusPokemons.length >= maxCapturas) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Você já possui 6 Pokémon!")));
      return;
    }

    meusPokemons.add(_pokemonDoDia!.id.toString());
    await prefs.setStringList('meusPokemons', meusPokemons);
    await prefs.setBool('pokemonCapturadoHoje', true);

    setState(() {
      _pokemonCapturado = true;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Pokémon capturado!")));
  }

  Future<void> _adiantarEncontro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ultimoEncontro');
    await _carregarPokemonDoDia();

    setState(() {
      _tempoRestante = const Duration(hours: 24);
      _pokemonCapturado = false;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Encontro Diário'),
        titleTextStyle: const TextStyle(
          color: Color.fromARGB(255, 32, 32, 32),
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Colors.lightBlue.shade50,
        elevation: 0,
        toolbarHeight: 100,
      ),
      body: Container(
        color: Colors.lightBlue.shade50,
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: _pokemonDoDia == null
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Pokemon do dia',
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
                    const SizedBox(height: 20),
                    // Círculo atrás da imagem do Pokémon
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            color: Colors.lightBlue.shade100,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Image.network(
                          'https://raw.githubusercontent.com/fanzeyi/pokemon.json/master/images/${_pokemonDoDia!.id.toString().padLeft(3, '0')}.png',
                          width: 280,
                          height: 280,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _pokemonDoDia!.name,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tipo(s): ${_pokemonDoDia!.types.join(', ')}',
                      style:
                          const TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Atributos',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'HP: ${_pokemonDoDia!.baseStats['HP']}, '
                      'Ataque: ${_pokemonDoDia!.baseStats['Attack']}, '
                      'Defesa: ${_pokemonDoDia!.baseStats['Defense']}',
                      style:
                          const TextStyle(fontSize: 18, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Tempo restante: ${_tempoRestante.inHours}:${(_tempoRestante.inMinutes % 60).toString().padLeft(2, '0')}:${(_tempoRestante.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                          fontSize: 18, color: Colors.blueAccent),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _pokemonCapturado ? null : _capturarPokemon,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 155, 244, 158),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24.0, vertical: 12.0),
                        textStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Capturar Pokémon'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _adiantarEncontro,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 241, 120, 111),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24.0, vertical: 12.0),
                        textStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Mudar'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
