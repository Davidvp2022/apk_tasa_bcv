import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MaterialApp(home: MonitorTasas(), debugShowCheckedModeBanner: false));

class MonitorTasas extends StatefulWidget {
  @override
  _MonitorTasasState createState() => _MonitorTasasState();
}

class _MonitorTasasState extends State<MonitorTasas> {
  // Variables de precios (ahora como números para la calculadora)
  double precioDolar = 0.0;
  double precioEuro = 0.0;
  double precioUsdt = 0.0;
  
  // Controlador para el texto que escribe el usuario
  TextEditingController controller = TextEditingController();
  double resultado = 0.0;

  Future<void> obtenerIndividual(String url, String tipo) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        setState(() {
          if (tipo == 'USD') precioDolar = double.parse(data['promedio'].toString());
          if (tipo == 'EUR') precioEuro = double.parse(data['promedio'].toString());
          if (tipo == 'USDT') precioUsdt = double.parse(data['promedio'].toString());
        });
      }
    } catch (e) {
      print("Error en $tipo: $e");
    }
  }

  void actualizarTodo() {
    obtenerIndividual('https://ve.dolarapi.com/v1/dolares/oficial', 'USD');
    obtenerIndividual('https://ve.dolarapi.com/v1/dolares/euro', 'EUR');
    obtenerIndividual('https://ve.dolarapi.com/v1/dolares/binance', 'USDT');
  }

  @override
  void initState() {
    super.initState();
    actualizarTodo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: Text("Dólar & Calculadora 🇻🇪"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: SingleChildScrollView( // Para que no se corte la pantalla al abrir el teclado
        padding: EdgeInsets.all(15),
        child: Column(
          children: [
            // SECCIÓN DE PRECIOS
            _cardPrecio("Dólar BCV", precioDolar, Colors.blue),
            _cardPrecio("Euro BCV", precioEuro, Colors.green),
            _cardPrecio("USDT Binance", precioUsdt, Colors.orange),
            
            Divider(height: 40),

            // SECCIÓN CALCULADORA
            Text("Calculadora de Conversión", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Monto en Divisas (\$ / € / USDT)",
                prefixIcon: Icon(Icons.calculate),
              ),
              onChanged: (valor) {
                // Esto hace que el cálculo sea instantáneo al escribir
                setState(() {
                  double monto = double.tryParse(valor) ?? 0.0;
                  resultado = monto * precioDolar; // Por defecto usa el dólar
                });
              },
            ),
            
            SizedBox(height: 20),
            
            Container(
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
            ),

            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: actualizarTodo, 
              icon: Icon(Icons.refresh), 
              label: Text("Actualizar Tasas")
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardPrecio(String t, double v, Color c) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.monetization_on, color: c),
        title: Text(t),
        trailing: Text(v == 0.0 ? "Cargando..." : "Bs. ${v.toStringAsFixed(2)}", 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}