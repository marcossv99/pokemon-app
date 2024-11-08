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

  // construtor para criar uma instância de pokemon a partir de um json
  factory Pokemon.fromJson(Map<String, dynamic> json) {
    return Pokemon(
      id: int.parse(json['id'].toString()),
      name: json['name']['english'],
      types: List<String>.from(json['type']),
      baseStats: Map<String, int>.from(
        json['base']
            .map((key, value) => MapEntry(key, int.parse(value.toString()))),
      ),
    );
  }

  // converte a instância do pokeon em um map para ser salvo no banco de dados
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'types': types.join(', '), // converte a lista para string
      'baseStats':
          baseStats.entries.map((e) => '${e.key}:${e.value}').join(','),
    };
  }

  // construtor para criar uma instância de pokemon a partir de um map 
  factory Pokemon.fromMap(Map<String, dynamic> map) {
    return Pokemon(
      id: map['id'],
      name: map['name'],
      types: map['types'].split(', '),
      baseStats: Map.fromEntries(
        map['baseStats'].split(',').map((entry) {
          final parts = entry.split(':');
          return MapEntry(parts[0], int.parse(parts[1]));
        }),
      ),
    );
  }
}
