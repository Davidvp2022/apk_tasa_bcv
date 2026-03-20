import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MaterialApp(home: MonitorTasas(), debugShowCheckedModeBanner: false));

class MonitorTasas extends StatefulWidget {
  @override
  _MonitorTasasState createState() => _MonitorTasasState();
}

class _MonitorTasasState extends State<MonitorTasas> {
  double precioDolar = 0.0;
  double precioEuro = 0.0;
  double precioUsdt = 0.0; // Usaremos el Paralelo como referencia de USDT/Dólar Libre
  
  String monedaSeleccionada = 'USD'; 
  TextEditingController controller = TextEditingController();
  double resultado = 0.0;

  Future<void> actualizarTasas() async {
    // Usamos los links exactos de tu investigación
    await fetchTasa('https://ve.dolarapi.com/v1/dolares/oficial', 'USD');
    await fetchTasa('https://ve.dolarapi.com/v1/euros', 'EUR');
    await fetchTasa('https://ve.dolarapi.com/v1/dolares/paralelo', 'USDT');
    
    recalcular(controller.text);
  }

  Future<void> fetchTasa(String url, String tipo) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final decodedData = json.decode(res.body);
        
        setState(() {
          double valor = 0.0;

          // Si es una LISTA (como en el caso de /v1/euros)
          if (decodedData is List) {
            // Buscamos el que dice "oficial" dentro de la lista
            var oficial = decodedData.firstWhere((item) => item['fuente'] == 'oficial');
            valor = double.parse(oficial['promedio'].toString());
          } 
          // Si es un OBJETO único (como /v1/dolares/oficial o paralelo)
          else {
            valor = double.parse(decodedData['promedio'].toString());
          }

          if (tipo == 'USD') precioDolar = valor;
          if (tipo == 'EUR') precioEuro = valor;
          if (tipo == 'USDT') precioUsdt = valor;
        });
      }
    } catch (e) {
      print("Error en $tipo: $e");
    }
  }

  void recalcular(String valor) {
    double monto = double.tryParse(valor) ?? 0.0;
    double tasa = precioDolar;
    if (monedaSeleccionada == 'EUR') tasa = precioEuro;
    if (monedaSeleccionada == 'USDT') tasa = precioUsdt;

    setState(() {
      resultado = monto * tasa;
    });
  }

  @override
  void initState() {
    super.initState();
    actualizarTasas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dólar & Calculadora 🇻🇪"), 
        backgroundColor: Colors.indigo, 
        foregroundColor: Colors.white,
        actions: [IconButton(icon: Icon(Icons.refresh), onPressed: actualizarTasas)],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _cardPrecio("Dólar BCV", precioDolar, Colors.blue),
            _cardPrecio("Euro BCV", precioEuro, Colors.green),
            _cardPrecio("Dólar Paralelo", precioUsdt, Colors.red), // Cambié el nombre a Paralelo
            
            Divider(height: 40),
            Text("Calculadora de Conversión", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),

            ToggleButtons(
              isSelected: [monedaSeleccionada == 'USD', monedaSeleccionada == 'EUR', monedaSeleccionada == 'USDT'],
              onPressed: (int index) {
                setState(() {
                  if (index == 0) monedaSeleccionada = 'USD';
                  if (index == 1) monedaSeleccionada = 'EUR';
                  if (index == 2) monedaSeleccionada = 'USDT';
                  recalcular(controller.text);
                });
              },
              borderRadius: BorderRadius.circular(10),
              children: [
                Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: Text("USD")),
                Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: Text("EUR")),
                Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: Text("PARA")),
              ],
            ),

            SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Monto en $monedaSeleccionada",
                prefixIcon: Icon(Icons.calculate),
              ),
              onChanged: recalcular,
            ),
            
            SizedBox(height: 20),
            _cajaResultado(),
          ],
        ),
      ),
    );
  }

  Widget _cajaResultado() {
    return Container(
      padding: EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text("Total en Bolívares:", style: TextStyle(color: Colors.indigo)),
          Text("Bs. ${resultado.toStringAsFixed(2)}", 
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo)),
        ],
      ),
    );
  }

  Widget _cardPrecio(String t, double v, Color c) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.monetization_on, color: c),
        title: Text(t),
        trailing: Text(v == 0.0 ? "Cargando..." : "Bs. ${v.toStringAsFixed(2)}", 
          style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}