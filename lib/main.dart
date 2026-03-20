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
  double precioUsdt = 0.0; 
  
  String monedaSeleccionada = 'USD'; 
  TextEditingController controller = TextEditingController();
  double resultado = 0.0;

  Future<void> actualizarTasas() async {
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
          if (decodedData is List) {
            var oficial = decodedData.firstWhere((item) => item['fuente'] == 'oficial');
            valor = double.parse(oficial['promedio'].toString());
          } else {
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
    double tasa = (monedaSeleccionada == 'USD') ? precioDolar : 
                  (monedaSeleccionada == 'EUR') ? precioEuro : precioUsdt;
    setState(() => resultado = monto * tasa);
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
        title: Text("Monitor de Tasas 🇻🇪"), 
        backgroundColor: Colors.indigo, 
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // TASAS CON NOMBRES ORIGINALES E ICONOS ESPECÍFICOS
            _cardPrecio("Dólar BCV", precioDolar, Icons.attach_money, Colors.blue),
            _cardPrecio("Euro BCV", precioEuro, Icons.euro, Colors.green),
            _cardPrecio("USDT Binance", precioUsdt, Icons.currency_bitcoin, Colors.orange),
            
            Divider(height: 40),
            Text("Calculadora de Conversión", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),

            ToggleButtons(
              isSelected: [monedaSeleccionada == 'USD', monedaSeleccionada == 'EUR', monedaSeleccionada == 'USDT'],
              onPressed: (int index) {
                setState(() {
                  monedaSeleccionada = index == 0 ? 'USD' : index == 1 ? 'EUR' : 'USDT';
                  recalcular(controller.text);
                });
              },
              borderRadius: BorderRadius.circular(10),
              children: [
                Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: Text("USD")),
                Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: Text("EUR")),
                Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: Text("USDT")),
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
            SizedBox(height: 20),
            OutlinedButton.icon(onPressed: actualizarTasas, icon: Icon(Icons.refresh), label: Text("Actualizar Tasas")),
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
          Text("Total en Bolívares (VES):", style: TextStyle(color: Colors.indigo)),
          Text("Bs. ${resultado.toStringAsFixed(2)}", 
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo)),
        ],
      ),
    );
  }

  // Widget de tarjeta actualizado para recibir un IconData
  Widget _cardPrecio(String titulo, double valor, IconData icono, Color colorFondo) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorFondo,
          child: Icon(icono, color: Colors.white),
        ),
        title: Text(titulo, style: TextStyle(fontWeight: FontWeight.w500)),
        trailing: Text(valor == 0.0 ? "Cargando..." : "Bs. ${valor.toStringAsFixed(2)}", 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}