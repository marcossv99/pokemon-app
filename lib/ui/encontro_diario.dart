import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pokemon.dart';

class EncontroDiarioPage extends StatefulWidget {
  const EncontroDiarioPage({Key? key}) : super(key: key);

  @override
  _EncontroDiarioPageState createState() => _EncontroDiarioPageState();
}

class _EncontroDiarioPageState extends State<EncontroDiarioPage> {
  Pokemon? _pokemonDoDia;
  late Timer _timer;
  Duration _tempoRestante = Duration(hours: 24);
  bool _pokemonCapturado = false;
  final int maxCapturas = 6;

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
    if (ultimoEncontro == null || agora.difference(DateTime.fromMillisecondsSinceEpoch(ultimoEncontro)).inHours >= 24) {
      _pokemonDoDia = await _sortearPokemon();
      await prefs.setInt('ultimoPokemonId', _pokemonDoDia!.id);
      await prefs.setInt('ultimoEncontro', agora.millisecondsSinceEpoch);
      await prefs.setBool('pokemonCapturadoHoje', false);
    } else {
      _pokemonDoDia = await _carregarPokemonPorId(ultimoPokemonId!);
      setState(() {
        _tempoRestante = Duration(hours: 24) - agora.difference(DateTime.fromMillisecondsSinceEpoch(ultimoEncontro));
        _pokemonCapturado = capturasHoje;
      });
    }
  }

  Future<Pokemon> _sortearPokemon() async {
    final randomId = Random().nextInt(800) + 1;
    return Pokemon(id: randomId, name: 'Pokemon $randomId', types: ['Tipo1'], baseStats: {});
  }

  Future<Pokemon> _carregarPokemonPorId(int id) async {
    return Pokemon(id: id, name: 'Pokemon $id', types: ['Tipo1'], baseStats: {});
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Você já possui 6 Pokémon!")));
      return;
    }

    meusPokemons.add(_pokemonDoDia!.id.toString());
    await prefs.setStringList('meusPokemons', meusPokemons);
    await prefs.setBool('pokemonCapturadoHoje', true);

    setState(() {
      _pokemonCapturado = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pokémon capturado!")));
  }

  Future<void> _adiantarEncontro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ultimoEncontro'); // Remove o encontro anterior
    await _carregarPokemonDoDia(); // Carrega um novo Pokémon

    setState(() {
      _tempoRestante = Duration(hours: 24); // Reseta o tempo para 24h
      _pokemonCapturado = false; // Habilita o botão de captura novamente
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
      ),
      body: Center(
        child: _pokemonDoDia == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Pokémon do dia: ${_pokemonDoDia!.name}', style: const TextStyle(fontSize: 24)),
                  Image.network(
                    'https://raw.githubusercontent.com/fanzeyi/pokemon.json/master/images/${_pokemonDoDia!.id.toString().padLeft(3, '0')}.png',
                    width: 100,
                    height: 100,
                  ),
                  Text('Tempo restante: ${_tempoRestante.inHours}:${(_tempoRestante.inMinutes % 60).toString().padLeft(2, '0')}:${(_tempoRestante.inSeconds % 60).toString().padLeft(2, '0')}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _pokemonCapturado ? null : _capturarPokemon,
                    child: const Text('Capturar Pokémon'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _adiantarEncontro,
                    child: const Text('Adiantar Encontro (Trocar Pokémon)'),
                  ),
                ],
              ),
      ),
    );
  }
}
