class Pokemon {
  final int id;
  final String name;
  final List<String> types;
  final Map<String, int> baseStats;

  Pokemon({
    required this.id,
    required this.name,
    required this.types,
    required this.baseStats,
  });

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    try {
      return Pokemon(
        id: int.parse(json['id'].toString()),
        name: json['name']['english'],
        types: List<String>.from(json['type']),
        baseStats: Map<String, int>.from(
          json['base'].map((key, value) => MapEntry(key, int.parse(value.toString()))),
        ),
      );
    } catch (e) {
      print("Erro ao converter JSON para Pokemon: $e");
      throw Exception('Erro ao processar os dados do Pokémon');
    }
  }
}
