import 'dart:convert';
import 'dart:io';
import 'package:translator/translator.dart';

void main() async {
  final file = File('../../assets/exercises.json');
  if (!await file.exists()) {
    print('File not found: ${file.path}');
    return;
  }

  final String jsonString = await file.readAsString();
  final List<dynamic> data = json.decode(jsonString);
  final translator = GoogleTranslator();

  int total = data.length;
  int translatedCount = 0;
  
  print('Iniciando a tradução de $total exercícios...');

  for (int i = 0; i < total; i++) {
    final item = data[i] as Map<String, dynamic>;
    
    // Check if it's already translated
    if (item.containsKey('instructions_pt') && (item['instructions_pt'] as List).isNotEmpty) {
      continue;
    }

    final instructions = item['instructions'] as List<dynamic>? ?? [];
    List<String> instructionsPt = [];

    if (instructions.isNotEmpty) {
      try {
        print('Traduzindo [$i/$total]: ${item['name']}');
        
        for (var inst in instructions) {
          final translated = await translator.translate(inst.toString(), from: 'en', to: 'pt');
          instructionsPt.add(translated.text);
          await Future.delayed(Duration(milliseconds: 300)); // Pequeno delay para evitar rate limit
        }
        
        item['instructions_pt'] = instructionsPt;
        translatedCount++;
        
        // Salvar a cada 20 traduções para não perder progresso
        if (translatedCount % 20 == 0) {
          await file.writeAsString(json.encode(data), flush: true);
          print('--- Progresso salvo ---');
        }

      } catch (e) {
        print('Erro ao traduzir ${item['name']}: $e');
        print('Pausando por 10 segundos antes de continuar...');
        await Future.delayed(Duration(seconds: 10));
        // Save state before continuing
        await file.writeAsString(json.encode(data), flush: true);
      }
    } else {
      item['instructions_pt'] = [];
    }
  }

  // Save final file
  await file.writeAsString(json.encode(data), flush: true);
  print('Tradução finalizada! $total exercícios processados.');
}
