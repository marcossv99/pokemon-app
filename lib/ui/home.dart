// lib/screens/home_page.dart

import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokémon App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 40,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/pokedex');
                },
                child: const Text('Pokédex'),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 150,
              height: 40,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/dailyEncounter');
                },
                child: const Text('Encontro Diário'),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 150,
              height: 40,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/myPokemons');
                },
                child: const Text('Meus Pokémons'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
