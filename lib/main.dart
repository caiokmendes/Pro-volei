import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

void main() {
  runApp(MaterialApp(
    home: VoleiPage(),
    debugShowCheckedModeBanner: false,
  ));
}

class VoleiPage extends StatefulWidget {
  const VoleiPage({super.key});

  @override
  _VoleiPageState createState() => _VoleiPageState();
}

class _VoleiPageState extends State<VoleiPage> {
  String? posicaoPonto1, tipoPonto1, origemPonto1, levantador1;
  String? posicaoPonto2, tipoPonto2, origemPonto2, levantador2;
  int placar1 = 0, placar2 = 0;
  int setSelecionado = 1;
  List<int> pontos = List.filled(60, 0);

  int saques1 = 0, bloqueios1 = 0, ataques1 = 0, erros1 = 0;
  int saques2 = 0, bloqueios2 = 0, ataques2 = 0, erros2 = 0;

  // --- acumuladores para o jogo inteiro ---
  int totalPlacar1 = 0, totalPlacar2 = 0;
  int totalSaques1 = 0, totalSaques2 = 0;
  int totalBloqueios1 = 0, totalBloqueios2 = 0;
  int totalAtaques1 = 0, totalAtaques2 = 0;
  int totalErros1 = 0, totalErros2 = 0;

  // --- sets vencidos ---
  int setsVencidos1 = 0, setsVencidos2 = 0;

  void salvarPonto(int equipe) {
    setState(() {
      if (equipe == 1 && placar1 < 30) {
        pontos[placar1] = 1;
        placar1++;
        _atualizarEstatistica(equipe, tipoPonto1);
      } else if (equipe == 2 && placar2 < 30) {
        pontos[30 + placar2] = 2;
        placar2++;
        _atualizarEstatistica(equipe, tipoPonto2);
      }
    });
  }

  void _atualizarEstatistica(int equipe, String? tipo) {
    if (tipo == null) return;
    if (equipe == 1) {
      if (tipo == "Saque") saques1++;
      if (tipo == "Bloqueio") bloqueios1++;
      if (tipo == "Ataque") ataques1++;
      if (tipo == "Erro do adversário") erros1++;
    } else {
      if (tipo == "Saque") saques2++;
      if (tipo == "Bloqueio") bloqueios2++;
      if (tipo == "Ataque") ataques2++;
      if (tipo == "Erro do adversário") erros2++;
    }
  }

  void excluirUltimoPonto(int equipe) {
    setState(() {
      if (equipe == 1 && placar1 > 0) {
        placar1--;
        pontos[placar1] = 0;
      } else if (equipe == 2 && placar2 > 0) {
        placar2--;
        pontos[30 + placar2] = 0;
      }
    });
  }

  /// --- PDF de um SET ---
  Future<void> gerarPdfSet() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Center(
            child: pw.Text("SET $setSelecionado",
                style: pw.TextStyle(
                    fontSize: 22, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 20),
          _tabelaResumo(
              placar1, placar2,
              saques1, saques2,
              bloqueios1, bloqueios2,
              ataques1, ataques2,
              erros1, erros2),
          pw.SizedBox(height: 30),
          _graficoResumo(
              saques1, saques2,
              bloqueios1, bloqueios2,
              ataques1, ataques2,
              erros1, erros2),
        ],
      ),
    );

    await _salvarAbrirPdf(pdf, "set_$setSelecionado.pdf");

    // acumula os dados do set no total do jogo
    totalPlacar1 += placar1;
    totalPlacar2 += placar2;
    totalSaques1 += saques1;
    totalSaques2 += saques2;
    totalBloqueios1 += bloqueios1;
    totalBloqueios2 += bloqueios2;
    totalAtaques1 += ataques1;
    totalAtaques2 += ataques2;
    totalErros1 += erros1;
    totalErros2 += erros2;

    // registra set vencido
    if (placar1 > placar2) {
      setsVencidos1++;
    } else if (placar2 > placar1) {
      setsVencidos2++;
    }

    // reseta os dados para o próximo set
    setState(() {
      placar1 = 0;
      placar2 = 0;
      saques1 = bloqueios1 = ataques1 = erros1 = 0;
      saques2 = bloqueios2 = ataques2 = erros2 = 0;
      pontos = List.filled(60, 0);
      setSelecionado++;
    });
  }

  /// --- PDF do JOGO COMPLETO ---
  Future<void> gerarPdfJogo() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Center(
            child: pw.Text("DADOS DO JOGO",
                style: pw.TextStyle(
                    fontSize: 22, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 20),
          _tabelaResumo(
              totalPlacar1, totalPlacar2,
              totalSaques1, totalSaques2,
              totalBloqueios1, totalBloqueios2,
              totalAtaques1, totalAtaques2,
              totalErros1, totalErros2,
              sets1: setsVencidos1,
              sets2: setsVencidos2),
          pw.SizedBox(height: 30),
          _graficoResumo(
              totalSaques1, totalSaques2,
              totalBloqueios1, totalBloqueios2,
              totalAtaques1, totalAtaques2,
              totalErros1, totalErros2),
        ],
      ),
    );

    await _salvarAbrirPdf(pdf, "jogo_completo.pdf");
  }

  /// --- Componentes reutilizáveis no PDF ---
  pw.Widget _tabelaResumo(
      int placar1, int placar2,
      int saques1, int saques2,
      int bloqueios1, int bloqueios2,
      int ataques1, int ataques2,
      int erros1, int erros2,
      {int sets1 = 0, int sets2 = 0}) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(children: [
          pw.Padding(
              padding: const pw.EdgeInsets.all(8), child: pw.Text("")),
          pw.Padding(
              padding: const pw.EdgeInsets.all(8), child: pw.Text("EQUIPE 1")),
          pw.Padding(
              padding: const pw.EdgeInsets.all(8), child: pw.Text("EQUIPE 2")),
        ]),
        pw.TableRow(children: [
          pw.Padding(
              padding: const pw.EdgeInsets.all(8), child: pw.Text("PONTOS TOTAIS")),
          pw.Padding(
              padding: const pw.EdgeInsets.all(8), child: pw.Text("$placar1")),
          pw.Padding(
              padding: const pw.EdgeInsets.all(8), child: pw.Text("$placar2")),
        ]),
        pw.TableRow(children: [
          pw.Padding(
              padding: const pw.EdgeInsets.all(8), child: pw.Text("SETS VENCIDOS")),
          pw.Padding(
              padding: const pw.EdgeInsets.all(8), child: pw.Text("$sets1")),
          pw.Padding(
              padding: const pw.EdgeInsets.all(8), child: pw.Text("$sets2")),
        ]),
        pw.TableRow(children: [
          pw.Padding(
              padding: const pw.EdgeInsets.all(8), child: pw.Text("SAQUES")),
          pw.Padding(
              padding: const pw.EdgeInsets.all(8), child: pw.Text("$saques1")),
          pw.Padding(
              padding: const pw.EdgeInsets.all(8), child: pw.Text("$saques2")),
        ]),
        pw.TableRow(children: [
          pw.Padding(
              padding: const pw.EdgeInsets.all(8), child: pw.Text("BLOQUEIOS")),
          pw.Padding(
              padding: const pw.EdgeInsets.all(8), child: pw.Text("$bloqueios1")),
          pw.Padding(
              padding: const pw.EdgeInsets.all(8), child: pw.Text("$bloqueios2")),
        ]),
        pw.TableRow(children: [
          pw.Padding(
              padding: const pw.EdgeInsets.all(8), child: pw.Text("ATAQUES")),
          pw.Padding(
              padding: const pw.EdgeInsets.all(8), child: pw.Text("$ataques1")),
          pw.Padding(
              padding: const pw.EdgeInsets.all(8), child: pw.Text("$ataques2")),
        ]),
        pw.TableRow(children: [
          pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text("ERROS ADVERSÁRIOS")),
          pw.Padding(
              padding: const pw.EdgeInsets.all(8), child: pw.Text("$erros1")),
          pw.Padding(
              padding: const pw.EdgeInsets.all(8), child: pw.Text("$erros2")),
        ]),
      ],
    );
  }

  pw.Widget _graficoResumo(int saques1, int saques2,
      int bloqueios1, int bloqueios2,
      int ataques1, int ataques2,
      int erros1, int erros2) {
    return pw.Column(
      children: [
        pw.Chart(
          grid: pw.CartesianGrid(
            xAxis: pw.FixedAxis.fromStrings(
              ['Saque', 'Bloqueio', 'Ataque', 'Erro Adv'],
              marginStart: 30,
              marginEnd: 30,
            ),
            yAxis: pw.FixedAxis([0, 1, 2, 3, 4, 5, 10, 15, 20]),
          ),
          datasets: [
            pw.BarDataSet(
              color: PdfColors.blue,
              width: 15,
              data: [
                pw.PointChartValue(-0.15, saques1.toDouble()),
                pw.PointChartValue(0.85, bloqueios1.toDouble()),
                pw.PointChartValue(1.85, ataques1.toDouble()),
                pw.PointChartValue(2.85, erros1.toDouble()),
              ],
            ),
            pw.BarDataSet(
              color: PdfColors.red,
              width: 15,
              data: [
                pw.PointChartValue(0.15, saques2.toDouble()),
                pw.PointChartValue(1.15, bloqueios2.toDouble()),
                pw.PointChartValue(2.15, ataques2.toDouble()),
                pw.PointChartValue(3.15, erros2.toDouble()),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Container(width: 12, height: 12, color: PdfColors.blue),
            pw.SizedBox(width: 5),
            pw.Text("Equipe 1 (Azul)"),
            pw.SizedBox(width: 20),
            pw.Container(width: 12, height: 12, color: PdfColors.red),
            pw.SizedBox(width: 5),
            pw.Text("Equipe 2 (Vermelho)"),
          ],
        ),
      ],
    );
  }

  Future<void> _salvarAbrirPdf(pw.Document pdf, String nomeArquivo) async {
    try {
      final directory =
          await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final file = File("${directory.path}/$nomeArquivo");
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF salvo em: ${file.path}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao salvar PDF: $e")),
      );
    }
  }

  /// --- UI ---
  Widget barraDePontos(int equipe) {
    int offset = equipe == 1 ? 0 : 30;
    return Container(
      height: 30,
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 30,
        itemBuilder: (context, index) {
          final cor = pontos[offset + index] == equipe
              ? (equipe == 1 ? Colors.amber : Colors.orange)
              : Colors.grey[300];
          return Container(
            width: 20,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            color: cor,
          );
        },
      ),
    );
  }

  Widget selecaoEquipe({
    required int equipe,
    required String? posicao,
    required String? tipo,
    required String? origem,
    required String? levantador,
    required ValueChanged<String?> onPosicao,
    required ValueChanged<String?> onTipo,
    required ValueChanged<String?> onOrigem,
    required ValueChanged<String?> onLevantador,
    required VoidCallback onSalvar,
    required VoidCallback onExcluir,
    required int placar,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("EQUIPE $equipe",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: posicao,
              hint: const Text("Posição do ponto"),
              isExpanded: true,
              onChanged: onPosicao,
              items: ['1', '2', '3', '4', '5', '6']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
            ),
            DropdownButton<String>(
              value: tipo,
              hint: const Text("Tipo de ponto"),
              isExpanded: true,
              onChanged: onTipo,
              items: ['Saque', 'Bloqueio', 'Ataque', 'Erro do adversário']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
            ),
            Row(
              children: [
                const Text("Origem: "),
                Radio<String>(
                  value: "side-out",
                  groupValue: origem,
                  onChanged: onOrigem,
                ),
                const Text("side-out"),
                Radio<String>(
                  value: "contra-ataque",
                  groupValue: origem,
                  onChanged: onOrigem,
                ),
                const Text("contra-ataque"),
              ],
            ),
            DropdownButton<String>(
              value: levantador,
              hint: const Text("Levantador"),
              isExpanded: true,
              onChanged: onLevantador,
              items: ['1', '2', '3', '4', '5', '6']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: onSalvar,
                  style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("SALVAR"),
                ),
                ElevatedButton(
                  onPressed: onExcluir,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("EXCLUIR"),
                ),
                Text("PLACAR: $placar"),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[200],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              barraDePontos(1),
              barraDePontos(2),
              Row(
                children: [
                  selecaoEquipe(
                    equipe: 1,
                    posicao: posicaoPonto1,
                    tipo: tipoPonto1,
                    origem: origemPonto1,
                    levantador: levantador1,
                    onPosicao: (val) => setState(() => posicaoPonto1 = val),
                    onTipo: (val) => setState(() => tipoPonto1 = val),
                    onOrigem: (val) => setState(() => origemPonto1 = val),
                    onLevantador: (val) => setState(() => levantador1 = val),
                    onSalvar: () => salvarPonto(1),
                    onExcluir: () => excluirUltimoPonto(1),
                    placar: placar1,
                  ),
                  selecaoEquipe(
                    equipe: 2,
                    posicao: posicaoPonto2,
                    tipo: tipoPonto2,
                    origem: origemPonto2,
                    levantador: levantador2,
                    onPosicao: (val) => setState(() => posicaoPonto2 = val),
                    onTipo: (val) => setState(() => tipoPonto2 = val),
                    onOrigem: (val) => setState(() => origemPonto2 = val),
                    onLevantador: (val) => setState(() => levantador2 = val),
                    onSalvar: () => salvarPonto(2),
                    onExcluir: () => excluirUltimoPonto(2),
                    placar: placar2,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    int set = index + 1;
                    return Row(
                      children: [
                        Radio(
                          value: set,
                          groupValue: setSelecionado,
                          onChanged: (int? val) =>
                              setState(() => setSelecionado = val!),
                        ),
                        Text("SET $set"),
                      ],
                    );
                  }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("SAIR"),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      onPressed: gerarPdfSet,
                      child: const Text("FINALIZAR SET"),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      onPressed: gerarPdfJogo,
                      child: const Text("FINALIZAR JOGO"),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
