import 'package:flutter/material.dart';
import 'ui/home.dart';
import 'ui/pokedex.dart';
import 'ui/encontro_diario.dart'; 
import 'ui/meus_pokemons.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokémon App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const Home(),
        '/pokedex': (context) => const Pokedex(),
        '/encontroDiario': (context) => const EncontroDiarioPage(),
        '/meusPokemons': (context) => const MeusPokemonsPage(),
      },
    );
  }
}
