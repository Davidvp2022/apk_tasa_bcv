import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Aquí usamos lo que agregamos al pubspec
import 'dart:convert'; // Para entender los datos que vienen de internet

void main() => runApp(MaterialApp(
      home: MonitorTasas(), 
      debugShowCheckedModeBanner: false, // Quita la etiqueta roja de "debug"
    ));

class MonitorTasas extends StatefulWidget {
  @override
  _MonitorTasasState createState() => _MonitorTasasState();
}

class _MonitorTasasState extends State<MonitorTasas> {
  // 1. Variables para guardar los precios que traeremos
  String bcvDolar = "---";
  String bcvEuro = "---";
  String usdtP2P = "---";

  // 2. La función que "viaja" a internet a buscar los datos
Future<void> obtenerPrecios() async {
    try {
      // Definimos una "identidad" para la app (Headers)
      Map<String, String> cabeceras = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' 
      };

      final resDolar = await http.get(Uri.parse('https://ve.dolarapi.com/v1/dolares/oficial'), headers: cabeceras);
      final resEuro = await http.get(Uri.parse('https://ve.dolarapi.com/v1/dolares/euro'), headers: cabeceras);
      final resUsdt = await http.get(Uri.parse('https://ve.dolarapi.com/v1/dolares/binance'), headers: cabeceras);

      // Imprimimos en consola para ver qué está llegando
      print("Status Dólar: ${resDolar.statusCode}");
      print("Cuerpo Dólar: ${resDolar.body}");

      if (resDolar.statusCode == 200 && resDolar.body.isNotEmpty) {
        setState(() {
          bcvDolar = json.decode(resDolar.body)['promedio'].toString();
          bcvEuro = json.decode(resEuro.body)['promedio'].toString();
          usdtP2P = json.decode(resUsdt.body)['promedio'].toString();
        });
      } else {
        setState(() => bcvDolar = "Error: ${resDolar.statusCode}");
      }
    } catch (e) {
      print("Error detallado: $e");
      setState(() => bcvDolar = "Error de red");
    }
  }

  @override
  void initState() {
    super.initState();
    obtenerPrecios(); // Se ejecuta automáticamente al abrir la app
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Monitor de Tasas 🇻🇪"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tarjetas para mostrar los precios
            _tarjetaPrecio("Dólar BCV", bcvDolar, Colors.blue),
            _tarjetaPrecio("Euro BCV", bcvEuro, Colors.green),
            _tarjetaPrecio("USDT Binance", usdtP2P, Colors.orange),
            
            SizedBox(height: 30),
            
            ElevatedButton.icon(
              onPressed: obtenerPrecios,
              icon: Icon(Icons.refresh),
              label: Text("Actualizar Precios"),
              style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
            ),
          ],
        ),
      ),
    );
  }

  // Un "Widget" personalizado para no repetir código de las tarjetas
  Widget _tarjetaPrecio(String titulo, String valor, Color color) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, child: Icon(Icons.monetization_on, color: Colors.white)),
        title: Text(titulo, style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text("Bs. $valor", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}