import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/prova.dart';

class TelaEstatisticas extends StatelessWidget {
  final Prova prova;
  const TelaEstatisticas({super.key, required this.prova});

  // Função para calcular a média das notas
  double _calcularNotaMedia() {
    if (prova.correcoes.isEmpty) return 0.0;
    double soma = prova.correcoes.map((c) => c.nota).reduce((a, b) => a + b);
    return soma / prova.correcoes.length;
  }

  // Função para definir o feedback de desempenho
  Map<String, dynamic> _getFeedbackDesempenho(double media) {
    if (media < 4.0) {
      return {'texto': 'Ruim', 'cor': Colors.red.shade700, 'icone': Icons.sentiment_very_dissatisfied};
    } else if (media < 7.0) {
      return {'texto': 'Regular', 'cor': Colors.orange.shade700, 'icone': Icons.sentiment_neutral};
    } else if (media < 9.0) {
      return {'texto': 'Bom', 'cor': Colors.blue.shade700, 'icone': Icons.sentiment_satisfied};
    } else {
      return {'texto': 'Ótimo', 'cor': Colors.green.shade700, 'icone': Icons.sentiment_very_satisfied};
    }
  }

  // Função para agrupar as notas para o gráfico
  Map<String, int> _getDistribuicaoNotas() {
    Map<String, int> distribuicao = {
      '0-3.9': 0,
      '4-6.9': 0,
      '7-8.9': 0,
      '9-10': 0,
    };

    for (var correcao in prova.correcoes) {
      if (correcao.nota < 4.0) {
        distribuicao['0-3.9'] = distribuicao['0-3.9']! + 1;
      } else if (correcao.nota < 7.0) distribuicao['4-6.9'] = distribuicao['4-6.9']! + 1;
      else if (correcao.nota < 9.0) distribuicao['7-8.9'] = distribuicao['7-8.9']! + 1;
      else distribuicao['9-10'] = distribuicao['9-10']! + 1;
    }
    return distribuicao;
  }

  @override
  Widget build(BuildContext context) {
    final double notaMedia = _calcularNotaMedia();
    final feedback = _getFeedbackDesempenho(notaMedia);
    final distribuicao = _getDistribuicaoNotas();
    
    // Lista de barras para o gráfico
    final barGroups = [
      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: distribuicao['0-3.9']!.toDouble(), color: feedback['cor'])]),
      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: distribuicao['4-6.9']!.toDouble(), color: feedback['cor'])]),
      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: distribuicao['7-8.9']!.toDouble(), color: feedback['cor'])]),
      BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: distribuicao['9-10']!.toDouble(), color: feedback['cor'])]),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Estatísticas de "${prova.nome}"'),
      ),
      body: prova.correcoes.isEmpty
          ? const Center(child: Text('Não há correções para analisar.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card da Nota Média
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text('Nota Média da Turma', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(
                            notaMedia.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: feedback['cor'],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Card do Desempenho
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Icon(feedback['icone'], color: feedback['cor'], size: 30),
                           const SizedBox(width: 12),
                           Text(
                             'Desempenho: ${feedback['texto']}',
                             style: Theme.of(context).textTheme.titleLarge?.copyWith(color: feedback['cor']),
                           )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Card do Gráfico
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Distribuição de Notas', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                barGroups: barGroups,
                                titlesData: FlTitlesData(
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        const style = TextStyle(fontSize: 10);
                                        String text;
                                        switch (value.toInt()) {
                                          case 0: text = '0-3.9'; break;
                                          case 1: text = '4-6.9'; break;
                                          case 2: text = '7-8.9'; break;
                                          case 3: text = '9-10'; break;
                                          default: text = ''; break;
                                        }
                                        return SideTitleWidget(
                                            axisSide: meta.axisSide, // Correção: passamos o 'axisSide' a partir do 'meta'
                                            space: 4,
                                            child: Text(text, style: style),
                                        );

                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}