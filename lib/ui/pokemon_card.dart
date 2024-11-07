// lib/ui/pokemon_card.dart
import 'package:flutter/material.dart';
import '../models/pokemon.dart';

class PokemonCard extends StatelessWidget {
  final Pokemon pokemon;

  const PokemonCard({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Column(
        children: [
          // Espaço extra no topo
          const SizedBox(height: 250),

          // Círculo atrás da imagem do Pokémon
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 253, 195, 171), // Cor amigável para o fundo do círculo
                  shape: BoxShape.circle,
                ),
              ),
              // Imagem do Pokémon
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://raw.githubusercontent.com/fanzeyi/pokemon.json/master/images/${pokemon.id.toString().padLeft(3, '0')}.png',
                    ),
                    fit: BoxFit.contain,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20), // Ajuste no espaçamento entre a imagem e as informações

          // Centralizar o nome e os tipos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Nome do Pokémon
                Text(
                  pokemon.name,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center, // Correção aqui: alinhamento do texto
                ),
                const SizedBox(height: 8),
                // Tipos do Pokémon
                Text(
                  'Tipo: ${pokemon.types.join(', ')}',
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center, // Correção aqui: alinhamento do texto
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Container para os atributos com fundo colorido
          Container(
            padding: const EdgeInsets.all(16.0),
            color: const Color.fromARGB(255, 230, 253, 227),  // Cor amigável para o fundo
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAttributeText('HP: ${pokemon.baseStats['HP']}'),
                    _buildAttributeText('Ataque: ${pokemon.baseStats['Attack']}'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAttributeText('Defesa: ${pokemon.baseStats['Defense']}'),
                    _buildAttributeText('Sp. Ataque: ${pokemon.baseStats['Sp. Attack']}'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAttributeText('Sp. Defesa: ${pokemon.baseStats['Sp. Defense']}'),
                    _buildAttributeText('Velocidade: ${pokemon.baseStats['Speed']}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Método auxiliar para construir o texto dos atributos
  Widget _buildAttributeText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: Colors.grey,
      ),
    );
  }
}
